//
//  SCRMediaDownloadsTableDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-27.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRMediaFetcher.h"

@interface SCRMediaDownloadsTableDelegate : NSObject<SCRMediaFetcherDelegate, UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithMediaFetcher:(SCRMediaFetcher *)fetcher;

@property (nonatomic, weak) UITableView *tableView;

@end
