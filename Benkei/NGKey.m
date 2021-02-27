//
//  NGKey.m
//  Benkei
//
//  Created by Yuki Sakamoto on 2021/02/26.
//  Copyright © 2021 eawai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NGKey.h"
#import <Carbon/Carbon.h>

@implementation NGKey

- (instancetype)initWithKeycode: (CGKeyCode)keycode
{
    self = [super init];
    if (self) {
        self.isConverted = false;
        self.isShiftKey = false;
        self.pressTime = [NSDate new];
        self.keycode = keycode;
    }
    return self;
}

@end
