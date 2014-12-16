//
//  SRMainViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRItemViewController.h"
#import "SCRFeed.h"

typedef NS_ENUM(NSInteger, SCRFeedViewType) {
    SCRFeedViewTypeAllFeeds,
    SCRFeedViewTypeFeed,
    SCRFeedViewTypeFavorites,
    SCRFeedViewTypeReceived
};

@interface SCRFeedViewController : UITableViewController

@property (nonatomic) CGRect selectedItemRect;

- (void) setFeedViewType:(SCRFeedViewType)type feed:(SCRFeed *)feed;

@end
