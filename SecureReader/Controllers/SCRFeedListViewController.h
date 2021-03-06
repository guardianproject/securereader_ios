//
//  SCRManageFeedsViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-01-29.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell.h>
#import "SCRYapDatabaseTableDelegate.h"
#import "SCRFeedSearchTableDelegate.h"

@interface SCRFeedListViewController : UIViewController<UISearchBarDelegate, SWTableViewCellDelegate, SCRFeedSearchTableDelegateDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *segmentedControlHeightConstraint;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trendingViewHeightConstraint;
@end
