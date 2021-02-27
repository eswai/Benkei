//
//  NGKey.h
//  Benkei
//
//  Created by Yuki Sakamoto on 2021/02/26.
//  Copyright © 2021 eawai. All rights reserved.
//

#ifndef NGKey_h
#define NGKey_h

@interface NGKey : NSObject

- (instancetype)initWithKeycode: (CGKeyCode)keycode;

@property CGKeyCode keycode;
@property NSDate *pressTime;
@property NSDate *releaseTime;
@property bool isConverted;
@property bool isShiftKey;

@end

#endif /* NGKey_h */
