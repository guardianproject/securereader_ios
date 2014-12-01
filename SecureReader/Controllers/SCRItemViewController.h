//
//  SCRItemViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-11-24.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRItem.h"
#import "SCRItemView.h"

@interface SCRItemViewController : UIViewController<UIPageViewControllerDataSource>

@property (strong, nonatomic) SCRItem *item;

- (void) willExpandFromView:(SCRItemView *)view;

@end