//
//  SCRFeed.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/24/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeed.h"

@implementation SCRFeed

#pragma mark SRCYapObject methods

- (NSString*) yapKey {
    return [self.htmlURL absoluteString];
}

- (NSString*) yapGroup {
    return [self.htmlURL host];
}

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

@end
