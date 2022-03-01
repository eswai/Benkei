//
//  AppDelegate.m
//  Lacaille
//
//  Created by kkadowaki on 2014.04.26.
//  Copyright (c) 2014-2018 kkadowaki. All rights reserved.
//  Modified by eswai on 2021/02/07 for Naginata style.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#import "AppDelegate.h"
#import "Naginata.h"
#import "ProperAction.h"

@implementation AppDelegate

static NSArray *arKanaMethods;
CFMachPortRef eventTap = NULL;
CFRunLoopSourceRef runLoopSource = NULL;
NSUserDefaults *ud;

NSStatusItem *sbItem;
AppDelegate *self_;
NSLock *gLock;
NSTimer *gTimer;

NSImage *imgActive;
NSImage *imgInactive;
NSImage *imgDisabled;

BOOL oyaSheetIsActive;
BOOL keySheetIsActive;
BOOL properSheetIsActive;
BOOL volatile gKanaMethod; // 日本語入力モード trueで日本語
unsigned char gBuff; // 文字入力バッファ
unsigned char gOya; // 左親指なら1、右親指なら2、それ以外0
unsigned char gPrevOya; // １ステップ前の親指状態
unsigned char gPressedOya;
int64_t gKeyDownAutorepeat;
CGEventFlags gEventMasks = 0;
NSDate *gOyaKeyDownTimeStamp;
CGEventSourceKeyboardType gKeyboardType;
pid_t gTargetPid;
NSMutableData *gKeySheetValue;
int gKeySheetValueLength;   // N.B. 10.9 or lower does not support NSMutableData.length
unsigned char gFirstIgnoredSingleThumbMask = 0;    // 親指キーの初回単独打鍵を無視するためのマスク

CGKeyCode hjbuf = 0;
//CGKeyCode curkey = 0;
//bool gvalid = 0;

NSFileHandle *debugOutFile = nil;
#define debugOut(...) \
 [((debugOutFile == nil) ? (debugOutFile = [NSFileHandle fileHandleWithStandardOutput]) : debugOutFile) \
  writeData:[[NSString stringWithFormat:__VA_ARGS__] dataUsingEncoding:NSUTF8StringEncoding]]

#define LAYOUT_KEY_COUNT    50      // キーの個数

static CGKeyCode viewTable[] = {
    6, 7, 8, 9, 11, 45, 46, 43, 47, 44, LAYOUT_KEY_COUNT - 1,   // 94
    0, 1, 2, 3, 5, 4, 38, 40, 37, 41, 39, 42,
    12, 13, 14, 15, 17, 16, 32, 34, 31, 35, 33, 30,
    18, 19, 20, 21, 23, 22, 26, 28, 25, 29, 27, 24, LAYOUT_KEY_COUNT - 2   // 93
};

NSArray *prefLayout = nil;          // レイアウト
BOOL prefEnabled = NO;              // NICOLA エミュレーション
BOOL prefCshift = NO;               // 連続シフトキー
BOOL prefReturnemu = NO;            // 無変換キーのエミュレーション
BOOL prefSpaceemu = NO;             // 変換キーのエミュレーション
BOOL prefFirstIgnoredSingleThumbL = NO;     // 左親指キーの初回単独打鍵は無視
BOOL prefFirstIgnoredSingleThumbR = NO;     // 右親指キーの初回単独打鍵は無視
CGKeyCode prefThumbL = kVK_JIS_Eisu;    // 親指左 = 英数
CGKeyCode prefThumbR = kVK_JIS_Kana;    // 親指右 = かな
NSTimeInterval prefTwait = 0.06;    // 同時判定時間

Naginata *naginata;

NSString *const BenkeiErrorDomain = @"org.jpn.benkei.Benkei.BenkeiErrorDomain";
typedef NS_ENUM(NSInteger, BenkeiErrorCode) {
    BenkeiErrorLayoutNotLoad,
    BenkeiErrorNoEventTap,
    BenkeiErrorSetModeCancelled DEPRECATED_ATTRIBUTE
};

- (BOOL)startAtLogin {
    NSURL *itemURL = [NSURL fileURLWithPath:[NSBundle mainBundle].bundlePath];
    
    Boolean foundIt = false;
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = (__bridge NSArray*)LSSharedFileListCopySnapshot(loginItems, &seed);
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
            
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, NULL);
            if (err == noErr) {
                foundIt = CFEqual(URL, (__bridge CFTypeRef)(itemURL));
                CFRelease(URL);
                
                if (foundIt) {
                    break;
                }
            }
        }
        CFRelease(loginItems);
    }
    return (BOOL)foundIt;
}

- (void)setStartAtLogin:(BOOL)enabled {
    [self willChangeValueForKey:@"startAtLogin"];
    NSURL *itemURL = [NSURL fileURLWithPath:[NSBundle mainBundle].bundlePath];
    LSSharedFileListItemRef existingItem = NULL;
    
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seed = 0U;
        NSArray *currentLoginItems = (__bridge NSArray*)LSSharedFileListCopySnapshot(loginItems, &seed);
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
            
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, NULL);
            if (err == noErr) {
                Boolean foundIt = CFEqual(URL, (__bridge CFTypeRef)(itemURL));
                CFRelease(URL);
                
                if (foundIt) {
                    existingItem = item;
                    break;
                }
            }
        }
        
        if (enabled && (existingItem == NULL)) {
            LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst,
                                          NULL, NULL, (__bridge CFURLRef)itemURL, NULL, NULL);
            
        } else if (!enabled && (existingItem != NULL)) {
            LSSharedFileListItemRemove(loginItems, existingItem);
        }
        
        CFRelease(loginItems);
    }
    [self didChangeValueForKey:@"startAtLogin"];
}

@synthesize propLayout;
- (NSArray *)propLayout { return prefLayout; }
- (void)setPropLayout:(NSArray *)value {
    // if (value != prefLayout) {
    NSMutableArray *keyDataForDictionary = [[NSMutableArray alloc] initWithCapacity:LAYOUT_KEY_COUNT];
    for (id obj in [value objectEnumerator]) {
        [keyDataForDictionary addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         convTraditionalKeyData([(ViewDataModel *)obj getKeyData:0]), @"No shift",
                                         convTraditionalKeyData([(ViewDataModel *)obj getKeyData:1]), @"With left shift",
                                         convTraditionalKeyData([(ViewDataModel *)obj getKeyData:2]), @"With right shift",
                                         convTraditionalKeyData([(ViewDataModel *)obj getKeyData:3]), @"With outer shift",
                                         convTraditionalKeyData([(ViewDataModel *)obj getKeyData:4]), @"ASCII - No shift",
                                         convTraditionalKeyData([(ViewDataModel *)obj getKeyData:5]), @"ASCII - With outer shift",
                                         convTraditionalKeyData([(ViewDataModel *)obj getKeyData:6]), @"With modifier key",
                                         ((ViewDataModel *)obj).proper, @"Proper noun",
                                         nil]];
    }
    
    [ud setObject:keyDataForDictionary forKey:@"layout"];
    [ud synchronize];
    // }
    prefLayout = value;
    [_tableView reloadData];
}


@synthesize propEnabled;
- (BOOL) validatePropEnabled:(inout __autoreleasing id *)ioValue error:(out NSError *__autoreleasing *)outError {
    if ([(*ioValue) intValue]) {
        return checkLayout(outError) && checkEventTap(outError);
    }
    return YES;
}
- (BOOL)propEnabled { return prefEnabled; }
- (void)setPropEnabled:(BOOL)value {
    BOOL oldValue = prefEnabled;
    if (value) {
        prefEnabled = YES;
        if (!enableEventTap()) {
            self.propEnabled = NO;
        }
    } else {
        prefEnabled = NO;
        disableEventTap();
    }
    if (value != oldValue) {
        [ud setObject:(value ? @(1) : @(0)) forKey:@"enabled"];
        [ud synchronize];
    }
    [self updateSbIcon];
    gPressedOya = 0;
}

@synthesize propCshift;
- (BOOL)propCshift { return prefCshift; }
- (void)setPropCshift:(BOOL)value {
    if (value != prefCshift) {
        [ud setObject:(value ? @(1) : @(0)) forKey:@"cshift"];
        [ud synchronize];
    }
    prefCshift = value;
    naginata.kouchiShift = value;
}

static NSControlStateValue getRadioButtonState(BOOL value) {
    // N.B. 10.10 and above: NSControlStateValue, NSControlStateValueOn, NSControlStateValueOff
    return value ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)updateRadioButtonsForSingleThumbL {
    _normalRadioButtonForSingleThumbL.state = getRadioButtonState(!prefFirstIgnoredSingleThumbL && !prefReturnemu);
    _firstIgnoranceRadioButtonForSingleThumbL.state = getRadioButtonState(prefFirstIgnoredSingleThumbL);
    _returnemuRadioButtonForSingleThumbL.state = getRadioButtonState(prefReturnemu);
}

- (void)updateRadioButtonsForSingleThumbR {
    _normalRadioButtonForSingleThumbR.state = getRadioButtonState(!prefFirstIgnoredSingleThumbR && !prefSpaceemu);
    _firstIgnoranceRadioButtonForSingleThumbR.state = getRadioButtonState(prefFirstIgnoredSingleThumbR);
    _spaceemuRadioButtonForSingleThumbR.state = getRadioButtonState(prefSpaceemu);
}

- (void)updateFirstIgnoredSingleThumbMask {
    gFirstIgnoredSingleThumbMask = (prefFirstIgnoredSingleThumbL ? 1 : 0) | (prefFirstIgnoredSingleThumbR ? 2 : 0);
    gPressedOya &= gFirstIgnoredSingleThumbMask;
}

