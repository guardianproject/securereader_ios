//
//  SCRFeedFetcher.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRNetworkFetcher.h"

@class YapDatabaseConnection, RSSParser;

@interface SCRFeedFetcher : SCRNetworkFetcher

/** Whether there is a refresh ongoing is KVO compliant */
@property (nonatomic, readonly) BOOL isRefreshing;

- (instancetype)initWithReadWriteYapConnection:(YapDatabaseConnection *)connection
                          sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

/**
 * Asynchronously goes through all subscribed feeds in the database and uses fetchFeedDataFromURL:completionQueue:completion
 * and the feeds xmlURL to update the feed items and inserts them into the datatbase. Once all the susbcribed feeeds have updated
 * the completion block is called
 *
 * @param completionQueue the queue the completion block with be called on (defaults to the main queue)
 * @param completion teh completion block will be called once all feeds have been updated
 *
 * @return Returns whether a refresh is started. Only one refresh is allowed at a time so if isRefreshing is YES then this will return NO
 *          and the completion block will not be called at all.
 */

- (BOOL)refreshSubscribedFeedsWithCompletionQueue:(dispatch_queue_t)completionQueue
                                       completion:(void (^)(void))completion;

/**
 *  Fetches RSS feed info and items and inserts it into the database.
 *
 *  @param url rss feed url
 */
- (void) fetchFeedDataFromURL:(NSURL*)url completionQueue:(dispatch_queue_t)completionQueue
                   completion:(void (^)(NSError *error))completion;


/**
 *  Wraps RSSAtomKit to use network and class defaults
 *
 *  @param url OPML document url
 *  @param completionBlock The result with an array of SCRFeed(s)
 *  @param completionQuee The queue to callback on if nil uses main queue
 *
 */

- (void) fetchFeedsFromOPMLURL:(NSURL *)url
               completionBlock:(void (^)(NSArray *feeds, NSError *error))completionBlock
               completionQueue:(dispatch_queue_t)completionQueue;

+ (RSSParser *)defaultParser;

@end
