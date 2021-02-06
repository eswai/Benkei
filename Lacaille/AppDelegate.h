//
//  AppDelegate.h
//  Lacaille
//
//  Created by kkadowaki on 2014.04.26.
//  Copyright (c) 2014-2018 kkadowaki. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <Quartz/Quartz.h>
#include <unistd.h>
#include <string.h>
#import "ViewDataModel.h"

// from ApplicationServices.framework/HIServices.framework/AXUIElement.h
extern Boolean AXIsProcessTrustedWithOptions(CFDictionaryRef options) __attribute__((weak_import));
extern CFStringRef kAXTrustedCheckOptionPrompt __attribute__((weak_import));

// from CoreGraphics.framework/CGEvent.h
extern void CGEventPostToPid(pid_t pid, CGEventRef event) __attribute__((weak_import));

#define kVK_RightCommand 0x36

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
- (IBAction)loadLayout:(id)sender;
- (IBAction)selectThumbL:(id)sender;
- (IBAction)selectThumbR:(id)sender;

@property (assign) IBOutlet NSButton *normalRadioButtonForSingleThumbL;
@property (assign) IBOutlet NSButton *firstIgnoranceRadioButtonForSingleThumbL;
@property (assign) IBOutlet NSButton *returnemuRadioButtonForSingleThumbL;
- (IBAction)radioSingleThumbL:(id)sender;

@property (assign) IBOutlet NSButton *normalRadioButtonForSingleThumbR;
@property (assign) IBOutlet NSButton *firstIgnoranceRadioButtonForSingleThumbR;
@property (assign) IBOutlet NSButton *spaceemuRadioButtonForSingleThumbR;
- (IBAction)radioSingleThumbR:(id)sender;

@property (assign) IBOutlet NSTabView *tabView;
@property (assign) IBOutlet NSTextField *versionBox;
@property (assign) IBOutlet NSTextView *aboutBox;
@property (assign) IBOutlet NSTextField *copyrightBox;
@property (assign) IBOutlet NSTableView *tableView;

@property (assign) IBOutlet NSPanel *oyaSheet;
- (IBAction)oyaCancel:(id)sender;
@property (assign) IBOutlet NSTextField *oyaLabel;

@property (assign) IBOutlet NSPanel *keySheet;
- (IBAction)keyOK:(id)sender;
- (IBAction)keyCancel:(id)sender;
@property (assign) IBOutlet NSTextField *keyLabel1;
@property (assign) IBOutlet NSTextField *keyLabel2;

@property (assign) IBOutlet NSMenu *sbMenu;
- (IBAction)showPreferences:(id)sender;

@property (nonatomic, assign) BOOL startAtLogin;
@property (nonatomic, assign) NSArray* propLayout;
@property (nonatomic, assign) BOOL propEnabled;
@property (nonatomic, assign) BOOL propCshift;
@property (nonatomic, assign) BOOL propFirstIgnoredSingleThumbL;
@property (nonatomic, assign) BOOL propFirstIgnoredSingleThumbR;
@property (nonatomic, assign) BOOL propReturnemu;
@property (nonatomic, assign) BOOL propSpaceemu;
@property (nonatomic, assign) CGKeyCode propThumbL;
@property (nonatomic, assign) CGKeyCode propThumbR;
@property (nonatomic, assign) NSTimeInterval propTwait;

@end
