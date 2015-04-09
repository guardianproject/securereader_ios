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
#import "SCRDatabaseManager.h"

@interface SCRMainViewController ()

@end

@implementation SCRMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tabBar setTheme:@"TabBarItemStyle"];
    self.delegate = self;
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
