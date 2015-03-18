//
//  SCRFeed.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/24/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "RSSFeed.h"
#import "SCRYapObject.h"

@class SCRItem, YapDatabaseReadTransaction, IOCipher;

@interface SCRFeed : RSSFeed <SCRYapObject>

@property (nonatomic) BOOL subscribed;
@property (nonatomic) BOOL userAdded;

- (void)enumerateItemsInTransaction:(YapDatabaseReadTransaction *)readTransaction block:(void (^)(SCRItem *item, BOOL *stop))block;

+ (void)removeFeed:(SCRFeed *)feed inTransaction:(YapDatabaseReadWriteTransaction *)transaction storage:(IOCipher *)storage;

@end
