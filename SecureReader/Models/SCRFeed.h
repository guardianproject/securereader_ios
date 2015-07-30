//
//  SCRFeed.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/24/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "RSSFeed.h"
#import "SCRYapObject.h"

@import UIKit;
@class SCRItem, YapDatabaseReadTransaction, IOCipher;

typedef NS_ENUM(NSUInteger, SCRFeedViewPreference) {
    SCRFeedViewPreferenceRSS = 0,
    SCRFeedViewPreferenceReadability = 1
};

@interface SCRFeed : RSSFeed <SCRYapObject>

@property (nonatomic) BOOL subscribed;
@property (nonatomic) BOOL userAdded;
@property (nonatomic, strong) UIImage *feedImage;
@property (nonatomic, strong) NSDate *lastFetchedFeedImageDate;
@property (nonatomic) SCRFeedViewPreference viewPreference;

- (void)enumerateItemsInTransaction:(YapDatabaseReadTransaction *)readTransaction block:(void (^)(SCRItem *item, BOOL *stop))block;

+ (void)removeFeed:(SCRFeed *)feed inTransaction:(YapDatabaseReadWriteTransaction *)transaction storage:(IOCipher *)storage;

@end
