//
//  Item.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItem.h"

@implementation SCRItem

#pragma mark SRCYapObject methods

- (NSString*) yapKey {
    return [self.linkURL absoluteString];
}

- (NSString*) yapGroup {
    return self.feedYapKey;
}

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

@end
