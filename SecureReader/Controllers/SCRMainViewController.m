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

@interface SCRMainViewController ()

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
