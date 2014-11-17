//
//  SRCFeedFetcher.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeedFetcher.h"
#import "MWFeedParser.h"
#import "SCRDatabaseManager.h"
#import "SCRItem.h"

@interface SCRFeedFetcher() <MWFeedParserDelegate>
@property (atomic, strong, readonly) NSMutableSet *parsers;
@end

@implementation SCRFeedFetcher

- (instancetype) init {
    if (self = [super init]) {
        _parsers = [NSMutableSet set];
    }
    return self;
}

/**
 *  Fetches RSS feed info and items and inserts it into the database.
 *
 *  @param url rss feed url
 */
- (void) fetchFeedDataFromURL:(NSURL*)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // We will need to modify MWFeedParser to use NSURLSession and Tor SOCKS proxy
        MWFeedParser *parser = [[MWFeedParser alloc] initWithFeedURL:url];
        parser.delegate = self;

        [parser parse];
    });
}

#pragma mark MWFeedParserDelegate methods

- (void)feedParserDidStart:(MWFeedParser *)parser {
    NSLog(@"feedParserDidStart %@", parser);
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info {
    NSLog(@"parser %@ didParseFeedInfo %@", parser, info);
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    NSLog(@"parser %@ didParseFeedItem %@", parser, item);
    SCRItem *appItem = [[SCRItem alloc] initWithFeedItem:item];
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:appItem forKey:appItem.yapKey inCollection:[[appItem class] yapCollection]];
    }];
}

- (void)feedParserDidFinish:(MWFeedParser *)parser {
    [self.parsers removeObject:parser];
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error {
    NSLog(@"parser %@ didFailWithError: %@", parser, error);
    [self.parsers removeObject:parser];
}


@end
