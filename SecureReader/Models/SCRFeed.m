//
//  SCRFeed.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/24/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeed.h"
#import "YapDatabaseTransaction.h"

@implementation SCRFeed

#pragma mark SRCYapObject methods

- (NSString*) yapKey {
    return [self.htmlURL absoluteString];
}

- (NSString*) yapGroup {
    return [self.htmlURL host];
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

@end
