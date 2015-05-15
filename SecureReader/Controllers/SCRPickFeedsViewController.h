//
//  SCRPickFeedsViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-05-13.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRYapDatabaseTableDelegate.h"

@interface SCRPickFeedsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
