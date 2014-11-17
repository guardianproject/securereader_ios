//
//  Item.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItem.h"

@implementation SCRItem

- (instancetype)initWithFeedItem:(MWFeedItem*)item {
    if (self = [super init]) {
        _title = item.title;
        _summary = item.summary;
        _url = [NSURL URLWithString:item.link];
        _publishDate = item.date;
        _updateDate = item.updated;
    }
    return self;
}

#pragma mark SRCYapObject methods

- (NSString*) yapKey {
    return [self.url absoluteString];
}

- (NSString*) yapGroup {
    return [self.url host];
}

+ (NSString*) yapCollection {
    return NSStringFromClass([self class]);
}

@end
