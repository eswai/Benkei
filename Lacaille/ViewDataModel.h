//
//  ViewDataModel.h
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

#import <Foundation/Foundation.h>
#import "KeyTransformer.h"

@interface ViewDataModel : NSObject

@property NSInteger keycode;
@property NSData* center;
@property NSData* left;
@property NSData* right;
@property NSData* outer;
@property NSData* ascii;
@property NSData* shift;
@property NSData* modifier;

-(NSString*)getKeycodeString;
-(NSData*)getKeyData:(unsigned char)gOya;

@end
