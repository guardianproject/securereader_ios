//
//  SCRFeed.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/24/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeed.h"
#import "SCRItem.h"
#import "SCRDatabaseManager.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "YapDatabaseTransaction.h"

@interface SCRFeed ()

@property (nonatomic, strong) NSString *yapKey;

@end

@implementation SCRFeed

#pragma mark SRCYapObject methods

- (NSString*) yapKey {
    
    if (!_yapKey) {
        if ([self.xmlURL.absoluteString length]) {
            _yapKey = [self.xmlURL absoluteString];
        }
        else if([self.htmlURL.absoluteString length]) {
            _yapKey = [self.htmlURL absoluteString];
        }
        else {
            _yapKey = [[NSUUID UUID] UUIDString];
        }
        if ([_yapKey hasSuffix:@"/"])
            _yapKey = [_yapKey substringToIndex:([_yapKey length] - 1)];
        _yapKey = [_yapKey lowercaseString];
    }
    return _yapKey;
}

- (NSString*) yapGroup {
    if ([self.htmlURL.absoluteString length]) {
        return [self.htmlURL host];
    } else {
        return [self.xmlURL host];
    }
}

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction setObject:self forKey:[self yapKey] inCollection:[[self class] yapCollection]];
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction removeObjectForKey:[self yapKey] inCollection:[[self class] yapCollection]];
}

- (void)enumerateItemsInTransaction:(YapDatabaseReadTransaction *)readTransaction block:(void (^)(SCRItem *item, BOOL *stop))block
{
    if (!block) {
        return;
    }
    
    [[readTransaction ext:kSCRRelationshipExtensionName] enumerateEdgesWithName:kSCRFeedEdgeName destinationKey:self.yapKey collection:[[self class] yapCollection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        
        SCRItem *mediaItem = [readTransaction objectForKey:edge.sourceKey inCollection:edge.sourceCollection];
        block(mediaItem,stop);
        
    }];
}

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

+ (void)removeFeed:(SCRFeed *)feed inTransaction:(YapDatabaseReadWriteTransaction *)transaction storage:(IOCipher *)storage
{
    [feed enumerateItemsInTransaction:transaction block:^(SCRItem *item, BOOL *stop) {
        [item removeMediaItemsWithReadWriteTransaction:transaction storage:storage];
        [transaction removeObjectForKey:item.yapKey inCollection:[[item class] yapCollection]];
    }];
    [transaction removeObjectForKey:feed.yapKey inCollection:[[feed class] yapCollection]];
}

@end
