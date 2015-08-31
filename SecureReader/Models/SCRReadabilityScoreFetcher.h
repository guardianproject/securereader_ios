//
//  SCRReadabilityScoreFetcher.h
//  SecureReader
//
//  Created by David Chiles on 8/31/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRNetworkFetcher.h"

@interface SCRReadabilityScoreFetcher : SCRNetworkFetcher

/**
 This fetches a readability score from the server
 
 @param url the url of the feed to check. This should be a RSS/Atom feed
 @param language this is the preferred language to use. Default is en_US
 @param completionQueue the queue to callback on. Default is main queue
 @param completionBlock the block that will be called when finished. Errors can be from the server when the result of the feed cannot be parsed correctly.
 @return
 */
- (void)fetchScoreForURL:(NSURL *)url
                language:(NSString *)language
         completionQueue:(dispatch_queue_t)completionQueue
         completionBlock:(void (^)(NSNumber *score,NSError *error))completionBlock;

@end