@synthesize propFirstIgnoredSingleThumbL;
- (BOOL)propFirstIgnoredSingleThumbL { return prefFirstIgnoredSingleThumbL; }
- (void)setPropFirstIgnoredSingleThumbL:(BOOL)value {
    if (value != prefFirstIgnoredSingleThumbL) {
        [ud setObject:(value ? @(1) : @(0)) forKey:@"firstIgnoredSingleThumbL"];
        [ud synchronize];
    }
    
    prefFirstIgnoredSingleThumbL = value;
    [self updateFirstIgnoredSingleThumbMask];
    [self updateRadioButtonsForSingleThumbL];
}

@synthesize propFirstIgnoredSingleThumbR;
- (BOOL)propFirstIgnoredSingleThumbR { return prefFirstIgnoredSingleThumbR; }
- (void)setPropFirstIgnoredSingleThumbR:(BOOL)value {
    if (value != prefFirstIgnoredSingleThumbR) {
        [ud setObject:(value ? @(1) : @(0)) forKey:@"firstIgnoredSingleThumbR"];
        [ud synchronize];
    }
    prefFirstIgnoredSingleThumbR = value;
    [self updateFirstIgnoredSingleThumbMask];
    [self updateRadioButtonsForSingleThumbR];
}

@synthesize propReturnemu;
- (BOOL)propReturnemu { return prefReturnemu; }
- (void)setPropReturnemu:(BOOL)value {
    if (value != prefReturnemu) {
        [ud setObject:(value ? @(1) : @(0)) forKey:@"returnemu"];
        [ud synchronize];
    }
    prefReturnemu = value;
    [self updateRadioButtonsForSingleThumbL];
}

@synthesize propSpaceemu;
- (BOOL)propSpaceemu { return prefSpaceemu; }
- (void)setPropSpaceemu:(BOOL)value {
    if (value != prefSpaceemu) {
        [ud setObject:(value ? @(1) : @(0)) forKey:@"spaceemu"];
        [ud synchronize];
    }
    prefSpaceemu = value;
    [self updateRadioButtonsForSingleThumbR];
}

@synthesize propThumbL;
- (CGKeyCode)propThumbL { return prefThumbL; }
- (void)setPropThumbL:(CGKeyCode)value {
    if (value != prefThumbL) {
        [ud setObject:@(value) forKey:@"thumbL"];
        [ud synchronize];
    };
    prefThumbL = value;
}

@synthesize propThumbR;
- (CGKeyCode)propThumbR { return prefThumbR; }
- (void)setPropThumbR:(CGKeyCode)value {
    if (value != prefThumbR) {
        [ud setObject:@(value) forKey:@"thumbR"];
        [ud synchronize];
    };
    prefThumbR = value;
}

@synthesize propTwait;
- (NSTimeInterval)propTwait { return prefTwait * 1000; }
- (void)setPropTwait:(NSTimeInterval)value {
    if (value / 1000 != prefTwait) {
        [ud setObject:@(value / 1000) forKey:@"twait"];
        [ud synchronize];
    };
    prefTwait = value / 1000;
    naginata.doujiTime = prefTwait;
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 17.0f;
}


- (IBAction)clickPropButton:(id)sender {
    CGKeyCode keycode = viewTable[[sender clickedRow]];
    
    [_properLabel setStringValue:[NSString stringWithFormat:@"%@",
                                [(ViewDataModel *)prefLayout[keycode] getKeycodeString]]
     ];
    [_properText setStringValue:((ViewDataModel *)prefLayout[keycode]).proper];
    
    if (!prefEnabled && !enableEventTap()) {
        return;
    }
    
    properSheetIsActive = YES;
    
    // N.B. 10.9 and above: [_window beginSheet:completionHandler]
    [NSApp beginSheet: _properSheet
       modalForWindow: _window
        modalDelegate: self
       didEndSelector: @selector(properSheetClosed:returnCode:contextInfo:)
          contextInfo: (__bridge void *)[NSNumber numberWithInt:(keycode << 8)]];
}

- (IBAction)properOK:(id)sender {
    [NSApp endSheet:_properSheet returnCode:0];
    [_properSheet close];
}
- (IBAction)properCancel:(id)sender {
    [NSApp endSheet:_properSheet returnCode:0xff];
    [_properSheet close];
}

- (IBAction)clickButton:(id)sender {
    CGKeyCode keycode = viewTable[[sender clickedRow]];
    int oya = (int)[sender clickedColumn] - 1;
    
    if (0 <= oya && oya <= 6) { // center, left, right, outer, ascii, shift, modifier
        [_keyLabel1 setStringValue:[NSString stringWithFormat:@"%@ %@",
                                    [(ViewDataModel *)prefLayout[keycode] getKeycodeString],
                                    NSLocalizedString(((oya == 0) ? @"nicola_no_shift" :
                                                       (oya == 1) ? @"nicola_with_left_shift" :
                                                       (oya == 2) ? @"nicola_with_right_shift" :
                                                       (oya == 3) ? @"nicola_with_outer_shift" :
                                                       (oya == 4) ? @"ascii_no_shift" :
                                                       (oya == 5) ? @"ascii_with_outer_shift" :
                                                       (oya == 6) ? @"ascii_with_modifier_key" :
                                                       nil), nil)
                                    ]
         ];
        [_keyLabel2 setStringValue:@""];
        
        if (!prefEnabled && !enableEventTap()) {
            return;
        }
        
        gKeySheetValue = [[NSMutableData alloc] initWithCapacity:3];
        gKeySheetValueLength = 0;
        // [[NSMutableData alloc] initWithData:[(ViewDataModel *)prefLayout[keycode] getKeyData:oya]];
        
        keySheetIsActive = YES;
        
        // N.B. 10.9 and above: [_window beginSheet:completionHandler]
        [NSApp beginSheet: _keySheet
           modalForWindow: _window
            modalDelegate: self
           didEndSelector: @selector(keySheetClosed:returnCode:contextInfo:)
              contextInfo: (__bridge void *)[NSNumber numberWithInt:(keycode << 8 | oya)]];
    }
}
- (IBAction)keyOK:(id)sender {
    [NSApp endSheet:_keySheet returnCode:0];
    [_keySheet close];
}
- (IBAction)keyCancel:(id)sender {
    [NSApp endSheet:_keySheet returnCode:0xff];
    [_keySheet close];
}
- (void)appendKeySheet:(CGKeyCode)keyCode modifierKeys:(CGEventFlags)flagMasks {
    
    if (keyCode == kVK_Option || keyCode == kVK_Command || keyCode == kVK_Shift || keyCode == kVK_CapsLock || keyCode == kVK_Control || keyCode == kVK_RightOption || keyCode == kVK_RightCommand || keyCode == kVK_RightShift || keyCode == kVK_RightControl) {
        // TODO: for now, modifier keys are appended by masks
        return;
    }
    CGEventFlags previousMasks = 0;
    if (flagMasks) {
        const void *ptr = [gKeySheetValue bytes];
        if (*(unsigned char*)(ptr + gKeySheetValueLength - 1) == (unsigned char)0xff) {
            for(int i = (int)gKeySheetValueLength - 2; i >= 0; i--) {
                // N.B. no masks for right keys
                switch(*(unsigned char*)(ptr + i) & 0xff) {
                    case kVK_Option:   previousMasks |= kCGEventFlagMaskAlternate; break;
                    case kVK_Command:  previousMasks |= kCGEventFlagMaskCommand; break;
                    case kVK_Shift:    previousMasks |= kCGEventFlagMaskShift; break;
                    case kVK_CapsLock: previousMasks |= kCGEventFlagMaskAlphaShift; break;
                    case kVK_Control:  previousMasks |= kCGEventFlagMaskControl; break;
                    case 0xFF:         i = 0;
                }
            }
            if ((flagMasks & previousMasks) == previousMasks) {
                [gKeySheetValue replaceBytesInRange:NSMakeRange(gKeySheetValueLength - 1, 1)
                                          withBytes:(const void*)NULL length:0];
                gKeySheetValueLength--;
            } else {
                previousMasks = 0;
            }
        }
    }
    if (flagMasks & ~previousMasks & kCGEventFlagMaskAlternate) {
        [gKeySheetValue appendBytes:(unsigned char[]){kVK_Option} length:1];  // Alt or Option
        gKeySheetValueLength++;
    }
    if (flagMasks & ~previousMasks & kCGEventFlagMaskCommand) {
        [gKeySheetValue appendBytes:(unsigned char[]){kVK_Command} length:1];  // Command
        gKeySheetValueLength++;
    }
    if (flagMasks & ~previousMasks & kCGEventFlagMaskShift) {
        [gKeySheetValue appendBytes:(unsigned char[]){kVK_Shift} length:1];  // Shift
        gKeySheetValueLength++;
    }
    if (flagMasks & ~previousMasks & kCGEventFlagMaskAlphaShift) {
        [gKeySheetValue appendBytes:(unsigned char[]){kVK_CapsLock} length:1];  // Caps Lock
        gKeySheetValueLength++;
    }
    if (flagMasks & ~previousMasks & kCGEventFlagMaskControl) {
        [gKeySheetValue appendBytes:(unsigned char[]){kVK_Control} length:1];  // Control
        gKeySheetValueLength++;
    }
    
    [gKeySheetValue appendBytes:(unsigned char[]){keyCode} length:1];
    gKeySheetValueLength++;
    
    if (flagMasks & (kCGEventFlagMaskAlternate | kCGEventFlagMaskCommand | kCGEventFlagMaskShift | kCGEventFlagMaskAlphaShift | kCGEventFlagMaskControl)) {
        [gKeySheetValue appendBytes:(unsigned char[]){0xFF} length:1];
        gKeySheetValueLength++;
    }
    
    [_keyLabel2 setStringValue:keyCodeToString(gKeySheetValue)];
    // [NSString stringWithFormat:@"%@", gKeySheetValue]
}
- (void)keySheetClosed:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (!prefEnabled) {
        disableEventTap();
    }
    keySheetIsActive = NO;
    
    if (returnCode == 0xff) return;
    
    CGKeyCode keycode = (CGKeyCode)[(__bridge NSNumber *)contextInfo intValue] >> 8;
    int oya =[(__bridge NSNumber *)contextInfo intValue] & 0xff;
    
    NSData *new_value = [NSData dataWithData:gKeySheetValue];   // N.B. 10.9 or lower does not support NSMutableData.length
    gKeySheetValue = nil;
    gKeySheetValueLength = 0;
    
    ViewDataModel* model = ((ViewDataModel *)prefLayout[keycode]);
    if (! [new_value isEqualToData:[(ViewDataModel *)prefLayout[keycode] getKeyData:oya]]) {
        if (oya == 0) {
            model.center = new_value;
        } else if (oya == 1) {
            model.left = new_value;
        } else if (oya == 2) {
            model.right = new_value;
        } else if (oya == 3) {
            model.outer = new_value;
        } else if (oya == 4) {
            model.ascii = new_value;
        } else if (oya == 5) {
            model.shift = new_value;
        } else if (oya == 6) {
            model.modifier = new_value;
        }
        self.propLayout = prefLayout;   // update UserDefaults
        // [sender reloadData];
    }
}

