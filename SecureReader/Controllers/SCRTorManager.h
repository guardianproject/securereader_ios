//
//  SCRTorManager.h
//  SecureReader
//
//  Created by David Chiles on 4/2/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPAProxy.h"

extern NSString *const kSCRTorManagerTorStatusNotification;

@interface SCRTorManager : NSObject

@property (nonatomic, strong, readonly) CPAProxyManager *proxyManager;

- (NSURLSessionConfiguration *)currentConfiguration;

@end
