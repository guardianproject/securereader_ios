//
//  SCRRootTabViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-07.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMainViewController.h"
#import "SCRLoginViewController.h"
#import "SCRAppDelegate.h"
#import "SCRFeedViewController.h"
#import "UIView+Theming.h"

@interface SCRMainViewController ()

@end

@implementation SCRMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tabBar setTheme:@"TabBarItemStyle"];
    self.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![[SCRAppDelegate sharedAppDelegate] isLoggedIn])
    {
        SCRLoginViewController *vcLogin = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
        vcLogin.modalPresentationStyle = UIModalPresentationFullScreen;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:vcLogin animated:NO completion:nil];
        });
        return;
    }
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (![[SCRAppDelegate sharedAppDelegate] isLoggedIn])
    {
        SCRLoginViewController *vcLogin = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
        vcLogin.modalPresentationStyle = UIModalPresentationFullScreen;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:vcLogin animated:NO completion:nil];
        });
        return NO;
    }
    return YES;
}

- (IBAction)showPanicAction:(id)sender
{
    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"panic"];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:viewController animated:YES completion:nil];
    });
}

- (IBAction)receiveShareAction:(id)sender
{
    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"receiveShare"];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:viewController animated:YES completion:nil];
    });
}


@end
