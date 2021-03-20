//
//  ProperAction.m
//  Benkei
//
//  Created by Yuki Sakamoto on 2021/03/20.
//  Copyright © 2021 eawai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProperAction.h"

@implementation ProperAction

- (instancetype)initWith: (NSString *)keycode
{
    self = [super init];
    if (self) {
        self.keycode = keycode;
    }
    return self;
}

@end
