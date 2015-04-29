//
//  SCRMediaDownloadsControllerTableViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-27.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRMediaFetcherWatcher.h"

@interface SCRMediaDownloadsViewController : UITableViewController<SCRMediaFetcherWatcherDelegate, UITableViewDataSource, UITableViewDelegate>
@end
