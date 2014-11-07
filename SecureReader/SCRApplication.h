//
//  Application.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kApplicationDidTimeoutNotification @"AppTimeOut"

@interface SCRApplication : UIApplication

+ (SCRApplication*) sharedApplication;

-(void)lockApplication;
-(void)lockApplicationDelayed;
- (void)startLockTimer;

@end
