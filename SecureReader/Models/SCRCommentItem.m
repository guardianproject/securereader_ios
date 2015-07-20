//
//  SCRCommentItem.m
//  SecureReader
//
//  Created by David Chiles on 7/13/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRCommentItem.h"

@implementation SCRCommentItem

#pragma - mark YapDatabaseRelationship Methods

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSMutableArray *edges = [[NSMutableArray alloc] init];
    
    if ([self.parentItemKey length]) {
        YapDatabaseRelationshipEdge *feedEdge = [YapDatabaseRelationshipEdge edgeWithName:kSCRCommentEdgeName
                                                                           destinationKey:self.parentItemKey
                                                                               collection:[SCRItem yapCollection]
                                                                          nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        if (feedEdge) {
            [edges addObject:feedEdge];
        }
    }
    return edges;
}

@end
