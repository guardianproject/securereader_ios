//
//  SCRFeedShareViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-03-04.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SWTableViewCell.h>
#import "SCRYapDatabaseTableDelegate.h"

@interface SCRFeedShareViewController : UIViewController<SCRYapDatabaseTableDelegateDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
