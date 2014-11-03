//
//  Application.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "Application.h"

@implementation Application
{
    NSTimer     *idleLockTimer;
}

- (void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];
    [self startLockTimer];
}

-(void)idleTimerExpired
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationDidTimeoutNotification object:nil];
}

-(void)startLockTimer
{
    if (idleLockTimer == nil || ![idleLockTimer isValid])
    {
        idleLockTimer = [NSTimer scheduledTimerWithTimeInterval:kApplicationTimeoutInSeconds target:self selector:@selector(idleTimerExpired) userInfo:nil repeats:NO];
    }
    else
    {
        [idleLockTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:kApplicationTimeoutInSeconds]];
    }
}

@end
