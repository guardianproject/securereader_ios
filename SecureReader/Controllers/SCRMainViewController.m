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
#import "SCRTheme.h"
#import "SCRSettings.h"
#import "SCRPulseView.h"
#import "SCRMoreViewController.h"
#import "SCRHelpHintViewController.h"

@interface SCRMainViewController ()
@property (nonatomic, strong) SCRPulseView *settingsHintView;
@end

@implementation SCRMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tabBar setTheme:@"TabBarItemStyle"];
    int edgeHeight = [(NSNumber*)[SCRTheme getProperty:@"edgeHeight" forTheme:@"TabBarItemStyle"] intValue];
    UIColor *backgroundColorSelected = [SCRTheme getColorProperty:@"backgroundColorSelected" forTheme:@"TabBarItemStyle"];
    CGRect rect = CGRectMake(0, 0, 1, self.tabBar.bounds.size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetFillColorWithColor(context, [backgroundColorSelected CGColor]);
    CGContextFillRect(context, CGRectMake(0, self.tabBar.bounds.size.height - edgeHeight, 1, edgeHeight));
    UIImage *backgroundSelected = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.tabBar setSelectionIndicatorImage:[backgroundSelected resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeStretch]];;
    
    for (UITabBarItem *item in self.tabBar.items)
    {
        item.title = nil;
        item.imageInsets = UIEdgeInsetsMake(9, 0, -9, 0);
    }
    
    self.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (![SCRSettings hasShownInitialSettingsHelp])
    {
        // A single tab item's width is the entire width of the tab bar divided by number of items
        CGFloat tabItemWidth = self.tabBar.frame.size.width / self.tabBar.items.count;
        CGFloat positionX = 4 * tabItemWidth;
        CGFloat positionY = self.tabBar.frame.origin.y;
        
        _settingsHintView = [[SCRPulseView alloc] initWithFrame:CGRectMake(positionX, positionY - 10, 40, 40)];
        [self.view addSubview:_settingsHintView];
    }
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

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (viewController.tabBarItem.tag == 4711 && _settingsHintView != nil)
    {
        [_settingsHintView removeFromSuperview];
        _settingsHintView = nil;
        NSLog(@"Show hint!");
        
        UINavigationController *moreController = (UINavigationController *)viewController;
        
        SCRHelpHintViewController *hintController = [self.storyboard instantiateViewControllerWithIdentifier:@"hint"];
        [hintController setTargetViewController:moreController.topViewController];
#warning Placeholder text
        [hintController addTarget:@"help" withText:@"This is the help item"];
        [hintController addTarget:@"settings" withText:@"This is the settings"];
        [hintController setDelegate:self];
        [self addChildViewController:hintController];
        [hintController.view setAlpha:0.0];
        [self.view addSubview:hintController.view];
        [UIView animateWithDuration:kSCRHintViewAnimationFadeInDuration animations:^{
            [hintController.view setAlpha:1.0];
        }];
        return YES;
    }
    return YES;
}

- (void)helpHintViewControllerDidClose:(SCRHelpHintViewController *)viewController
{
    [SCRSettings setHasShownInitialSettingsHelp:YES];
}

@end
