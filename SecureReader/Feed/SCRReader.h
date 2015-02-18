//
//  SCRReader.h
//  SecureReader
//
//  Created by N-Pex on 2015-01-19.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCRFeed.h"
#import "SCRItem.h"

@interface SCRReader : NSObject

+ (SCRReader *) sharedInstance;

-(void) removeFeed:(SCRFeed *)feed;
-(void) setFeed:(SCRFeed *)feed subscribed:(BOOL)subscribed;
-(void) markItem:(SCRItem *)item asFavorite:(BOOL)favorite;

@end
