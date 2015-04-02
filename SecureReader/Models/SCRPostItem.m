//
//  SCRPostItem.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPostItem.h"
#import "YapDatabaseTransaction.h"

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

@end
