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
- (void)showBars;
@property BOOL isHidingBars;
@property (weak) UIView *topBar;
@property (weak) UIView *bottomBar;
@property CGFloat startScrollOffset;
@property CGFloat startTopBarOffset;
@property CGFloat startBottomBarOffset;
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

    self.isHidingBars = YES;
    self.topBar = self.navigationBar;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (!self.isHidingBars)
    {
        [self showBars];
    }
    [super pushViewController:viewController animated:animated];
}

- (UIView *) getBottomBar
{
    if (self.topViewController == nil)
        return nil;
    if ([self.topViewController respondsToSelector:@selector(toolBar)])
    {
        return [self.topViewController performSelector:@selector(toolBar)];
    }
    else
    {
        return self.topViewController.tabBarController.tabBar;
    }
}

- (void)registerScrollViewForHideBars:(UIScrollView *)scrollView
{
    [scrollView.panGestureRecognizer addTarget:self action:@selector(handlePan:)];
    if (!self.isHidingBars)
    {
        [self showBars];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    UIScrollView *scrollView = (UIScrollView *)gesture.view;
    if (scrollView == nil)
        return;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        self.startScrollOffset = scrollView.contentOffset.y;
        if (self.isHidingBars)
        {
            self.bottomBar = [self getBottomBar];
            self.startTopBarOffset = self.topBar.frame.origin.y;
            self.startBottomBarOffset = self.bottomBar.frame.origin.y;
        }
    }
    else if (gesture.state == UIGestureRecognizerStateChanged)
    {
        CGFloat currentOffset = scrollView.contentOffset.y;
        CGFloat delta = self.startScrollOffset - currentOffset;
        
        CGRect frame = self.topBar.frame;
        CGFloat position = 0;
        if (self.isHidingBars)
            position = self.startTopBarOffset + delta;
        else
            position = - frame.size.height + delta;
        frame.origin.y = MAX(- frame.size.height, MIN(self.startTopBarOffset, position));
        [self.topBar setFrame:frame];
        
        frame = self.bottomBar.frame;
        if (self.isHidingBars)
            position = self.startBottomBarOffset - delta;
        else
            position = self.startBottomBarOffset + frame.size.height - delta;
        frame.origin.y = MIN(self.startBottomBarOffset + frame.size.height, MAX(self.startBottomBarOffset, position));
        [self.bottomBar setFrame:frame];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        CGFloat currentOffset = scrollView.contentOffset.y;
        CGFloat delta = self.startScrollOffset - currentOffset;
        if ((!self.isHidingBars && delta >= (self.topBar.frame.size.height / 5))
            ||
            (self.isHidingBars && delta >= -(self.topBar.frame.size.height / 2)))
        {
            [self showBars];
        }
        else
        {
            [UIView animateWithDuration:0.2 animations:^{
                CGRect frame = self.topBar.frame;
                frame.origin.y = -frame.size.height -self.startTopBarOffset;
                [self.topBar setFrame:frame];
                frame = self.bottomBar.frame;
                frame.origin.y = self.startBottomBarOffset + frame.size.height;
                [self.bottomBar setFrame:frame];
            } completion:^(BOOL finished) {
                self.isHidingBars = NO;
            }];
        }
    }
}

- (void)showBars
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.topBar.frame;
        frame.origin.y = self.startTopBarOffset;
        [self.topBar setFrame:frame];
        frame = self.bottomBar.frame;
        frame.origin.y = self.startBottomBarOffset;
        [self.bottomBar setFrame:frame];
    } completion:^(BOOL finished) {
        self.isHidingBars = YES;
    }];
}

@end
