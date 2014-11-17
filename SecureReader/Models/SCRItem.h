//
//  Item.h
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mantle.h"
#import "SCRYapObject.h"
#import "MWFeedItem.h"

@interface SCRItem : MTLModel <SCRYapObject>

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *summary;
@property (nonatomic, strong, readonly) NSDate *publishDate;
@property (nonatomic, strong, readonly) NSDate *updateDate;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, readonly) NSURL *thumbnailURL;

- (instancetype)initWithFeedItem:(MWFeedItem*)item;

@end
