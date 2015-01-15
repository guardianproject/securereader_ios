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

    // Hide bar on swipe, if we are running 8 or higher
    if ([self respondsToSelector:@selector(setHidesBarsOnSwipe:)])
    {
        [self performSelector:@selector(setHidesBarsOnSwipe:) withObject:[NSNumber numberWithBool:YES]];
    }
}

@end
