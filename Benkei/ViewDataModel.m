//
//  ViewDataModel.m
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

#import "ViewDataModel.h"

@implementation ViewDataModel

-(NSString*)getKeycodeString {
    return keyCodeToString([[NSData alloc] initWithBytes:(unsigned char[]){self.keycode} length:1]);
    // return [NSString stringWithFormat:@"%@", self.keycode];
}
-(NSString*)getCenter {
    return keyCodeToString(self.center);
}
-(NSString*)getLeft {
    return keyCodeToString(self.left);
}
-(NSString*)getRight {
    return keyCodeToString(self.right);
}
-(NSString*)getOuter {
    return keyCodeToString(self.outer);
}
-(NSString*)getAscii {
    return keyCodeToString(self.ascii);
}
-(NSString*)getShift {
    return keyCodeToString(self.shift);
}
-(NSString*)getModifier {
    return keyCodeToString(self.modifier);
}
-(NSData*)getKeyData:(unsigned char)gOya {
    switch(gOya) {
        case 0:
            return self.center;
        case 1:
            return self.left;
        case 2:
            return self.right;
        case 3:
            return self.outer;
        case 4:
            return self.ascii;
        case 5:
            return self.shift;
        case 6:
            return self.modifier;
    }
    return [NSData data];
}

@end
