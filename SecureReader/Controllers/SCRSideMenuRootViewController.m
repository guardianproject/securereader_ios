//
//  SCRSideMenuViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-10.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRSideMenuRootViewController.h"
#import "SCRAppDelegate.h"

@interface SCRSideMenuRootViewController ()

@end

@implementation SCRSideMenuRootViewController

@synthesize content;
@synthesize menu;

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewController *vcMain = [self.storyboard instantiateViewControllerWithIdentifier:self.content];
    UIViewController *vcMenu = [self.storyboard instantiateViewControllerWithIdentifier:self.menu];
    [self setLeftDrawerViewController:vcMenu];
    [self setCenterViewController:vcMain];
    [self setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeBezelPanningCenterView];
    [self setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)openDrawerAction:(id)sender
{
    if (self.openSide == MMDrawerSideNone)
        [self openDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    else
        [self closeDrawerAnimated:YES completion:nil];
}

@end
