//
//  SCRReader.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-19.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRReader.h"
#import "SCRDatabaseManager.h"
#import "SCRFeedFetcher.h"

@implementation SCRReader

#pragma mark Singleton Methods

+ (id)sharedInstance {
    static SCRReader *sharedReader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedReader = [[self alloc] init];
    });
    return sharedReader;
}

- (id)init {
    if (self = [super init]) {
    }
    return self;
}

-(void) removeFeed:(SCRFeed *)feed
{
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:feed.yapKey inCollection:[[feed class] yapCollection]];
    }];
}

-(void) setFeed:(SCRFeed *)feed subscribed:(BOOL)subscribed
{
    [feed setSubscribed:subscribed];
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [feed saveWithTransaction:transaction];

        // TODO - When subscribing, we need to download the feed!
        if (subscribed)
        {
            SCRFeedFetcher *fetcher = [[SCRFeedFetcher alloc] init];
            if (feed.xmlURL != nil)
                [fetcher fetchFeedDataFromURL:[feed xmlURL] completionQueue:nil completion:nil];
            else
                [fetcher fetchFeedDataFromURL:[feed htmlURL] completionQueue:nil completion:nil];
        }
    }];
}

-(void) markItem:(SCRItem *)item asFavorite:(BOOL)favorite
{
    [item setIsFavorite:favorite];
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [item saveWithTransaction:transaction];
    }];
}

@end
