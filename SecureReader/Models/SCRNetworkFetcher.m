//
//  SCRNetworkFeetcher.m
//  SecureReader
//
//  Created by David Chiles on 4/3/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRNetworkFetcher.h"
#import "SCRTorManager.h"

@implementation SCRNetworkFetcher

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        _networkOperationQueue = [[NSOperationQueue alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkNotificationReceived:)
                                                     name:kSCRTorManagerNetworkStatusNotification
                                                   object:nil];
    }
    return self;
}

- (void)networkNotificationReceived:(NSNotification *)notification
{
    NSURLSessionConfiguration *configuration = notification.userInfo[KSCRTorManagerURLSessionConfigurationKey];
    if (configuration) {
        self.urlSessionConfiguration = configuration;
    }
    
    NSNumber *paused = notification.userInfo[kSCRTorManagerNetworkPauseKey];
    
    if (paused) {
        self.networkOperationQueue.suspended = [paused boolValue];
    }
}

@end
