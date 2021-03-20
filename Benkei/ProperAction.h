//
//  ProperAction.h
//  Benkei
//
//  Created by Yuki Sakamoto on 2021/03/20.
//  Copyright © 2021 eawai. All rights reserved.
//

#ifndef ProperAction_h
#define ProperAction_h

@interface ProperAction : NSObject

- (instancetype)initWith: (NSString *)keycode;

@property NSString *keycode;

@end
#endif /* ProperAction_h */