- (void)properSheetClosed:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (!prefEnabled) {
        disableEventTap();
    }
    properSheetIsActive = NO;
    
    if (returnCode == 0xff) return;
    
    CGKeyCode keycode = (CGKeyCode)[(__bridge NSNumber *)contextInfo intValue] >> 8;
    
    ViewDataModel* model = ((ViewDataModel *)prefLayout[keycode]);
    model.proper = [_properText stringValue];
    self.propLayout = prefLayout;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    return (prefLayout == nil || [prefLayout count] != LAYOUT_KEY_COUNT) ? 0 : (sizeof(viewTable) / sizeof(CGKeyCode));
}

static int getOyaByIdentifier(NSString *identifier) {
    return (([identifier isEqualToString:@"center"]) ? 0 :
            ([identifier isEqualToString:@"left"]) ? 1 :
            ([identifier isEqualToString:@"right"]) ? 2 :
            ([identifier isEqualToString:@"outer"]) ? 3 :
            ([identifier isEqualToString:@"ascii"]) ? 4 :
            ([identifier isEqualToString:@"shift"]) ? 5 :
            ([identifier isEqualToString:@"modifier"]) ? 6 :
            -1);
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0 || sizeof(viewTable) / sizeof(CGKeyCode) <= row) {
        return nil;
    }
    int oya = getOyaByIdentifier([tableColumn identifier]);
    
    if([[tableColumn identifier] isEqualToString:@"keycode"]) {
        NSTextFieldCell* txcell = [[NSTextFieldCell alloc] init];
        return txcell;
        
    } else if(oya == 2) {
        NSButtonCell* btcell = [[NSButtonCell alloc] init];
        
        [btcell setTarget:self];
        [btcell setAction:@selector(clickPropButton:)];
        
        [btcell setBezelStyle:NSBezelStyleRoundRect];   // NSRecessedBezelStyle, NSInlineBezelStyle
        [btcell setTitle:[(ViewDataModel *)prefLayout[viewTable[row]] proper]];
        
        return btcell;

    } else if(oya >= 0) {
        NSButtonCell* btcell = [[NSButtonCell alloc] init];
        
        [btcell setTarget:self];
        [btcell setAction:@selector(clickButton:)];
        
        [btcell setBezelStyle:NSBezelStyleRoundRect];   // NSRecessedBezelStyle, NSInlineBezelStyle
        [btcell setTitle:keyCodeToString([(ViewDataModel *)prefLayout[viewTable[row]] getKeyData:oya])];
        
        return btcell;
    }
    
    return nil;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    if (row < 0 || sizeof(viewTable) / sizeof(CGKeyCode) <= row) {
        return nil;
    }
    int oya = getOyaByIdentifier([tableColumn identifier]);
    
    if([[tableColumn identifier] isEqualToString:@"keycode"]) {
        return [(ViewDataModel *)prefLayout[viewTable[row]] getKeycodeString];
        
    } else if(oya == 2) {
        return ((ViewDataModel *)prefLayout[viewTable[row]]).proper;

    } else if(oya >= 0) {
        return 0;
        
    }
    
    return nil;
}


