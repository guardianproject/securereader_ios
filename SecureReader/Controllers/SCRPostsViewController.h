//
//  SCRPostsViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-02-24.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell.h>
#import "SCRYapDatabaseTableDelegate.h"

@interface SCRPostsViewController : UIViewController<SWTableViewCellDelegate, SCRYapDatabaseTableDelegateDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@end
