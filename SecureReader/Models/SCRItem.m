//
//  Item.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItem.h"
#import "SCRMediaItem.h"
#import "YapDatabaseTransaction.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "SCRDatabaseManager.h"

NSString *const kSCRMediaItemEdgeName = @"kSCRMediaItemEdgeName";

@implementation SCRItem

#pragma mark SRCYapObject methods

- (NSString*) yapKey {
    return [self.linkURL absoluteString];
}

- (NSString*) yapGroup {
    return self.feedYapKey;
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

- (NSArray *)tags
{
    return [NSArray arrayWithObjects:@"Tag", @"Long tag", @"A really really long tag that will scroll", nil];
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
    if ([mediaItemKeys count]) {
        NSMutableArray *edges = [NSMutableArray arrayWithCapacity:[mediaItemKeys count]];
        
        for (NSString *mediaItemKey in mediaItemKeys) {
            //Review nodeDeletionRules. Need some way to make sure we delete the file in IOCipher
            YapDatabaseRelationshipEdge *mediaItemEdge = [YapDatabaseRelationshipEdge edgeWithName:kSCRMediaItemEdgeName
                                                                                    destinationKey:mediaItemKey
                                                                                        collection:[SCRMediaItem yapCollection]
                                                                                   nodeDeleteRules:YDB_DeleteDestinationIfAllSourcesDeleted];
            if (mediaItemEdge) {
                [edges addObject:mediaItemEdge];
            }
            
        }
        return edges;
    }
    return nil;
}

#pragma - mark MTLModel Methods

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *dictionary = [[super encodingBehaviorsByPropertyKey] mutableCopy];
    
    [dictionary setObject:@(MTLModelEncodingBehaviorExcluded) forKey:NSStringFromSelector(@selector(mediaItems))];
    
    return dictionary;
}

@end
