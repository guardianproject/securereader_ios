//
//  SCRTorManager.h
//  SecureReader
//
//  Created by David Chiles on 4/2/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPAProxy.h"

extern NSString *const kSCRTorManagerNetworkStatusNotification;
extern NSString *const kSCRTorManagerBootstrapProgressSummaryKey;
extern NSString *const kSCRTorManagerBootstrapProgressNotification;

extern NSString *const kSCRTorManagerBootstrapProgressKey;

/** Will be included in notification userinfo if the network operations need to be paused or resumes */
extern NSString *const kSCRTorManagerNetworkPauseKey;

/** Will be included in notification userinfo ifi the session configuration has changed*/
extern NSString *const KSCRTorManagerURLSessionConfigurationKey;


@interface SCRTorManager : NSObject

/**
 The proxy manager that will automatically start connecting to tor with the tor setting is changed to YES.
 kSCRTorManagerNetworkStatusNotification notification is sent when tor is started and when tor is started
 and completed connecting. kSCRTorManagerNetworkStatusNotification is also sent when the tor setting is sent to NO;
 */

@property (nonatomic, strong, readonly) CPAProxyManager *proxyManager;

/**
 The current configuration based on the tor setting
 */
- (NSURLSessionConfiguration *)currentConfiguration;

/**
 This method querires tor by sending a commond over the tor control port
 
 @param resultBlock the result returned by tor
 @param queue the queue that the resultBlock should be called on. Defaults to main
 */
- (void)currentBootstrapProgress:(void (^)(NSInteger progress, NSString *summary))resultBlock
                           queue:(dispatch_queue_t)queue;

@end