- (BOOL)loadPreferences:(id)udict ignoreEnabled:(BOOL)ignoreEnabled {
    if (udict == nil) {
        return NO;
    }
    id value;
    
    // かな入力
    BOOL bcMode = ((value = [udict objectForKey:@"mode"]) != nil && [value intValue]) ? YES : NO;
    // 小指シフト＋数字キーで記号入力（かな入力のみ）
    BOOL bcKoyubi = ((value = [udict objectForKey:@"koyubi"]) != nil && [value intValue]) ? YES : NO;
    // 後退キーのエミュレーション
    BOOL bcBsemu = ((value = [udict objectForKey:@"bsemu"]) != nil && [value intValue]) ? YES : NO;
    // 取消キーのエミュレーション
    BOOL bcEscemu = ((value = [udict objectForKey:@"escemu"]) != nil && [value intValue]) ? YES : NO;
    // 小指シフトで半濁音を入力
    BOOL bcPinky = ((value = [udict objectForKey:@"pinky"]) != nil && [value intValue]) ? YES : NO;
    
    debugOut(@"bcMode   = %d\n", bcMode);
    debugOut(@"bcKoyubi = %d\n", bcKoyubi);
    debugOut(@"bcBsemu  = %d\n", bcBsemu);
    debugOut(@"bcEscemu = %d\n", bcEscemu);
    debugOut(@"bcPinky  = %d\n", bcPinky);
    
    if ((value = [udict objectForKey:@"cshift"]) != nil) {
        self.propCshift = [value intValue] ? YES : NO;
    }
    if ((value = [udict objectForKey:@"returnemu"]) != nil) {
        self.propReturnemu = [value intValue] ? YES : NO;
    }
    if (!self.propReturnemu && (value = [udict objectForKey:@"firstIgnoredSingleThumbL"]) != nil) {
        self.propFirstIgnoredSingleThumbL = [value intValue] ? YES : NO;
    }
    
    if ((value = [udict objectForKey:@"spaceemu"]) != nil) {
        self.propSpaceemu = [value intValue] ? YES : NO;
    }
    if (!self.propSpaceemu && (value = [udict objectForKey:@"firstIgnoredSingleThumbR"]) != nil) {
        self.propFirstIgnoredSingleThumbR = [value intValue] ? YES : NO;
    }
    
    if ((value = [udict objectForKey:@"thumbL"]) != nil) {
        self.propThumbL = [value intValue];
    }
    if ((value = [udict objectForKey:@"thumbR"]) != nil) {
        self.propThumbR = [value intValue];
    }
    if ((value = [udict objectForKey:@"twait"]) != nil) {
        self.propTwait = [value doubleValue] * 1000;
    }
    
    NSDictionary *layout = [udict objectForKey:(NSString *)@"layout"];
    if (layout.count != LAYOUT_KEY_COUNT) {
        return NO;
    }
    
    NSMutableArray *keyData1 = [[NSMutableArray alloc] initWithCapacity:LAYOUT_KEY_COUNT];
    
    int count = 0;
    for (id obj in [layout objectEnumerator]) {
        ViewDataModel *model = [[ViewDataModel alloc] init];
        
        int keycode = ((count < LAYOUT_KEY_COUNT - 2) ? count :
                       (count == LAYOUT_KEY_COUNT - 2) ? kVK_JIS_Yen :
                       (count == LAYOUT_KEY_COUNT - 1) ? kVK_JIS_Underscore :
                       0xff);
        count++;
        
        model.keycode = keycode;
        model.center = convKeyData(obj[@"No shift"]);
        model.left = convKeyData(obj[@"With left shift"]);
        model.right = convKeyData(obj[@"With right shift"]);
        model.outer = convKeyData(obj[@"With outer shift"]);
        model.ascii = convKeyData(obj[@"ASCII - No shift"]);
        model.shift = convKeyData(obj[@"ASCII - With outer shift"]);
        model.modifier = convKeyData(obj[@"With modifier key"]);
        model.proper = obj[@"Proper noun"];

        // backward compatibility: 後退／取消キーのエミュレーション
//        if (keycode == kVK_ANSI_Quote && bcBsemu) {
//            model.center = model.left = model.right = model.outer = [[NSData alloc] initWithBytes:(unsigned char[]){kVK_Delete} length:1];
//        }
//        if (keycode == kVK_ANSI_Backslash && bcEscemu) {
//            model.center = model.left = model.right = model.outer = [[NSData alloc] initWithBytes:(unsigned char[]){kVK_Escape} length:1];
//        }
        // backward compatibility: 小指シフトの定義がなければデフォルト
        if (model.outer == nil) {
            if (bcMode && bcKoyubi && (0x12 <= keycode && keycode <= 0x1D) && keycode != 0x18 && keycode != 0x1B) {
                // backward compatibility: かな入力＆小指シフト＋数字キーで記号入力
                model.outer = [[NSData alloc] initWithBytes:(unsigned char[]){kVK_Option, kVK_Shift, keycode, 0xff} length:4];
            } else {
                model.outer = [[NSData alloc] initWithBytes:(unsigned char[]){kVK_Shift, keycode, 0xff} length:3];
            }
        }
        if (model.ascii == nil) {
            model.ascii = [[NSData alloc] initWithBytes:(unsigned char[]){keycode} length:1];
        }
        if (model.shift == nil) {
            model.shift = [[NSData alloc] initWithBytes:(unsigned char[]){kVK_Shift, keycode, 0xff} length:3];
        }
        if (model.modifier == nil) {    // 修飾キーは入力時に追加
            model.modifier = [[NSData alloc] initWithBytes:(unsigned char[]){keycode} length:1];
        }
        
        if (model.center == nil || model.left == nil || model.right == nil) {
            return NO;
        }

        if (model.proper == nil) {
            model.proper = @"";
        }
        [keyData1 addObject:model];
    }
    
    // backward compatibility: 小指シフトで半濁音を入力
//    if (bcPinky) {
//        static unsigned char pinkyTable[] = {kVK_ANSI_H, kVK_ANSI_Y, kVK_ANSI_X, kVK_ANSI_P, kVK_ANSI_V, kVK_ANSI_N, kVK_ANSI_B, kVK_ANSI_Comma, kVK_ANSI_Period, kVK_ANSI_L};
//        for(int i = 0; i < sizeof(pinkyTable); i += 2) {
//            ((ViewDataModel *)keyData1[pinkyTable[i]]).outer = [(ViewDataModel *)keyData1[pinkyTable[i + 1]] getKeyData:1];
//        }
//    }
    
    if (ud != udict || bcMode || bcKoyubi || bcBsemu || bcEscemu || bcPinky) {
        self.propLayout = keyData1;
        if (bcMode)
            [ud setObject:@(0) forKey:@"mode"];
        if (bcKoyubi)
            [ud setObject:@(0) forKey:@"koyubi"];
        if (bcBsemu)
            [ud setObject:@(0) forKey:@"bsemu"];
        if (bcEscemu)
            [ud setObject:@(0) forKey:@"escemu"];
        if (bcPinky)
            [ud setObject:@(0) forKey:@"pinky"];
        [ud synchronize];
    } else {
        prefLayout = keyData1;  // do not update UserDefaults
        [_tableView reloadData];
    }
    
    if (!ignoreEnabled && (value = [udict objectForKey:@"enabled"]) != nil) {
        self.propEnabled = [value intValue] ? YES : NO;
    }
    
    return YES;
}
static NSData *convKeyData(NSData *in) {
    if (in == nil) {
        return nil;
    }
    NSMutableData *out = [[NSMutableData alloc] initWithCapacity:(in.length + 1)];
    
    BOOL needs_reset = NO;
    const void *in_ptr = in.bytes;
    
    if (in.length >= 4 && *(unsigned char *)(in.bytes + 2) == 0xff) {
        // backward compatibility: 4 バイト以上で ff modifier ff または modifier ff ff の場合、
        // 先頭の ff は、最初に修飾キーだけを押下してすぐに解除したい場合のパディングなので、残す。
        if ((*(unsigned char *)(in.bytes) == 0xff && *(unsigned char *)(in.bytes + 1) != 0xff) ||
            (*(unsigned char *)(in.bytes) != 0xff && *(unsigned char *)(in.bytes + 1) == 0xff)) {
            [out appendBytes:in_ptr length:1];
        }
    }
    
    for (int i = 0; i < in.length; i++) {
        unsigned char key = *(unsigned char *)(in_ptr);
        // backward compatibility: 先頭 2 バイトと末尾の ff は読み飛ばす。
        if (key != 0xff || (1 < i && i < in.length - 1)) {
            [out appendBytes:in_ptr length:1];
            
            if (key == kVK_Option || key == kVK_Command || key == kVK_Shift || key == kVK_CapsLock || key == kVK_Control || key == kVK_RightOption || key == kVK_RightCommand || key == kVK_RightShift || key == kVK_RightControl) {
                needs_reset = YES;
            } else if (key == 0xff) {
                needs_reset = NO;
            }
        }
        in_ptr++;
    }
    if (needs_reset) {
        [out appendBytes:(unsigned char[]){0xff} length:1];
    }
    return [NSData dataWithData:out];   // N.B. 10.9 or lower does not support NSMutableData.length
}
static NSData *convTraditionalKeyData(NSData *in) {
    if (in == nil) {
        return nil;
    }
    
    // backward compatibility: 可能な限り 0xff でパディングした 3 バイトの値で UserDefaults に保存する。
    if (in.length <= 2) {
        unsigned char out[] = {0xff, 0xff, 0xff};
        [in getBytes:out length:in.length];
        return [[NSData alloc] initWithBytes:out length:3];
        
    } else if (in.length == 3) {
        return in;
        
    } else {
        const void *ptr = [in bytes];
        if (*(unsigned char*)(ptr + in.length - 1) == (unsigned char)0xff) {
            return [in subdataWithRange:NSMakeRange(0, in.length - 1)];
        }
        return in;
    }
}

- (IBAction)loadLayout:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[@"plist"];
    [openPanel beginSheetModalForWindow:[sender window] completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *openURL = openPanel.URLs[0];
            
            if (![self loadPreferences:[NSDictionary dictionaryWithContentsOfURL:openURL] ignoreEnabled:NO]) {
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"import_error_message", nil)
                                                 defaultButton:NSLocalizedString(@"import_error_ok", nil)
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"import_error_text", nil)];
                alert.alertStyle = NSAlertStyleCritical;
                [alert runModal];
            }
            
            
        } else {
            [openPanel close];
        }
    }];
}
- (IBAction)selectThumbL:(id)sender {
    [self openOyaSheet:@"key_thumbL" contextInfo:@"thumbL"];
}
- (IBAction)selectThumbR:(id)sender {
    [self openOyaSheet:@"key_thumbR" contextInfo:@"thumbR"];
}
- (void)openOyaSheet:(NSString*)stringValue contextInfo:(NSString*)contextInfo {
    [_oyaLabel setStringValue:NSLocalizedString(stringValue, nil)];
    if (!prefEnabled && !enableEventTap()) {
        return;
    }
    oyaSheetIsActive = YES;
    // N.B. 10.9 and above: [_window beginSheet:completionHandler]
    [NSApp beginSheet: _oyaSheet
       modalForWindow: _window
        modalDelegate: self
       didEndSelector: @selector(oyaSheetClosed:returnCode:contextInfo:)
          contextInfo: (__bridge void *)contextInfo];
}
- (void)closeOyaSheet:(CGKeyCode)keyCode {
    [NSApp endSheet:_oyaSheet returnCode:keyCode];
    [_oyaSheet close];
}
- (void)oyaSheetClosed:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (!prefEnabled) {
        disableEventTap();
    }
    oyaSheetIsActive = NO;
    if (returnCode == 0xff) return;
    
    if ([@"thumbL" isEqualToString: (__bridge id)contextInfo]) {
        self.propThumbL = returnCode;
    } else if ([@"thumbR" isEqualToString: (__bridge id)contextInfo]) {
        self.propThumbR = returnCode;
    }
}
- (IBAction)oyaCancel:(id)sender {
    [self closeOyaSheet:0xff];
}
- (IBAction)showPreferences:(id)sender {
    // [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    ProcessSerialNumber psn = {0, kCurrentProcess};
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    
    [_window makeKeyAndOrderFront:self];
    [_tabView selectTabViewItemAtIndex:0];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesWindowWillClose)
                                                 name:NSWindowWillCloseNotification
                                               object:_window];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
}

- (IBAction)radioSingleThumbL:(id)sender {
    NSInteger tag = [sender tag];
    
    [self setPropFirstIgnoredSingleThumbL:(tag == 1)];
    [self setPropReturnemu:(tag == 2)];
}

- (IBAction)radioSingleThumbR:(id)sender {
    NSInteger tag = [sender tag];
    
    [self setPropFirstIgnoredSingleThumbR:(tag == 1)];
    [self setPropSpaceemu:(tag == 2)];
}

- (IBAction)showAboutBox:(id)sender {
    // [NSApp orderFrontStandardAboutPanel:sender];
    [self showPreferences:nil];
    [_tabView selectTabViewItemAtIndex:1];
}

-(void)preferencesWindowWillClose {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowWillCloseNotification
                                                  object:_window];
    // [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    ProcessSerialNumber psn = {0, kCurrentProcess};
    TransformProcessType(&psn, kProcessTransformToUIElementApplication);
}

