//
//  SCRNetworkFeetcher.h
//  SecureReader
//
//  Created by David Chiles on 4/3/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCRNetworkFetcher : NSObject

/**
 This is an operation queue that all network requests should be passed on. The purpose opf this queue 
 is to allow network operations to be paused while Tor is starting up and resumed once completed. 
 It is not up to this class to choose the correct proxy settings for the NSURLSession data tasks.
 
 */
@property (nonatomic, strong, readonly) NSOperationQueue *networkOperationQueue;

/**
 This is the url session that will be used for network requests. This must be set in the init method or
 otherwise before netweork requests.
 
 */
@property (nonatomic, strong) NSURLSessionConfiguration *urlSessionConfiguration;

- (void)downloadDataFor:(NSURL *)url
        completionQueue:(dispatch_queue_t)completionQueue
        completionBlock:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionBlock;

@end
