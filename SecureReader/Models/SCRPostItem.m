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

@implementation SCRPostItem

@synthesize title = _title;
@synthesize itemDescription = _itemDescription;
@synthesize publicationDate = _publicationDate;

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

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

@end
