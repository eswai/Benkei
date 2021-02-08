//
//  Naginata.m
//  Lacaille
//
//  Created by Yuki Sakamoto on 2021/02/07.
//  Copyright © 2021 kkadowaki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Naginata.h"
#import <Carbon/Carbon.h>

@implementation Naginata

NSMutableArray *ngbuf;
NSDictionary *ng_keymap;
NSMutableSet * keyset;

- (instancetype)init
{
    self = [super init];
    if (self) {
        ngbuf = [NSMutableArray new];
        keyset = [NSMutableSet new];

        ng_keymap = [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_I], nil],
                     [NSSet setWithObjects:[NSNumber numberWithInt:kVK_ANSI_W], nil],
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_E], nil],
                     [NSSet setWithObjects:[NSNumber numberWithInt:kVK_ANSI_E], nil],
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_I], nil],
                     [NSSet setWithObjects:[NSNumber numberWithInt:kVK_ANSI_R], nil],
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_DownArrow], nil],
                     [NSSet setWithObjects:[NSNumber numberWithInt:kVK_ANSI_T], nil],
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil],
                     [NSSet setWithObjects:[NSNumber numberWithInt:kVK_ANSI_Q], [NSNumber numberWithInt:kVK_ANSI_W], nil],
        nil];
    }
    return self;
}

-(NSArray *)pressKey:(CGKeyCode)keycode
{
    [ngbuf addObject: [NSNumber numberWithInt: keycode]];
    [keyset addObject: [NSNumber numberWithInt: keycode]];
    return NULL;
}

-(NSArray *)releaseKey:(CGKeyCode)keycode
{
    NSArray *kana = (NSArray *)[ng_keymap objectForKey:keyset];
    [keyset removeAllObjects];
    return kana;
}

@end
