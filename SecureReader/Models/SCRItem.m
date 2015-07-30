//
//  Item.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItem.h"
#import "SCRFeed.h"
#import "SCRMediaItem.h"
#import "SCRCommentItem.h"
#import "YapDatabaseTransaction.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "SCRDatabaseManager.h"
#import "IOCipher.h"
#import "NSString+SecureReader.h"

NSString *const kSCRMediaItemEdgeName = @"kSCRMediaItemEdgeName";
NSString *const kSCRFeedEdgeName      = @"kSCRFeedEdgeName";
NSString *const kSCRCommentEdgeName   = @"kSCRCommentEdgeName";


NSString *const kSCRFeedWfwPrefix = @"wfw";
NSString *const kSCRFeedWfwNameSpace = @"http://wellformedweb.org/CommentAPI/";

NSString *const kSCRFeedSlashPrefix = @"slash";
NSString *const kSCRFeedSlashNameSpace = @"http://purl.org/rss/1.0/modules/slash/";

NSString *const kSCRFeedPaikPrefix = @"paik";
NSString *const kSCRFeedPaikNameSpace = @"http://securereader.guardianproject.info/paik";

@implementation SCRItem

#pragma - mark RSSItem method overrides
- (instancetype)initWithFeedType:(RSSFeedType)feedType xmlElement:(ONOXMLElement *)xmlElement mediaItemClass:(Class)mediaItemClass
{
    if (self = [super initWithFeedType:feedType xmlElement:xmlElement mediaItemClass:mediaItemClass]) {
        [self parseSpecialFeedValues:xmlElement];
        self.totalCommentCount = 0;
    }
    return  self;
}

- (void)parseSpecialFeedValues:(ONOXMLElement *)xmlElement
{
    ONOXMLDocument *document = xmlElement.document;
    
    [document definePrefix:kSCRFeedWfwPrefix forDefaultNamespace:kSCRFeedWfwNameSpace];
    [document definePrefix:kSCRFeedSlashPrefix forDefaultNamespace:kSCRFeedSlashNameSpace];
    [document definePrefix:kSCRFeedPaikPrefix forDefaultNamespace:kSCRFeedPaikNameSpace];
    
    ONOXMLElement *wfw = [xmlElement firstChildWithXPath:[NSString stringWithFormat:@"%@:commentRss",kSCRFeedWfwPrefix]];
    self.commentsURL = [NSURL URLWithString:[wfw stringValue]];
    
    ONOXMLElement *countElement = [xmlElement firstChildWithXPath:[NSString stringWithFormat:@"%@:comments",kSCRFeedSlashPrefix]];
    self.commentCount = [countElement numberValue].unsignedIntegerValue;
    
    ONOXMLElement *paikIDElement = [xmlElement firstChildWithXPath:[NSString stringWithFormat:@"%@:id",kSCRFeedPaikPrefix]];
    self.paikID = [paikIDElement stringValue];
}

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

- (NSString *)pathForDownloadedHTML
{
    if ([self.yapKey length]) {
        return [NSString pathWithComponents:@[@"/html",[self.yapKey scr_md5],@"index.html"]];
    }
    return nil;
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

- (void)enumeratCommentsWithTransaction:(YapDatabaseReadTransaction *)transaction block:(void (^)(SCRCommentItem *comment,BOOL *stop))block
{
    if (!block) {
        return;
    }
    
    [[transaction ext:kSCRRelationshipExtensionName] enumerateEdgesWithName:kSCRCommentEdgeName destinationKey:self.yapKey collection:[[self class] yapCollection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        
        SCRCommentItem *comment = [transaction objectForKey:edge.sourceKey inCollection:edge.sourceCollection];
        block(comment,stop);
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
    
    if ([self.feedYapKey length]) {
        YapDatabaseRelationshipEdge *feedEdge = [YapDatabaseRelationshipEdge edgeWithName:kSCRFeedEdgeName
                                                                           destinationKey:self.feedYapKey
                                                                               collection:[SCRFeed yapCollection]
                                                                          nodeDeleteRules:YDB_DeleteSourceIfAllDestinationsDeleted];
        if (feedEdge) {
            [edges addObject:feedEdge];
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

#pragma - mark Class Methods

+ (void)removeItemsOlderThan:(NSDate *)date includeFavorites:(BOOL)includingFavorites withReadWriteTransaction:(YapDatabaseReadWriteTransaction *)transaction storage:(IOCipher *)storage
{
    __block NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
    __block NSMutableArray *mediaItemsToRemove = [[NSMutableArray alloc] init];
    [transaction enumerateKeysAndMetadataInCollection:[self yapCollection] usingBlock:^(NSString *key, id metadata, BOOL *stop) {
        if ([metadata isKindOfClass:[NSDate class]]) {
            NSDate *objectDate = (NSDate *)metadata;
            if ([date compare:objectDate] == NSOrderedDescending) {
                SCRItem *item = [transaction objectForKey:key inCollection:[self yapCollection]];
                
                if (!item.isFavorite || includingFavorites) {
                    [keysToRemove addObject:key];
                    
                    [item enumerateMediaItemsInTransaction:transaction block:^(SCRMediaItem *mediaItem, BOOL *stop) {
                        [mediaItemsToRemove addObject:mediaItem];
                    }];
                }
            }
        }
    }];
    
    for (SCRMediaItem *mediaItem in mediaItemsToRemove) {
        NSString *localPath = [mediaItem localPath];
        if ([localPath length]){
            [storage removeItemAtPath:localPath error:nil];
        }
        [transaction removeObjectForKey:mediaItem.yapKey inCollection:[SCRMediaItem yapCollection]];
    }
    
    [transaction removeObjectsForKeys:keysToRemove inCollection:[self yapCollection]];
}

#pragma - mark MTLModel Methods

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    NSMutableDictionary *dictionary = [[super encodingBehaviorsByPropertyKey] mutableCopy];
    
    [dictionary setObject:@(MTLModelEncodingBehaviorExcluded) forKey:NSStringFromSelector(@selector(mediaItems))];
    
    return dictionary;
}



@end
