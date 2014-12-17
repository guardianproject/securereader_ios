//
//  SRNavigationController.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRNavigationController.h"
#import "SCRAppDelegate.h"
#import "SCRSelectLanguageViewController.h"
#import "SCRCreatePassphraseViewController.h"
#import "SCRLoginViewController.h"
#import "SCRItemViewController.h"
#import "SCRFeedViewController.h"
#import "UIView+Theming.h"
#import "SCRTheme.h"
#import "SCRItemViewControllerSegue.h"

#define kAnimationDurationFadeIn 0.2
#define kAnimationDurationExpand 0.5
#define kAnimationDurationCollapse 0.5
#define kAnimationDurationFadeOut 0.2

@interface SCRNavigationController ()

@end

@implementation SCRNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationBar setTheme:@"NavigationBarItemStyle"];

    UIColor *color = [SCRTheme getColorProperty:@"textColor" forTheme:@"NavigationBarItemStyle"];
    if (color != nil)
    {
        [self.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName]];
    }
    [self performSegueWithIdentifier:@"segueToMain" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController class] != [SCRSelectLanguageViewController class] &&
        [viewController class] != [SCRCreatePassphraseViewController class] &&
        [viewController class] != [SCRLoginViewController class])
    {
        if (![[SCRAppDelegate sharedAppDelegate] isLoggedIn])
        {
            SCRLoginViewController *vcLogin = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
            vcLogin.modalPresentationStyle = UIModalPresentationFullScreen;
            [vcLogin setDestinationViewController:viewController navigationController:self animated:animated];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:vcLogin animated:YES completion:nil];
            });
            return;
        }
    }
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    return [super popViewControllerAnimated:animated];
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
    [self pushViewController:viewController animated:YES];
}

@end
