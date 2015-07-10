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

- (instancetype) init {
    if (self = [self initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]]) {
    }
    return self;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    if (self = [super init]) {
        if (sessionConfiguration) {
            _urlSessionConfiguration = sessionConfiguration;
        } else {
            _urlSessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        }
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

- (void)downloadDataFor:(NSURL *)url completionQueue:(dispatch_queue_t)completionQueue completionBlock:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionBlock
{
    if (!completionBlock || ![url.absoluteString length]) {
        return;
    }
    
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    __weak typeof(self)weakSelf = self;
    [self.networkOperationQueue addOperationWithBlock:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:strongSelf.urlSessionConfiguration];
        NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(completionQueue, ^{
                completionBlock(data,response,error);
            });
        }];
        [dataTask resume];
    }];
    
    
}

@end
