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

int ng_chrcount = 0;
int keycomb = 0;

NSMutableArray *ngbuf;
NSDictionary *ng_key;
NSDictionary *ng_keymap;

- (instancetype)init
{
    self = [super init];
    if (self) {
        ngbuf = [NSMutableArray new];
        
        ng_key = [NSDictionary dictionaryWithObjectsAndKeys:
            @B_Q, [NSNumber numberWithInt:kVK_ANSI_Q],
            [NSNumber numberWithInt:B_W], [NSNumber numberWithInt:kVK_ANSI_W],
            [NSNumber numberWithInt:B_E], [NSNumber numberWithInt:kVK_ANSI_E],
            [NSNumber numberWithInt:B_R], [NSNumber numberWithInt:kVK_ANSI_R],
            [NSNumber numberWithInt:B_T], [NSNumber numberWithInt:kVK_ANSI_T],
        nil];

        ng_keymap = [NSDictionary dictionaryWithObjectsAndKeys:
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_K], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSNumber numberWithInt:B_W],
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_T], [NSNumber numberWithInt:kVK_ANSI_E], nil], [NSNumber numberWithInt:B_E],
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_S], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSNumber numberWithInt:B_R],
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_DownArrow], nil], [NSNumber numberWithInt:B_T],
                     [NSArray arrayWithObjects: [NSNumber numberWithInt:kVK_ANSI_X], [NSNumber numberWithInt:kVK_ANSI_I], nil], [NSNumber numberWithInt:B_Q | B_W],
        nil];
    }
    return self;
}

-(NSArray *)pressKey:(CGKeyCode)keycode
{
    [ngbuf addObject: [NSNumber numberWithInt: keycode]];
    id bkey = [ng_key objectForKey: [NSNumber numberWithInt:keycode]];
    int c = [(NSNumber *)bkey intValue];
    keycomb |= c;
    return NULL;
}

-(NSArray *)releaseKey:(CGKeyCode)keycode
{
    return (NSArray *)[ng_keymap objectForKey:[NSNumber numberWithInt:keycomb]];
}

@end