- (void)awakeFromNib {
    // [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    ProcessSerialNumber psn = {0, kCurrentProcess};
    TransformProcessType(&psn, kProcessTransformToUIElementApplication);
    
    imgActive = [NSImage imageNamed:@"nagi_active"];
    imgInactive = [NSImage imageNamed:@"nagi_inactive"];
    imgDisabled = [NSImage imageNamed:@"nagi_inactive"];

    NSString *rtfFilePath = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"];
    [_aboutBox readRTFDFromFile:rtfFilePath];
    _copyrightBox.stringValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
    _versionBox.stringValue = [NSString stringWithFormat:NSLocalizedString(@"version_string", nil),
                               [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                               [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    
    sbItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSSquareStatusItemLength];
    sbItem.button.image = imgDisabled;
    sbItem.button.alternateImage = [NSImage imageNamed:@"nagi_active"];
    sbItem.button.toolTip = @"Benkei";
    [sbItem setHighlightMode: YES];
    sbItem.menu = _sbMenu;
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self_ = self;
    
    NSError *__strong outError = nil;
    BOOL noEventTap = NO;
    BOOL firstRun = NO;
    if (ud == nil) {
        ud = [NSUserDefaults standardUserDefaults];
        if ([ud objectForKey: @"enabled"] == nil) {
            firstRun = YES;
        }
        
        [ud registerDefaults: [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"]]];
        [self loadPreferences:ud ignoreEnabled:(noEventTap || firstRun)];
    }
    if (firstRun) {
        self.propEnabled = NO;
        [ud setObject:@(0) forKey:@"enabled"];
        [ud synchronize];
        
        [self showPreferences:nil];
        [_tabView selectTabViewItemAtIndex:1];
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"welcome_message", nil)
                                         defaultButton:NSLocalizedString(@"welcome_ok", nil)
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"welcome_text", nil)];
        alert.alertStyle = NSAlertStyleInformational;
        [alert runModal];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05f]];
    }
    
    if (!checkEventTap(&outError)) {
        noEventTap = YES;
        // if (outError) {
        //     [self_ showPreferences:nil];
        //     NSAlert *alert = [NSAlert alertWithMessageText:outError.localizedDescription
        //                                      defaultButton:NSLocalizedString(@"eventTap_error_ok", nil)
        //                                    alternateButton:nil
        //                                        otherButton:nil
        //                          informativeTextWithFormat:@"%@", outError.localizedRecoverySuggestion];
        //     alert.alertStyle = NSCriticalAlertStyle;
        //     [alert runModal];
        // }
    }
    
    naginata = [Naginata new];
    naginata.kouchiShift = self.propCshift;
    naginata.doujiTime = prefTwait;

    gBuff = 0xff;
    gOya = 0;
    gOyaKeyDownTimeStamp = [NSDate date];
    gPrevOya = 0;
    gPressedOya = 0;
    
    CGEventRef tmp_event = CGEventCreateKeyboardEvent(NULL, 0, YES);
    CGEventSourceRef tmp_source = CGEventCreateSourceFromEvent(tmp_event);
    gKeyboardType = CGEventSourceGetKeyboardType(tmp_source);
    gTargetPid = 0;
    CFRelease(tmp_event);
    CFRelease(tmp_source);
    
    gLock = [[NSLock alloc] init];
    oyaSheetIsActive = NO;
    keySheetIsActive = NO;
    
    // 入力ソースの監視
    gKanaMethod = NO;
    arKanaMethods = @[@"com.apple.inputmethod.Japanese",
                      @"com.apple.inputmethod.Japanese.Katakana",
                      @"com.apple.inputmethod.Japanese.HalfWidthKana"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardInputSourceChanged:)
                                                 name:NSTextInputContextKeyboardSelectionDidChangeNotification
                                               object:nil];
    [self keyboardInputSourceChanged:nil];
    
    if (prefEnabled) {
        if (noEventTap || !enableEventTap()) {
            self.propEnabled = NO;
        }
    }
    [self updateSbIcon];
    
    debugOut(@"Start\n");
}

BOOL checkLayout(NSError *__autoreleasing *outError) {
    if (prefLayout == nil) {
        if (outError != NULL) {
            *outError = [[NSError alloc]
                         initWithDomain:BenkeiErrorDomain
                         code:BenkeiErrorLayoutNotLoad
                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"no_layout_message", nil),
                                    NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"no_layout_text", nil)}
                         ];
        }
        return NO;
    }
    return YES;
}

BOOL checkEventTap(NSError *__autoreleasing *outError) {
    if (AXIsProcessTrustedWithOptions != NULL) {
        // 10.9 or higher
        NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: (id)kCFBooleanTrue};
        if (!AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options)) {
            if (outError != NULL) {
                *outError = [[NSError alloc]
                             initWithDomain:BenkeiErrorDomain
                             code:BenkeiErrorNoEventTap
                             userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"eventTap_error_message", nil),
                                        NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"eventTap_error_text", nil)}
                             ];
            }
            return NO;
        }
    }
    
    CFMachPortRef eventTapTest = CGEventTapCreate(kCGAnnotatedSessionEventTap, kCGHeadInsertEventTap, 0,
                                                  CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged),
                                                  keyUpDownEventCallback, NULL);
    if (!eventTapTest) {
        if (outError != NULL) {
            *outError = [[NSError alloc]
                         initWithDomain:BenkeiErrorDomain
                         code:BenkeiErrorNoEventTap
                         userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"eventTap_error_message", nil),
                                    NSLocalizedRecoverySuggestionErrorKey:((AXIsProcessTrustedWithOptions != NULL) ?
                                                                           NSLocalizedString(@"eventTap_error_text", nil) :
                                                                           NSLocalizedString(@"eventTap_error_text108", nil))
                                    }
                         ];
        }
        return NO;
    }
    CGEventTapEnable(eventTapTest, false);
    return YES;
}

BOOL enableEventTap() {
    disableEventTap();
    
    NSError *__strong outError = nil;
    if (!checkLayout(&outError) || !checkEventTap(&outError)) {
        if (outError) {
            [self_ showPreferences:nil];
            NSAlert *alert = [NSAlert alertWithMessageText:outError.localizedDescription
                                             defaultButton:NSLocalizedString(@"eventTap_error_ok", nil)
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"%@", outError.localizedRecoverySuggestion];
            alert.alertStyle = NSAlertStyleCritical;
            [alert runModal];
        }
        return NO;
    }
    
    eventTap = CGEventTapCreate(kCGAnnotatedSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault,
                                CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged),
                                keyUpDownEventCallback, NULL);
    
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    
    return YES;
}

void disableEventTap() {
    if (eventTap) {
        CGEventTapEnable(eventTap, false);
        eventTap = NULL;
    }
    if (runLoopSource) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        runLoopSource = NULL;
    }
    gPrevOya = 0;
    gOya = 0;
}

void myCGEventPostToPid(pid_t pid, CGEventRef event) {
    if (!pid || event == NULL) {
        return;
    }
    CFRetain(event);
    
    debugOut(@"[Post] Type=%d Keycode=%d, Flags=<%llx>, Pid=%d\n",
             CGEventGetType(event), (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode),
             (CGEventFlags)CGEventGetFlags(event), pid);
    if (CGEventPostToPid != NULL) {
        // 10.11 or higher
        CGEventPostToPid(pid, event);
        
    } else {
        ProcessSerialNumber psn;
        if (!GetProcessForPID(pid, &psn)) {
            CGEventPostToPSN(&psn, event);
        }
        
    }
}

static inline CGEventFlags myCGEventGetFlags(CGEventRef event) {
    CGEventFlags flags = (CGEventFlags)CGEventGetFlags(event);
    CGEventFlags usedFlags = 0;
    for(int i = 0; i < 2; i++) {
        switch (i == 0 ? prefThumbL : prefThumbR) {
            case kVK_Option: case kVK_RightOption:      usedFlags |= kCGEventFlagMaskAlternate;     break;
            case kVK_Command: case kVK_RightCommand:    usedFlags |= kCGEventFlagMaskCommand;       break;
            case kVK_Shift: case kVK_RightShift:        usedFlags |= kCGEventFlagMaskShift;         break;
            case kVK_CapsLock:                          usedFlags |= kCGEventFlagMaskAlphaShift;    break;
            case kVK_Control:                           usedFlags |= kCGEventFlagMaskControl;       break;
        }
    }
    if (flags & (kCGEventFlagMaskAlternate | kCGEventFlagMaskCommand | kCGEventFlagMaskShift | kCGEventFlagMaskAlphaShift | kCGEventFlagMaskControl) & ~usedFlags) {
        return flags;
    }
    return (flags &~ (gEventMasks & usedFlags));
}

static inline CGEventRef returnPt(CGEventRef event, CGEventSourceRef source) {
    debugOut(@"[RetP] Type=%d Keycode=%d, Flags=<%llx>, Pid=%d\n",
             CGEventGetType(event), (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode),
             (CGEventFlags)CGEventGetFlags(event),
             (pid_t)CGEventGetIntegerValueField(event, kCGEventTargetUnixProcessID));
    gPressedOya = 0;
    fireTimer();
    if(source != NULL) {
        CFRelease(source);
    }
    return event;
}

