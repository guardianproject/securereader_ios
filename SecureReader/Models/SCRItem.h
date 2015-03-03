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
#import "RSSItem.h"

@import UIKit;

@interface SCRItem : RSSItem <SCRYapObject>

/** yapKay for the parent SCRFeed */
@property (nonatomic, strong) NSString *feedYapKey;

@property (nonatomic) BOOL isFavorite;
@property (nonatomic) BOOL isReceived;

// TEMP - replace with real property!
- (NSArray *)tags;

@end
