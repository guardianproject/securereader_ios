//
//  SCRMediaItem.h
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "RSSMediaItem.h"
#import "SCRYapObject.h"

@class SCRItem, YapDatabaseReadTransaction;

typedef NS_ENUM(NSUInteger, SCRMediaItemStatus) {
    SCRMediaItemStatusNotDownloaded = 0,
    SCRMediaItemStatusDownloading   = 1,
    SCRMediaItemStatusDownloaded    = 2
};

@interface SCRMediaItem : RSSMediaItem <SCRYapObject>

@property (nonatomic) SCRMediaItemStatus dataStatus;

/** Local path for used in IOCipher */
- (NSString *)localPath;

/** Local URL to be used with SCRMediaServer */
- (NSURL *)localURLWithPort:(NSUInteger)port;

- (void)enumerateItemsInTransaction:(YapDatabaseReadTransaction *)readTransaction block:(void (^)(SCRItem *item,BOOL *stop))block;

/** Hashes the URL to be used as a Yap key */
+ (NSString *)mediaItemKeyForURL:(NSURL *)url;

@end