static CGEventRef keyUpDownEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    // Renable the eventTap when kCGEventTapDisabledByTimeout event come.
    // see http://lists.apple.com/archives/quartz-dev/2009/Sep/msg00006.html
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        if (eventTap) CGEventTapEnable(eventTap, true);
        return event;
    }
    
    // Pass through
    if ((CGEventFlags)CGEventGetFlags(event) & 0x20000000 ||
        (pid_t)CGEventGetIntegerValueField(event, kCGEventSourceUnixProcessID) == getpid()) {
        debugOut(@"[PT] Keycode=%d, Flags=<%llx>, Type=%d, targetPid=%d\n",
                 (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode),
                 (CGEventFlags)CGEventGetFlags(event), type,
                 (pid_t)CGEventGetIntegerValueField(event, kCGEventTargetUnixProcessID)
                 );
        return event;
    }
    
    // support for modifier keys
    if (type == kCGEventFlagsChanged) {
        CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        CGEventFlags masksForThisKey = 0;
        switch(keycode) {
            case kVK_Option: case kVK_RightOption:      masksForThisKey = kCGEventFlagMaskAlternate;    break;
            case kVK_Command: case kVK_RightCommand:    masksForThisKey = kCGEventFlagMaskCommand;      break;
            case kVK_Shift: case kVK_RightShift:        masksForThisKey = kCGEventFlagMaskShift;        break;
            case kVK_CapsLock:                          masksForThisKey = kCGEventFlagMaskAlphaShift;   break;
            case kVK_Control:                           masksForThisKey = kCGEventFlagMaskControl;      break;
            default:                                    return event;
        }
        if (masksForThisKey) {
            type = ((CGEventFlags)CGEventGetFlags(event) & masksForThisKey) ? kCGEventKeyDown : kCGEventKeyUp;
            if (type == kCGEventKeyUp) {
                gEventMasks &= ~masksForThisKey;
            } else {
                gPressedOya = 0;
            }
            if (keycode == prefThumbL || keycode == prefThumbR || (oyaSheetIsActive && (pid_t)CGEventGetIntegerValueField(event, kCGEventTargetUnixProcessID) == getpid())) {
                if (type == kCGEventKeyDown && gKanaMethod) {
                    gEventMasks |= masksForThisKey;
                }
            } else {
                return event;
            }
        }
    }
    
    // Sanity check
    if ((type != kCGEventKeyDown) && (type != kCGEventKeyUp)) {
        return event;
    }
    
    if (oyaSheetIsActive) {
        if ((pid_t)CGEventGetIntegerValueField(event, kCGEventTargetUnixProcessID) == getpid()) {
            [self_ closeOyaSheet:(CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode)];
            return NULL;
        } else if (!prefEnabled) {
            return event;
        }
    }
    if (keySheetIsActive) {
        if ((pid_t)CGEventGetIntegerValueField(event, kCGEventTargetUnixProcessID) == getpid()) {
            if (type == kCGEventKeyDown) {
                [self_ appendKeySheet:(CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode) modifierKeys:(CGEventFlags)CGEventGetFlags(event) ];
            }
            return NULL;
        } else if (!prefEnabled) {
            return event;
        }
    }
    
    // Event source
    CGEventSourceRef source = CGEventCreateSourceFromEvent(event);
    if (source != NULL) {
        gKeyboardType = CGEventSourceGetKeyboardType(source);
    }
    pid_t targetPid = (pid_t)CGEventGetIntegerValueField(event, kCGEventTargetUnixProcessID);
    
    debugOut(@"[EV] Keycode=%d, Flags=<%llx>, Type=%d, targetPid=%d, gTargetPid=%d\n",
             (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode), (CGEventFlags)CGEventGetFlags(event), type, targetPid, gTargetPid);
    
    CGKeyCode keycode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    
    if (type == kCGEventKeyDown) {
        gKeyDownAutorepeat = CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat);
    }
    
    // 同時判定時間を過ぎていたら親指キーを戻す
    // 薙刀式　連続シフトは常時オンなのでここは削除する
    /*
    if (!prefCshift && (gBuff == prefThumbL || gBuff == prefThumbR) &&
        [[NSDate date] timeIntervalSinceDate:gOyaKeyDownTimeStamp] > prefTwait) {
        unsigned char prevBuff = gBuff;
        CGEventFlags prevEventMasks = gEventMasks;
        switch(gBuff) {
            case kVK_Option: case kVK_RightOption:      gEventMasks &= ~kCGEventFlagMaskAlternate;    break;
            case kVK_Command: case kVK_RightCommand:    gEventMasks &= ~kCGEventFlagMaskCommand;      break;
            case kVK_Shift: case kVK_RightShift:        gEventMasks &= ~kCGEventFlagMaskShift;        break;
            case kVK_CapsLock:                          gEventMasks &= ~kCGEventFlagMaskAlphaShift;   break;
            case kVK_Control:                           gEventMasks &= ~kCGEventFlagMaskControl;      break;
        }
        startTimer(0);
        fireTimer();
        
        // 親指が修飾キーなら親指キーではなく修飾キーとしてもう一度押す
        if (prevEventMasks != gEventMasks) {
            myCGEventPostToPid(targetPid, CGEventCreateKeyboardEvent(source, prevBuff, YES));
            // yield しないと順序が逆になる
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05f]];
        }
    }
    */ // ここまで削除
    gTargetPid = targetPid;
    
    // remove thumb keys from event flags
//    CGEventSetFlags(event, myCGEventGetFlags(event));
    
    // Control, Alt or Option, Command, Help, Fn (Function), numeric keypad
    if (myCGEventGetFlags(event) & (kCGEventFlagMaskControl | kCGEventFlagMaskAlternate |
                                    kCGEventFlagMaskCommand | kCGEventFlagMaskHelp |
                                    kCGEventFlagMaskSecondaryFn | kCGEventFlagMaskNumericPad)) {
        if (keycode < 0x0A || (0x0A < keycode && keycode < 0x24) || (0x24 < keycode && keycode < 0x30) || keycode == kVK_JIS_Yen || keycode == kVK_JIS_Underscore) {

            NSData *newkey = getKeyDataForOya(keycode, 6);

            if (newkey.length == 1) {
                // backward compatibility: 修飾キーのキー定義がデフォルト or 1文字のときは returnPt を使う
                if (! [newkey isEqualToData:[[NSData alloc] initWithBytes:(unsigned char[]){keycode} length:1]]) {
                    CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode,
                                                (CGKeyCode)(*(unsigned char *)(newkey.bytes) & 0xff));
                }
                return returnPt(event, source);
            }

            if (type == kCGEventKeyDown) {
                fireTimer();

                pressKeys(source, targetPid, newkey, myCGEventGetFlags(event));
            }
            if(source != NULL) {
                CFRelease(source);
            }
            return NULL;
        }
        return returnPt(event, source);
    }
    
    if (!gKanaMethod) { // 日本語入力でない
        gOya = 0;
        gPrevOya = 0;
        [naginata deepClear];

        // 薙刀式処理
        /*
         hjbuf keycode   press             release
         空     H/J     next               H/J出力+continue
         空     HJ以外   continue           continue
         H/J    H/J     kVK_JIS_Kana+next  continue
         H/J    HJ以外   H/J出力+continue    continue
        */
        if (type == kCGEventKeyDown) {
            if (hjbuf == 0) {
                if (keycode == kVK_ANSI_H || keycode == kVK_ANSI_J) {
                    hjbuf = keycode;
                    return NULL;
                }
            } else {
                if (hjbuf + keycode == kVK_ANSI_H + kVK_ANSI_J) {
                    NSData *newkey = [[NSData alloc] initWithBytes:(unsigned char[]){kVK_JIS_Kana} length:1];
                    pressKeys(source, targetPid, newkey, myCGEventGetFlags(event));
                    hjbuf = 0;
                    return NULL;
                } else {
                    NSData *newkey = [[NSData alloc] initWithBytes:(unsigned char[]){hjbuf, keycode} length:2];
                    pressKeys(source, targetPid, newkey, myCGEventGetFlags(event));
                    hjbuf = 0;
                    return NULL;
                }
            }
        } else if (type == kCGEventKeyUp) {
            if (hjbuf > 0 && hjbuf == keycode) {
                NSData *newkey = [[NSData alloc] initWithBytes:(unsigned char[]){hjbuf} length:1];
                pressKeys(source, targetPid, newkey, myCGEventGetFlags(event));
                hjbuf = 0;
            }
        }
        
//        修飾キーが効かない
//        curkey = keycode;
//        if (type == kCGEventKeyDown && (keycode == kVK_ANSI_H || keycode == kVK_ANSI_J)) {
//            gvalid = true;
//            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_MSEC));
//            dispatch_after(time, dispatch_get_main_queue(), ^{
//                CGKeyCode firstkey = keycode;
//                debugOut(@"[GCD] keycode=%d\n", keycode);
//                @synchronized ([NSNumber numberWithInt:keycode]) {
//                    if (gvalid) {
//                        if (curkey + firstkey == kVK_ANSI_H + kVK_ANSI_J) {
//                            debugOut(@"[GCD] Naginata ON\n");
//                            [naginata clear];
//                            pressKeys2(source, targetPid, @[[NSNumber numberWithInt:kVK_JIS_Kana]]);
//                            gvalid = false;
//                        } else {
//                            pressKeys2(source, targetPid, @[[NSNumber numberWithInt:firstkey]]);
//                        }
//                    }
//                }
//            });
//            return NULL;
//        }
//        文字の逆転を防止したいが、waitは効かない
//        if (gvalid && (keycode != kVK_ANSI_H && keycode != kVK_ANSI_J)) {
//            [NSThread sleepForTimeInterval:0.05f];
//        }
        
        
//        if (keycode < 0x0A || (0x0A < keycode && keycode < 0x24) || (0x24 < keycode && keycode < 0x30) || keycode == kVK_JIS_Yen || keycode == kVK_JIS_Underscore) {
//
//            NSData *newkey;
//            if (myCGEventGetFlags(event) & kCGEventFlagMaskShift) {
//                newkey = getKeyDataForOya(keycode, 5);
//
//                if (newkey.length == 3 && (CGKeyCode)(*(unsigned char *)(newkey.bytes) & 0xff) == kVK_Shift && (CGKeyCode)(*(unsigned char *)(newkey.bytes + 2) & 0xff) == 0xff) {
//                    // backward compatibility: シフト（英）のキー定義がデフォルト or 1文字のときは returnPt を使う
//                    if (! [newkey isEqualToData:[[NSData alloc] initWithBytes:(unsigned char[]){kVK_Shift, keycode, 0xff} length:3]]) {
//                        CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode,
//                                                    (CGKeyCode)(*(unsigned char *)(newkey.bytes + 1) & 0xff));
//                    }
//                    return returnPt(event, source);
//                }
//            } else {
//                newkey = getKeyDataForOya(keycode, 4);
//
//                if (newkey.length == 1) {
//                    // backward compatibility: 単独打鍵（英）のキー定義がデフォルト or 1文字のときは returnPt を使う
//                    if (! [newkey isEqualToData:[[NSData alloc] initWithBytes:(unsigned char[]){keycode} length:1]]) {
//                        CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode,
//                                                    (CGKeyCode)(*(unsigned char *)(newkey.bytes) & 0xff));
//                    }
//                    return returnPt(event, source);
//                }
//            }
//
//            if (type == kCGEventKeyDown) {
//                fireTimer();
//
//                if (myCGEventGetFlags(event) & kCGEventFlagMaskShift)
//                    myCGEventPostToPid(targetPid, CGEventCreateKeyboardEvent(source, kVK_Shift, NO));    // Shift
//                pressKeys(source, targetPid, newkey, (CGEventFlags)0);
//                if (myCGEventGetFlags(event) & kCGEventFlagMaskShift)
//                    myCGEventPostToPid(targetPid, CGEventCreateKeyboardEvent(source, kVK_Shift, YES));   // Shift
//            }
//            if(source != NULL) {
//                CFRelease(source);
//            }
//            return NULL;
//        }
        return returnPt(event, source);
    }
    
