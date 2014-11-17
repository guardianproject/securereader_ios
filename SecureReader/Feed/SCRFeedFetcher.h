//
//  SCRFeedFetcher.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCRFeedFetcher : NSObject

/**
 *  Fetches RSS feed info and items and inserts it into the database.
 *
 *  @param url rss feed url
 */
- (void) fetchFeedDataFromURL:(NSURL*)url;

@end
