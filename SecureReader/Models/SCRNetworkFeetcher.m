//
//  SCRNetworkFeetcher.m
//  SecureReader
//
//  Created by David Chiles on 4/3/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRNetworkFeetcher.h"
#import "CPAProxy.h"

@implementation SCRNetworkFeetcher

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        _networkOperationQueue = [[NSOperationQueue alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torNotificationReceived:) name:CPAProxyDidStartSetupNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torNotificationReceived:) name:CPAProxyDidFinishSetupNotification object:nil];
    }
    return self;
}

- (void)torNotificationReceived:(NSNotification *)notification
{
    if ([notification.name isEqualToString:CPAProxyDidStartSetupNotification] ) {
        self.networkOperationQueue.suspended = YES;
    } else if ([notification.name isEqualToString:CPAProxyDidFinishSetupNotification]) {
        self.networkOperationQueue.suspended = NO;
    }
}

@end
