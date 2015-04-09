//
//  SCRPostItem.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRItem.h"
#import "SCRYapObject.h"

@interface SCRPostItem : MTLModel<SCRYapObject>

@property (nonatomic) NSString *uuid;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *content;
@property (nonatomic) NSDate *lastEdited;
@property (nonatomic) BOOL isSent;

@property (nonatomic, strong) NSArray *tags;

@property (nonatomic, strong) NSArray *mediaItemsYapKeys;

- (void)removeMediaItemsWithReadWriteTransaction:(YapDatabaseReadWriteTransaction *)transaction storage:(IOCipher *)storage;

- (void)enumerateMediaItemsInTransaction:(YapDatabaseReadTransaction *)readTransaction block:(void (^)(SCRMediaItem *mediaItem,BOOL *stop))block;

@end
