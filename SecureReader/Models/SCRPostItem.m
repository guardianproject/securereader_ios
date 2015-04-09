//
//  SCRPostItem.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPostItem.h"
#import "SCRMediaItem.h"
#import "SCRDatabaseManager.h"
#import "IOCipher.h"
#import "YapDatabaseTransaction.h"
#import "YapDatabaseRelationshipTransaction.h"

extern NSString *const kSCRMediaItemEdgeName; // = @"kSCRMediaItemEdgeName";

@implementation SCRPostItem

#pragma mark SRCYapObject methods

- (NSString*) yapKey {
    return self.uuid;
}

- (NSString*) yapGroup {
    if (self.isSent) {
        return @"Sent";
    } else {
        return @"Drafts";
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

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}


- (void)removeMediaItemsWithReadWriteTransaction:(YapDatabaseReadWriteTransaction *)transaction storage:(IOCipher *)storage
{
    [self enumerateMediaItemsInTransaction:transaction block:^(SCRMediaItem *mediaItem, BOOL *stop) {
        [storage removeItemAtPath:[mediaItem localPath] error:nil];
        [transaction removeObjectForKey:mediaItem.yapKey inCollection:[[mediaItem class] yapCollection]];
    }];
}

- (void)enumerateMediaItemsInTransaction:(YapDatabaseReadTransaction *)readTransaction block:(void (^)(SCRMediaItem *, BOOL *))block
{
    if (!block) {
        return;
    }
    
    [[readTransaction ext:kSCRRelationshipExtensionName] enumerateEdgesWithName:kSCRMediaItemEdgeName sourceKey:self.yapKey collection:[[self class] yapCollection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        
        SCRMediaItem *mediaItem = [readTransaction objectForKey:edge.destinationKey inCollection:edge.destinationCollection];
        block(mediaItem,stop);
        
    }];
}

#pragma - mark YapDatabaseRelationship Methods

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *mediaItemKeys = [self mediaItemsYapKeys];
    NSMutableArray *edges = [NSMutableArray arrayWithCapacity:[mediaItemKeys count]];
    if ([mediaItemKeys count]) {
        
        for (NSString *mediaItemKey in mediaItemKeys) {
            //Review nodeDeletionRules. Need some way to make sure we delete the file in IOCipher
            YapDatabaseRelationshipEdge *mediaItemEdge = [YapDatabaseRelationshipEdge edgeWithName:kSCRMediaItemEdgeName
                                                                                    destinationKey:mediaItemKey
                                                                                        collection:[SCRMediaItem yapCollection]
                                                                                   nodeDeleteRules:YDB_NotifyIfDestinationDeleted];
            if (mediaItemEdge) {
                [edges addObject:mediaItemEdge];
            }
            
        }
    }
    return edges;
}

- (id)yapDatabaseRelationshipEdgeDeleted:(YapDatabaseRelationshipEdge *)edge withReason:(YDB_NotifyReason)reason
{
    if (reason == YDB_DestinationNodeDeleted) {
        [[self.mediaItemsYapKeys mutableCopy] removeObject:edge.destinationKey];
    }
    return self;
}

#pragma - mark MTLModel Methods

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *dictionary = [[super encodingBehaviorsByPropertyKey] mutableCopy];
    
    [dictionary setObject:@(MTLModelEncodingBehaviorExcluded) forKey:NSStringFromSelector(@selector(mediaItems))];
    
    return dictionary;
}

@end