//    if (myCGEventGetFlags(event) & kCGEventFlagMaskShift) {
//        if (keycode < 0x0A || (0x0A < keycode && keycode < 0x24) || (0x24 < keycode && keycode < 0x30) || keycode == kVK_JIS_Yen || keycode == kVK_JIS_Underscore) {
//
//            NSData *newkey = getKeyDataForOya(keycode, 3);
//
//            if (newkey.length == 3 && (CGKeyCode)(*(unsigned char *)(newkey.bytes) & 0xff) == kVK_Shift && (CGKeyCode)(*(unsigned char *)(newkey.bytes + 2) & 0xff) == 0xff) {
//                // backward compatibility: 小指シフトのキー定義がデフォルト or 1文字のときは returnPt を使う
//                if (! [newkey isEqualToData:[[NSData alloc] initWithBytes:(unsigned char[]){kVK_Shift, keycode, 0xff} length:3]]) {
//                    CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode,
//                                                (CGKeyCode)(*(unsigned char *)(newkey.bytes + 1) & 0xff));
//                }
//                return returnPt(event, source);
//            }
//
//            if (type == kCGEventKeyDown) {
//                fireTimer();
//
//                myCGEventPostToPid(targetPid, CGEventCreateKeyboardEvent(source, kVK_Shift, NO));    // Shift
//                pressKeys(source, targetPid, newkey, (CGEventFlags)0);
//                myCGEventPostToPid(targetPid, CGEventCreateKeyboardEvent(source, kVK_Shift, YES));   // Shift
//            }
//            if(source != NULL) {
//                CFRelease(source);
//            }
//            return NULL;
//
//        } else if (prefReturnemu && keycode == prefThumbL) {
//            CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, (CGKeyCode)kVK_Return);
//        } else if (prefSpaceemu && keycode == prefThumbR) {
//            CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, (CGKeyCode)kVK_Space);
//        }
//        return returnPt(event, source);
//    }
    
    // backward compatibility: 後退／取消キーのエミュレーションでは returnPt を使う
//    BOOL is_bs = YES;
//    BOOL is_esc = YES;
//    for(int i = 0; i <= 2 && (is_bs || is_esc); i++) {
//        NSData *newkey = getKeyDataForOya(keycode, i);
//        is_bs = is_bs && newkey.length == 1 && *(unsigned char *)(newkey.bytes) == kVK_Delete;
//        is_esc = is_esc && newkey.length == 1 && *(unsigned char *)(newkey.bytes) == kVK_Escape;
//    }
//    if (is_bs) {
//        CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, (CGKeyCode)kVK_Delete);
//        return returnPt(event, source);
//    }
//    if (is_esc) {
//        CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, (CGKeyCode)kVK_Escape);
//        return returnPt(event, source);
//    }
    
    
    if (keycode <= kVK_ANSI_T || keycode == kVK_ANSI_O || keycode == kVK_ANSI_U || (kVK_ANSI_I <= keycode && keycode <= kVK_ANSI_J) || keycode == kVK_ANSI_K  || keycode == kVK_ANSI_Semicolon || (kVK_ANSI_Comma <= keycode && keycode <= kVK_ANSI_Period) || keycode == kVK_Space || keycode == kVK_Return) { // see viewTable
        // 薙刀式処理
        NSArray *kana;
        if (type == kCGEventKeyDown) {
            kana = [naginata pressKey:keycode];
        } else if (type == kCGEventKeyUp) {
            kana = [naginata releaseKey:keycode];
        }
//        CGEventFlags flag = (CGEventFlags)0;
//        for (NSNumber *k in kana) {
//            if ([k intValue] == kVK_Shift) {
//                flag = kCGEventFlagMaskShift;
//            } else {
//                NSData *newkey = [[NSData alloc] initWithBytes:(unsigned char[]){[k intValue]} length:1];
//                pressKeys(source, targetPid, newkey, flag);
//                flag = (CGEventFlags)0;
//            }
//        }
        if (kana != nil) {
            pressKeys2(source, targetPid, kana);
        }
//        if (type == kCGEventKeyDown) {
//            sendUnicode(source, targetPid, @"？");
//        }
        
        /*
        if (type == kCGEventKeyDown) {
            // 連続シフトで親指を押した
            if (prefCshift && (keycode == prefThumbL || keycode == prefThumbR)) {
                if (!(keycode == prefThumbL && gOya == 1) && !(keycode == prefThumbR && gOya == 2)) { // Autorepeat
                    gPrevOya = gOya;
                    gOya = ((keycode == prefThumbL) ? 1 :
                            (keycode == prefThumbR) ? 2 : 0);
                    if (gOya == gPrevOya) { // Sanity check
                        gPrevOya = 0;
                    }
                    if (gBuff == 0xff) {
                        gBuff = keycode;
                    } else {
                        fireTimer();
                    }
                }
                
            } else if (gBuff == prefThumbL || gBuff == prefThumbR) {    // 親指キー → 文字キー
                gOya = ((gBuff == prefThumbL) ? 1 :
                        (gBuff == prefThumbR) ? 2 :
                        (prefCshift) ? gOya : 0);
                gOyaKeyDownTimeStamp = [NSDate date];
                gBuff = keycode;
                startTimer(0);
                fireTimer();
                
            } else if (gBuff != 0xff) {     // 文字キー → 親指キー
                gOya = ((keycode == prefThumbL) ? 1 :
                        (keycode == prefThumbR) ? 2 :
                        (prefCshift) ? gOya : 0);
                fireTimer();
                
                if (keycode == prefThumbL || keycode == prefThumbR) {
                    gOyaKeyDownTimeStamp = [NSDate date];
                } else {
                    gBuff = keycode;
                    startTimer(0);
                }
                
            } else if (keycode == prefThumbL || keycode == prefThumbR) {    // 文字なし → 親指キー
                gBuff = keycode;
                gOyaKeyDownTimeStamp = [NSDate date];
                
            } else {    // 親指なし → 文字キー
                gBuff = keycode;
                startTimer(0);
                
            }
        } else if (type == kCGEventKeyUp) {
            if (prefCshift && (keycode == prefThumbL || keycode == prefThumbR)) {
                if ((keycode == prefThumbL && (gOya == 1 || gPrevOya == 1)) || (keycode == prefThumbR && (gOya == 2 || gPrevOya == 2))) {   // Autorepeat
                    // 親指キーが押されてから離すまでに一度もキーが押されていなければ、親指キー
                    if (gBuff == keycode) {
                        startTimer(0);
                        fireTimer();
                    }
                    if (gOya == gPrevOya || (keycode == prefThumbL && gPrevOya == 1) || (keycode == prefThumbR && gPrevOya == 2)) { // Sanity check
                        gPrevOya = 0;
                    }
                    if ((keycode == prefThumbL && gOya == 1) || (keycode == prefThumbR && gOya == 2)) {
                        gOya = gPrevOya;
                    }
                    gPrevOya = 0;
                }
            } else if (gBuff == keycode && (keycode == prefThumbL || keycode == prefThumbR)) {
                // 親指キーが離されたら、キーを押された時間に遡ってタイマーをスタート
                startTimer([[NSDate date] timeIntervalSinceDate:gOyaKeyDownTimeStamp]);
                
            } else if (gOya == 0 && (keycode == prefThumbL || keycode == prefThumbR)) {
                // 10.13 の Dock では、Command + Tab の後の Command キーを returnPt で戻さないといけない
                unsigned char key = keycode;
                if (key == kVK_Option || key == kVK_Command || key == kVK_Shift || key == kVK_CapsLock || key == kVK_Control || key == kVK_RightOption || key == kVK_RightCommand || key == kVK_RightShift || key == kVK_RightControl) {
                    return returnPt(event, source);
                }
            }
        }
         */
        if(source != NULL) {
            CFRelease(source);
        }
        return NULL;
    }
    
    debugOut(@"[EndF] Keycode=%d\n", keycode);
    return returnPt(event, source);
}

//static inline void startTimer(NSTimeInterval negativeInterval) {
//    [gLock lock];
//    [gTimer invalidate];
//    NSTimeInterval interval = prefTwait - negativeInterval;
//    gTimer = [NSTimer scheduledTimerWithTimeInterval:(interval >= 0 ? interval : 0)
//                                              target:self_
//                                            selector:@selector(timerFired:)
//                                            userInfo:(__bridge id)nil
//                                             repeats:NO];
//    [gLock unlock];
//}

static inline void fireTimer() {
    [gTimer invalidate];
//    [self_ timerFired:nil];
}

