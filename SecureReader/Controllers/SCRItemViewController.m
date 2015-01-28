//
//  SCRItemViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-24.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemViewController.h"
#import "SCRItemPageViewController.h"
#import "SCRItem.h"
#import "SCRReader.h"
#import "SCRNavigationController.h"
#import "SCRLabel.h"
#import "SCRApplication.h"
#import "SCRSettings.h"


@interface SCRItemViewController ()
@property SCRFeedViewController *itemDataSource;
@property NSIndexPath *currentItemIndex;
@property (weak, nonatomic) IBOutlet UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIView *container;
@property UIGestureRecognizer *textSizeViewGestureRecognizer;
@property BOOL textSizeViewVisible;
@end

@implementation SCRItemViewController

@synthesize pageViewController;
@synthesize itemDataSource;
@synthesize currentItemIndex;

- (void)viewDidLoad {
    [super viewDidLoad];
    pageViewController = [[self childViewControllers] objectAtIndex:0];
    pageViewController.delegate = self;
    [self updateCurrentView];
    
    self.textSizeViewGestureRecognizer = [[UIGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextSizeGesture:)];
    [self.textSizeViewGestureRecognizer setEnabled:YES];
    [self.textSizeViewGestureRecognizer setCancelsTouchesInView:NO];
    [self.textSizeViewGestureRecognizer setDelaysTouchesBegan:NO];
    [self.textSizeViewGestureRecognizer setDelaysTouchesEnded:NO];
    [self.textSizeViewGestureRecognizer setDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.textSizeSlider.value = [SCRSettings fontSizeAdjustment];
}

- (UIViewController *)viewControllerForIndexPath:(NSIndexPath *)indexPath
{
    SCRItem *item = [itemDataSource itemForIndexPath:indexPath];
    if (item != nil)
    {
        SCRItemPageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"fullScreenItemView"];
        [vc setItem:item];
        [vc setItemIndexPath:indexPath];
        [(SCRNavigationController *)self.navigationController registerScrollViewForHideBars:vc.scrollView];
        return vc;
    }
    return nil;
}

#pragma mark - Page View Controller Delegate

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[SCRItemPageViewController class]])
    {
        NSIndexPath *indexPath = [(SCRItemPageViewController *)viewController itemIndexPath];
        NSIndexPath *newPath = [NSIndexPath indexPathForRow:(indexPath.row - 1)
                                                  inSection:indexPath.section];
        return [self viewControllerForIndexPath:newPath];
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[SCRItemPageViewController class]])
    {
        NSIndexPath *indexPath = [(SCRItemPageViewController *)viewController itemIndexPath];
        NSIndexPath *newPath = [NSIndexPath indexPathForRow:(indexPath.row + 1)
                                                  inSection:indexPath.section];
        return [self viewControllerForIndexPath:newPath];
    }
    return nil;
}


#pragma mark - Data

- (void) setDataView:(SCRFeedViewController *)feedView withStartAt:(NSIndexPath *)indexPath
{
    self.itemDataSource = feedView;
    self.currentItemIndex = indexPath;
    [self updateCurrentView];
}
             
- (void) updateCurrentView
{
    if (itemDataSource != nil && currentItemIndex != nil && self.isViewLoaded)
    {
        [pageViewController setDataSource:self];
        
        SCRItem *item = [itemDataSource itemForIndexPath:currentItemIndex];
        SCRItemPageViewController *initialViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"fullScreenItemView"];
        [initialViewController setItem:item];
        [initialViewController setItemIndexPath:currentItemIndex];
        [(SCRNavigationController *)self.navigationController registerScrollViewForHideBars:initialViewController.scrollView];
        NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
        [pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
}
             

#pragma mark - Toolbar buttons

- (IBAction)textSizeItemClicked:(id)sender
{
    [self toggleTextSizeView];
}

- (IBAction)markItemAsFavorite:(id)sender
{
    SCRItem *item = [itemDataSource itemForIndexPath:self.currentItemIndex];
    if (item != nil)
    {
        [[SCRReader sharedInstance] markItem:item asFavorite:YES]; //TODO - toggle
    }
}

- (void) showTextSizeView
{
    [self.view addGestureRecognizer:self.textSizeViewGestureRecognizer];
    [self.view layoutIfNeeded];
    self.textSizeViewHeightConstraint.constant = 60;
    [UIView animateWithDuration:0.5 animations:^{
        self.textSizeView.alpha = 1.0f;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.textSizeViewVisible = YES;
    }];
 
}

- (void) hideTextSizeView
{
    [self.view removeGestureRecognizer:self.textSizeViewGestureRecognizer];
    [self.view layoutIfNeeded];
    self.textSizeViewHeightConstraint.constant = 0;
    [UIView animateWithDuration:0.5 animations:^{
        self.textSizeView.alpha = 0.0f;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.textSizeViewVisible = NO;
    }];
}

- (void) toggleTextSizeView
{
    if (self.textSizeViewVisible)
        [self hideTextSizeView];
    else
        [self showTextSizeView];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (!CGRectContainsPoint(self.textSizeView.frame, [touch locationInView:self.view]) && self.textSizeViewHeightConstraint.constant > 0)
    {
        [self hideTextSizeView];
    }
    return NO;
}

- (void)handleTextSizeGesture:(UIGestureRecognizer *)gestureRecognizer
{
    // Not used
}

- (IBAction)textSideSliderChanged:(id)sender
{
    [SCRSettings setFontSizeAdjustment:self.textSizeSlider.value];
}

@end
