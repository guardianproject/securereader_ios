//
//  SCRItemPageViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-11-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRItem.h"

@interface SCRItemPageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITextView *contentView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) SCRItem *item;
@property (strong, nonatomic) NSIndexPath *itemIndexPath;

@end
