//
//  SRCFeedFetcher.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeedFetcher.h"
#import "RSSAtomKit.h"
#import "SCRDatabaseManager.h"
#import "SCRItem.h"
#import "SCRFeed.h"
#import "SCRMediaItem.h"
#import "YapDatabaseQuery.h"
#import "YapDatabaseSecondaryIndexTransaction.h"

@interface SCRFeedFetcher()
@property (nonatomic, strong) RSSAtomKit *atomKit;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

@end

@implementation SCRFeedFetcher

- (instancetype) init {
    if (self = [super init]) {
        self.callbackQueue = dispatch_queue_create("SCRFeedFetcher callback queue", 0);
        _isRefreshing = NO;
    }
    return self;
}

- (instancetype) initWithReadWriteYapConnection:(YapDatabaseConnection *)connection
                           sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    if (self = [self init]) {
        self.databaseConnection = connection;
        _atomKit = [[RSSAtomKit alloc] initWithSessionConfiguration:sessionConfiguration];
        [self registerRSSAtomKitClasses];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeYapConnections:) name:SCRRemoveYapConnectionsNotification object:[SCRDatabaseManager sharedInstance]];
    }
    return self;
}

- (void) removeYapConnections:(NSNotification*)notification {
    self.databaseConnection = nil;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCRRemoveYapConnectionsNotification object:[SCRDatabaseManager sharedInstance]];
}


- (void)setUrlSessionConfiguration:(NSURLSessionConfiguration *)urlSessionConfiguration
{
    self.atomKit.urlSessionConfiguration = urlSessionConfiguration;
}

- (NSURLSessionConfiguration *)urlSessionConfiguration
{
    return self.atomKit.urlSessionConfiguration;
}

- (void)registerRSSAtomKitClasses
{
    [self.atomKit.parser registerFeedClass:[SCRFeed class]];
    [self.atomKit.parser registerItemClass:[SCRItem class]];
    [self.atomKit.parser registerMediaItemClass:[SCRMediaItem class]];
}

- (BOOL)refreshSubscribedFeedsWithCompletionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(void))completion
{
    // Only allow one refresh operation at a time
    if (self.isRefreshing) {
        return NO;
    }
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(isRefreshing))];
    _isRefreshing = YES;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isRefreshing))];
    
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        dispatch_group_t group = dispatch_group_create();
        NSString *queryString = [NSString stringWithFormat:@"Where %@ = %d",kSCRSubscribedFeedsColumnName,YES];
        YapDatabaseQuery *query = [YapDatabaseQuery queryWithFormat:queryString];
        
        [[transaction ext:kSCRSecondaryIndexExtensionName] enumerateKeysAndObjectsMatchingQuery:query usingBlock:^(NSString *collection, NSString *key, id object, BOOL *stop) {
            
            if ([object isKindOfClass:[SCRFeed class]]) {
                SCRFeed *feed = (SCRFeed *)object;
                dispatch_group_enter(group);
                [self fetchFeedDataFromURL:feed.sourceURL completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSError *error) {
                    dispatch_group_leave(group);
                }];
            }
        }];
        
        dispatch_group_notify(group, completionQueue, ^{
            [self willChangeValueForKey:NSStringFromSelector(@selector(isRefreshing))];
            _isRefreshing = NO;
            [self didChangeValueForKey:NSStringFromSelector(@selector(isRefreshing))];
            if (completion) {
                completion();
            }
        });
    }];
    
    return YES;
}

/**
 *  Fetches RSS feed info and items and inserts it into the database.
 *
 *  @param url rss feed url
 */

//Instead pass whole SRCFeed item to check if things have change URL and yap key wise that database needs to be modified
//maybe unsubscribe old one so old content is still around
- (void) fetchFeedDataFromURL:(NSURL*)url completionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(NSError *))completion {
    
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    NSAssert(url != nil, @"url cannot be nil!");
    if (!url) {
        dispatch_async(completionQueue, ^{
            completion([NSError errorWithDomain:@"securereader.feedfetcher" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}]);
        });
        return;
    }
    
    [self.networkOperationQueue addOperationWithBlock:^{
        
        [self.atomKit parseFeedFromURL:url completionBlock:^(RSSFeed *feed, NSArray *items, NSError *error) {
            NSLog(@"Parsed feed %@ with %lu items", feed.title, (unsigned long)items.count);
            if (error) {
                if (completion) {
                    dispatch_async(completionQueue, ^{
                        completion(error);
                    });
                }
                return;
            }
            
            if ([feed isKindOfClass:[SCRFeed class]]) {
                SCRFeed *nativeFeed = (SCRFeed*)feed;
                [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    ////// Feed Storage //////
                    SCRFeed *existingFeed = [transaction objectForKey:nativeFeed.yapKey inCollection:[[nativeFeed class] yapCollection]];
                    if (existingFeed) {
                        nativeFeed.subscribed = existingFeed.subscribed;
                    }
                    [transaction setObject:nativeFeed forKey:nativeFeed.yapKey inCollection:[[nativeFeed class] yapCollection]];
                    
                    ////// Items Storage //////
                    [items enumerateObjectsUsingBlock:^(RSSItem *item, NSUInteger idx, BOOL *stop) {
                        if ([item isKindOfClass:[SCRItem class]]) {
                            SCRItem *nativeItem = (SCRItem*)item;
                            SCRItem *existingItem = [transaction objectForKey:nativeItem.yapKey inCollection:[[nativeItem class] yapCollection]];
                            id itemMetaData = [transaction metadataForKey:nativeItem.yapKey inCollection:[[nativeItem class] yapCollection]];
                            if (!itemMetaData) {
                                itemMetaData = [NSDate date];
                            }
                            if (existingItem) {
                                nativeItem.isFavorite = existingItem.isFavorite;
                                nativeItem.isReceived = existingItem.isReceived;
                            }
                            nativeItem.feedYapKey = nativeFeed.yapKey;
                            
                            ////// Media Items storage //////
                            if ([nativeItem.mediaItems count]) {
                                NSMutableArray *mediaItemKeysArray = [NSMutableArray arrayWithCapacity:[nativeItem.mediaItems count]];
                                for (SCRMediaItem *mediaItem in nativeItem.mediaItems) {
                                    SCRMediaItem *existingMediaItem =[transaction objectForKey:mediaItem.yapKey inCollection:[SCRMediaItem yapCollection]];
                                    if (!existingMediaItem) {
                                        [transaction setObject:mediaItem forKey:mediaItem.yapKey inCollection:[SCRMediaItem yapCollection]];
                                    }
                                    [mediaItemKeysArray addObject:mediaItem.yapKey];
                                }
                                nativeItem.mediaItemsYapKeys = mediaItemKeysArray;
                            }
                            
                            
                            [transaction setObject:nativeItem forKey:nativeItem.yapKey inCollection:[[nativeItem class] yapCollection] withMetadata:itemMetaData]   ;
                        }
                    }];
                } completionBlock:^{
                    if (completion) {
                        dispatch_async(completionQueue, ^{
                            completion(nil);
                        });
                    }
                }];
            }
        } completionQueue:self.callbackQueue];
    }];
    
}

- (void) fetchFeedsFromOPMLURL:(NSURL *)url completionBlock:(void (^)(NSArray *, NSError *))completionBlock completionQueue:(dispatch_queue_t)completionQueue{
    [self.atomKit parseFeedsFromOPMLURL:url completionBlock:completionBlock completionQueue:completionQueue];
}


@end
