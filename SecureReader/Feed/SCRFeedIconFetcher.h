//
//  SCRFeedIconFetcher.h
//  SecureReader
//
//  Created by David Chiles on 5/18/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRNetworkFetcher.h"

@import UIKit;

@interface SCRFeedIconFetcher : SCRNetworkFetcher

- (instancetype) initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

- (void)fetchIconForURL:(NSURL *)url
        completionQueue:(dispatch_queue_t)queue
             completion:(void (^)(UIImage *image, NSError *error))completion;

@end
