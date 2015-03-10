//
//  SCRFeed.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/24/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "RSSFeed.h"
#import "SCRYapObject.h"

@interface SCRFeed : RSSFeed <SCRYapObject>

@property (nonatomic) BOOL subscribed;
@property (nonatomic) BOOL userAdded;

@end