static inline NSData *getKeyDataForOya(CGKeyCode keycode, unsigned char oya) {
    return ((keycode < LAYOUT_KEY_COUNT - 2) ? [(ViewDataModel *)prefLayout[keycode] getKeyData:oya] :
            (keycode == kVK_JIS_Yen) ? [(ViewDataModel *)prefLayout[(LAYOUT_KEY_COUNT - 2)] getKeyData:oya] :
            (keycode == kVK_JIS_Underscore) ? [(ViewDataModel *)prefLayout[(LAYOUT_KEY_COUNT - 1)] getKeyData:oya] :
            [[NSData alloc] initWithBytes:(unsigned char[]){keycode} length:1]);
}

static void pressKeys(CGEventSourceRef source, pid_t targetPid, NSData *newkey, CGEventFlags mask) {
    CGEventFlags flags = mask;
    
    const void *in_ptr = newkey.bytes;
    const void *reset_ptr = in_ptr;
    for (int i = 0; i < newkey.length; i++) {
        unsigned key = *(unsigned char *)(in_ptr++) & 0xff;
        CGEventRef newevent;
        
        if (key == 0xff) {  // 修飾キーを解除する
            flags = mask;
            while (reset_ptr != in_ptr) {
                unsigned key = *(unsigned char *)(reset_ptr++) & 0xff;
                
                if (key == kVK_Option || key == kVK_Command || key == kVK_Shift || key == kVK_CapsLock || key == kVK_Control || key == kVK_RightOption || key == kVK_RightCommand || key == kVK_RightShift || key == kVK_RightControl) {
                    myCGEventPostToPid(targetPid, CGEventCreateKeyboardEvent(source, key, NO));
                }
            }
            continue;
        }
        
        newevent = CGEventCreateKeyboardEvent(source, key, YES);
        CGEventSetFlags(newevent, (myCGEventGetFlags(newevent) & ~kCGEventFlagMaskShift) | flags);
        myCGEventPostToPid(targetPid, newevent);
        
        if (key == kVK_Option || key == kVK_RightOption) {          // Alt or Option
            flags |= kCGEventFlagMaskAlternate;
        } else if (key == kVK_Command || key == kVK_RightCommand) {   // Command
            flags |= kCGEventFlagMaskCommand;
        } else if (key == kVK_Shift || key == kVK_RightShift) {   // Shift
            flags |= kCGEventFlagMaskShift;
        } else if (key == kVK_CapsLock) {   // Caps Lock
            flags |= kCGEventFlagMaskAlphaShift;
        } else if (key == kVK_Control || key == kVK_RightControl) {   // Control
            flags |= kCGEventFlagMaskControl;
        } else {
            newevent = CGEventCreateKeyboardEvent(source, key, NO);
            CGEventSetFlags(newevent, (myCGEventGetFlags(newevent)) | flags);
            myCGEventPostToPid(targetPid, newevent);
        }
        
        if (i % 8 == 7) {  // 24 バイトになると入力できなくなるようなので、定期的に yield する。
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05f]];
        }
    }
}


static void pressKeys2(CGEventSourceRef source, pid_t targetPid, NSArray *newkey) {
    if (newkey == NULL) {
        return;
    }
    
    CGEventFlags flags = 0;
    
    for (NSObject *k in newkey) {
        if ([k isKindOfClass: [NSNumber class]]) {

            unsigned key = [(NSNumber *)k intValue];

            // 修飾キーはその後に続く１キーのみ有効
            switch (key) {
                case kVK_Shift:
                case kVK_RightShift:
                    flags |= kCGEventFlagMaskShift;
                    continue;
                case kVK_Command:
                case kVK_RightCommand:
                    flags |= kCGEventFlagMaskCommand;
                    continue;
                case kVK_Control:
                case kVK_RightControl:
                    flags |= kCGEventFlagMaskControl;
                    continue;
                case kVK_Option:
                case kVK_RightOption:
                    flags |= kCGEventFlagMaskAlternate;
                    continue;
            }
            
            CGEventRef newevent;
                        
            newevent = CGEventCreateKeyboardEvent(source, key, YES);
            CGEventSetFlags(newevent, (myCGEventGetFlags(newevent) & ~kCGEventFlagMaskShift) | flags);
            myCGEventPostToPid(targetPid, newevent);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001f]];

            newevent = CGEventCreateKeyboardEvent(source, key, NO);
            CGEventSetFlags(newevent, (myCGEventGetFlags(newevent)) | flags);
            myCGEventPostToPid(targetPid, newevent);
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.001f]];

            flags = 0;
            CFRelease(newevent);
            
        } else if ([k isKindOfClass:[NSString class]]) {
            sendUnicode(source, targetPid, (NSString *)k);
            
        } else if ([k isKindOfClass:[ProperAction class]]) {
            NSString *pk = ((ProperAction *)k).keycode;
            for (ViewDataModel *vdm in prefLayout) {
                if ([pk isEqualToString:[vdm getKeycodeString]]) {
                    sendUnicode(source, targetPid, vdm.proper);
                    break;
                }
            }
        }
        
    }
}

static void sendUnicode(CGEventSourceRef source, pid_t targetPid, NSString *str) {
    if (str == nil || [str length] == 0) {
        return;
    }
    
    // 1 - Get the string length in bytes.
    NSUInteger l = [str lengthOfBytesUsingEncoding:NSUTF16StringEncoding];

//    pressKeys2(source, targetPid, @[[NSNumber numberWithInt:kVK_JIS_Eisu]]);
    
//    NSArray* isources = CFBridgingRelease(TISCreateInputSourceList((__bridge CFDictionaryRef)@{ (__bridge NSString*)kTISPropertyInputSourceID : @"com.apple.keylayout.ABC" }, FALSE));
//    TISInputSourceRef isource = (__bridge TISInputSourceRef)isources[0];
//    TISSelectInputSource(isource);
    
//    TISSelectInputSource(TISCopyInputSourceForLanguage(CFSTR("en")));
    
    TISSelectInputSource(TISCopyCurrentASCIICapableKeyboardLayoutInputSource());
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];

    // 2 - Get bytes for unicode characters
    UniChar *uc = malloc(l);
    [str getBytes:uc maxLength:l usedLength:NULL encoding:NSUTF16StringEncoding options:0 range:NSMakeRange(0, l) remainingRange:NULL];

    // 3 - create an empty tap event, and set unicode string
    CGEventRef tap = CGEventCreateKeyboardEvent(source, 0, YES);
    CGEventKeyboardSetUnicodeString(tap, str.length, uc);
    myCGEventPostToPid(targetPid, tap);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];

    pressKeys2(source, targetPid, @[[NSNumber numberWithInt:kVK_JIS_Kana]]);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];

    CFRelease(tap);
    free(uc);
}

//-(void)timerFired:(NSTimer*)timer {
//    [gLock lock];
//    BOOL flag = (gTimer == nil);
//    gTimer = nil;
//    [gLock unlock];
//    if (flag) return;
//
//    unsigned char keycode = gBuff;
//    gBuff = 0xff;
//
//    CGEventSourceRef source;
//    CGEventRef tmp_event = CGEventCreateKeyboardEvent(NULL, 0, YES);
//    source = CGEventCreateSourceFromEvent(tmp_event);
//    CFRelease(tmp_event);
//    CGEventSourceSetKeyboardType(source, gKeyboardType);
//    pid_t targetPid = gTargetPid;
//
//    if (keycode == prefThumbL || keycode == prefThumbR) {
//        unsigned char oya = (keycode == prefThumbL) ? 1 : 2;
//
//        if (prefReturnemu && keycode == prefThumbL) {
//            keycode = (CGKeyCode)kVK_Return;
//        } else if (prefSpaceemu && keycode == prefThumbR) {
//            keycode = (CGKeyCode)kVK_Space;
//        }
//
//        if ((oya & gFirstIgnoredSingleThumbMask) == 0 || (gPressedOya == oya && !gKeyDownAutorepeat)) {
//            gPressedOya = 0;
//            myCGEventPostToPid(targetPid, CGEventCreateKeyboardEvent(source, keycode, YES));
//            myCGEventPostToPid(targetPid, CGEventCreateKeyboardEvent(source, keycode, NO));
//        } else {
//            gPressedOya = oya & gFirstIgnoredSingleThumbMask;
//        }
//
//    } else if (keycode != 0xff) {
//        gPressedOya = 0;
//        NSData *newkey = getKeyDataForOya(keycode, gOya);
//        debugOut(@"[OYA] Keycode=%d, gOya=%d, newKey=%@\n", keycode, gOya, newkey);
//        pressKeys(source, targetPid, newkey, (CGEventFlags)0);
//    }
//    if (!prefCshift) {
//        gOya = 0;
//    }
//
//    if(source != NULL) {
//        CFRelease(source);
//    }
//}

- (void)keyboardInputSourceChanged:(NSNotification *)notification {
    TISInputSourceRef inputSource = TISCopyCurrentKeyboardInputSource();
    if (inputSource) {
        NSString *mode = (__bridge NSString *)TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID);
        gKanaMethod = ((mode && [arKanaMethods containsObject:mode]) ? YES : NO);
        CFRelease(inputSource);
        
        [self updateSbIcon];
    }
}

- (void)updateSbIcon {
    if (!self.propEnabled) {
        debugOut(@"Disabled\n");
        sbItem.button.image = imgDisabled;
    } else if (gKanaMethod) {
        debugOut(@"Japanese\n");
        sbItem.button.image = imgActive;
    } else {
        debugOut(@"Non-Japanese\n");
        sbItem.button.image = imgInactive;
    }
}

@end
