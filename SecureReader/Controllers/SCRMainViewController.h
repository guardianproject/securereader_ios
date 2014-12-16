//
//  SCRRootViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-12-05.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRMainViewController : UIViewController<UITabBarDelegate>

@property (strong, nonatomic) IBOutlet UITabBar *tabBar;
@property (strong, nonatomic) IBOutlet UIView *container;

@end
