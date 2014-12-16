//
//  SCRTabBarSegue.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-15.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRMainViewControllerSegue.h"
#import "SCRMainViewController.h"

@implementation SCRMainViewControllerSegue

- (void) perform {
    SCRMainViewController *tabBarViewController = (SCRMainViewController *)self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    for (UIViewController *child in tabBarViewController.childViewControllers)
    {
        [child willMoveToParentViewController:nil];
        [child.view removeFromSuperview];
        [child removeFromParentViewController];
    }
    
    destinationViewController.view.frame = tabBarViewController.container.bounds;
    [tabBarViewController addChildViewController:destinationViewController];
    [tabBarViewController.container addSubview:destinationViewController.view];
    [destinationViewController didMoveToParentViewController:tabBarViewController];
    
    tabBarViewController.navigationItem.title = destinationViewController.navigationItem.title;
    tabBarViewController.navigationItem.rightBarButtonItems = destinationViewController.navigationItem.rightBarButtonItems;
    tabBarViewController.navigationItem.rightBarButtonItem = destinationViewController.navigationItem.rightBarButtonItem;
}

@end
