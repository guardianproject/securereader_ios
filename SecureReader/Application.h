//
//  Application.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kApplicationTimeoutInSeconds 5
#define kApplicationDidTimeoutNotification @"AppTimeOut"

@interface Application : UIApplication

- (void)startLockTimer;

@end
