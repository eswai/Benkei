//
//  KeyTransformer.m
//  Lacaille
//
//  Created by kkadowaki on 2014.04.26.
//  Copyright (c) 2014-2016 kkadowaki. All rights reserved.
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

#import "KeyTransformer.h"

@implementation KeyTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if (value == nil) return nil;
    if ([value isKindOfClass:[NSNumber class]]) {
        return keyCodeToString([[NSData alloc] initWithBytes:(unsigned char[]){[value intValue]} length:1]);
    }
    return keyCodeToString((NSData *)value);
}

- (id)reverseTransformedValue:(id)value
{
    return nil;
}

static BOOL initialized = NO;
static NSString* keymap[0x80] = {
    @"a", @"s", @"d", @"f", @"h", @"g", @"z", @"x",
    @"c", @"v", @"[Section]", @"b", @"q", @"w", @"e", @"r",
    @"y", @"t", @"1", @"2", @"3", @"4", @"6", @"5",
    @"^"/* = */, @"9", @"7", @"-", @"8", @"0", @"["/* ] */, @"o",
    @"u", @"@"/* [ */, @"i", @"p", @"↩", @"l", @"j", @":"/* ' */,
    @"k", @";", @"]"/* \ */, @",", @"/", @"n", @"m", @".",
    @"⇥", @"␣", @"`", @"⌫", @"⌤"/* no def */, @"⎋", @"[R⌘]", @"⌘",
    @"⇧", @"⇪", @"⌥", @"⌃", @"[R⇧]", @"[R⌥]", @"[R⌃]", @"[fn]",
    @"[F17]", @"[K.]", @"<42>", @"[K*]", @"<44>", @"[K+]", @"<46>", @"⌧"/* Keypad */,
    @"[VolumeUp]", @"[VolumeDown]", @"[Mute]", @"[K/]", @"[K⌤]", @"<4d>", @"[K-]", @"[F18]",
    @"[F19]", @"[K=]", @"[K0]", @"[K1]", @"[K2]", @"[K3]", @"[K4]", @"[K5]",
    @"[K6]", @"[K7]", @"[F20]", @"[K8]", @"[K9]", @"¥", @"_", @"[K,]",
    @"[F5]", @"[F6]", @"[F7]", @"[F3]", @"[F8]", @"[F9]", @"[Eisu]", @"[F11]",
    @"[Kana]", @"[F13]", @"[F16]", @"[F14]", @"<6c>", @"[F10]", @"<6e>", @"[F12]",
    @"<70>", @"[F15]", @"[Help]", @"↖", @"⇞", @"⌦", @"[F4]", @"↘",
    @"[F2]", @"⇟", @"[F1]", @"←", @"→", @"↓", @"↑", @"<7f>",
};

NSString *keyCodeToString(NSData* keycode) {
    if (!initialized) {
        keymap[kVK_JIS_Eisu] = NSLocalizedString(@"key_eisu", nil);     // 英数、無変換
        keymap[kVK_JIS_Kana] = NSLocalizedString(@"key_kana", nil);     // かな、変換
        initialized = YES;
    }
    
    TISInputSourceRef currentKeyboard = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
    CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
    NSMutableString *str = [NSMutableString stringWithCapacity: 8];
    
    const void *in_ptr = keycode.bytes;
    for (int i = 0; i < keycode.length; i++) {
        unsigned key = *(unsigned char *)(in_ptr++) & 0xff;
        
        if (key == 0xff) {  // reset modifier key
            if (i < keycode.length - 1)
                [str appendFormat:@"  "];
            continue;
        }
        
        UniCharCount actualStringLength = 0;
        if (layoutData != NULL) {
            UInt32 deadKeyState = 0;
            UniChar chars[4];
            UCKeyTranslate((const UCKeyboardLayout *)CFDataGetBytePtr(layoutData), key, kUCKeyActionDisplay,
                           0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState,
                           sizeof(chars) / sizeof(chars[0]), &actualStringLength, chars);
            if (actualStringLength == 1 && ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:chars[0]]
                                            || [[NSCharacterSet controlCharacterSet] characterIsMember:chars[0]]))
                actualStringLength = 0;
            [str appendString:(__bridge NSString*)CFStringCreateWithCharacters(kCFAllocatorDefault, chars, actualStringLength)];
        }
        if (actualStringLength == 0) {
            if (key < sizeof(keymap) / sizeof(keymap[0])) {
                [str appendString: keymap[key]];
            } else {
                [str appendFormat:@"<%02x>", key];
            }
        }
    }
    CFRelease(currentKeyboard);
    return str;
}

@end
