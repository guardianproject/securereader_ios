//
//  Application.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRApplication.h"
#import "SCRSettings.h"

@implementation SCRApplication
{
    NSTimer     *idleLockTimer;
}

+ (SCRApplication*) sharedApplication
{
    return (SCRApplication*)[UIApplication sharedApplication];
}

- (void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];
    [self startLockTimer];
}

-(void)lockApplication
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationDidTimeoutNotification object:nil];
}

-(void)lockApplicationDelayed
{
    NSInteger timeout = [SCRSettings lockTimeout];
    if (timeout == 0)
    {
        [self lockApplication];
    }
    else
    {
        [self startLockTimer];
    }
}

-(void)startLockTimer
{
    NSInteger timeout = [SCRSettings lockTimeout];
    if (timeout != 0)
    {
        if (idleLockTimer == nil || ![idleLockTimer isValid])
        {
            idleLockTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(lockApplication) userInfo:nil repeats:NO];
        }
        else
        {
            [idleLockTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
        }
    }
}

@end
