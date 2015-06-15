//
//  Item.h
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mantle.h"
#import "SCRYapObject.h"
#import "RSSItem.h"
#import "YapDatabaseRelationshipNode.h"

@import UIKit;

@class YapDatabaseReadTransaction, SCRMediaItem, IOCipher;

extern NSString *const kSCRMediaItemEdgeName;
extern NSString *const kSCRFeedEdgeName;

@interface SCRItem : RSSItem <SCRYapObject, YapDatabaseRelationshipNode>

/** yapKay for the parent SCRFeed */
@property (nonatomic, strong) NSString *feedYapKey;

@property (nonatomic) BOOL isFavorite;
@property (nonatomic) BOOL isReceived;

@property (nonatomic, strong) NSArray *mediaItemsYapKeys;

- (NSString *)pathForDownloadedHTML;

// TEMP - replace with real property!
- (NSArray *)tags;

- (void)removeMediaItemsWithReadWriteTransaction:(YapDatabaseReadWriteTransaction *)transaction storage:(IOCipher *)storage;

- (void)enumerateMediaItemsInTransaction:(YapDatabaseReadTransaction *)readTransaction block:(void (^)(SCRMediaItem *mediaItem,BOOL *stop))block;

/**
 Removes SCRItems in the database and their media items where the the data in the yap metadata field is older than a date.
 
 @param date The date to compare the items metadata date object to.
 @param includingFavorites Set to YES and favorites will be deleted as well
 @param transaction The transaction to perfrom all database actions with
 @param storage The encrypted storage where the media items are stored
 */
+ (void)removeItemsOlderThan:(NSDate *)date includeFavorites:(BOOL)includingFavorites withReadWriteTransaction:(YapDatabaseReadWriteTransaction *)transaction storage:(IOCipher *)storage;

@end
