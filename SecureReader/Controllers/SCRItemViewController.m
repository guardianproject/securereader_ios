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
#import "SCRNavigationController.h"
#import "SCRLabel.h"
#import "SCRApplication.h"
#import "SCRSettings.h"
#import "SCRTheme.h"
#import "UIBarItem+Theming.h"
#import "SCRAppDelegate.h"
#import "NSString+HTML.h"
#import "SCRCommentsViewController.h"
#import "SCRRequireNicknameSegue.h"
#import "NSURL+SecureReader.h"
#import "SCRWordpressClient.h"
#import "SCRDatabaseManager.h"

@interface SCRItemViewController ()
@property id<SCRItemViewControllerDataSource> itemDataSource;
@property NSIndexPath *currentItemIndex;
@property (weak, nonatomic) IBOutlet UIPageViewController *pageViewController;
@property (weak, nonatomic) IBOutlet UIView *container;
@property UIGestureRecognizer *textSizeViewGestureRecognizer;
@property BOOL textSizeViewVisible;
@property UIColor *favoriteButtonDefaultTintColor;
@property UIColor *favoriteButtonSelectedTintColor;
@end

@implementation SCRItemViewController

@synthesize pageViewController;
@synthesize itemDataSource;
@synthesize currentItemIndex;

- (void)viewDidLoad {
    [super viewDidLoad];
    pageViewController = [[self childViewControllers] objectAtIndex:0];
    pageViewController.delegate = self;
    
    self.textSizeViewGestureRecognizer = [[UIGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextSizeGesture:)];
    [self.textSizeViewGestureRecognizer setEnabled:YES];
    [self.textSizeViewGestureRecognizer setCancelsTouchesInView:NO];
    [self.textSizeViewGestureRecognizer setDelaysTouchesBegan:NO];
    [self.textSizeViewGestureRecognizer setDelaysTouchesEnded:NO];
    [self.textSizeViewGestureRecognizer setDelegate:self];
    
    self.favoriteButtonDefaultTintColor = [self.buttonFavorite tintColor];
    self.favoriteButtonSelectedTintColor = [SCRTheme getColorProperty:@"onTintColor" forTheme:[self.buttonFavorite theme]];
    
    
    if (self.hidesFavoriteButton)
    {
        // Remove the buttons from the toolbar
        NSMutableArray *toolbarButtons = [self.toolBar.items mutableCopy];
        [toolbarButtons removeObject:self.buttonFavorite];
        [toolbarButtons removeObject:self.buttonFavoriteSpace];
        [self.toolBar setItems:toolbarButtons];
    }
    
    [self updateCurrentView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.textSizeSlider.value = [SCRSettings fontSizeAdjustment];
    SCRItemPageViewController *viewController = [self.pageViewController.viewControllers firstObject];
    [self updateCommentButton:viewController.item];
}

- (UIViewController *)viewControllerForIndexPath:(NSIndexPath *)indexPath
{
    SCRItem *item = [itemDataSource itemForIndexPath:indexPath];
    if (item != nil)
    {
        SCRItemPageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"fullScreenItemView"];
        [vc setItem:item];
        [vc setItemIndexPath:indexPath];
        
        [self updateCommentButton:item];
        
        [(SCRNavigationController *)self.navigationController registerScrollViewForHideBars:vc.scrollView];
        return vc;
    }
    return nil;
}

- (void)updateCommentButton:(SCRItem *)item{
    if ([[item.commentsURL absoluteString] length]) {
        self.buttonComment.hidden = NO;
        [self.buttonComment setBadge:[NSString stringWithFormat:@"%d",item.totalCommentCount]];
        SCRWordpressClient *wpClient = [SCRWordpressClient defaultClient];
        NSString *username = [SCRSettings wordpressUsername];
        NSString *password = [SCRSettings wordpressPassword];
        if ([username length] && [password length]) {
            [wpClient setUsername:username password:password];
            //Todo: Change to only update every so often not on every button update.
            if (item.lastCheckedCommentCount == nil || ABS([item.lastCheckedCommentCount timeIntervalSinceNow]) > 3600) {
                [wpClient getCommentCountsForPostId:[item.commentsURL scr_wordpressPostID] completionBlock:^(NSUInteger approvedCount, NSUInteger awaitingModerationCount, NSUInteger spamCount, NSUInteger totalCommentCount, NSError *error) {
                    __block NSString *badgeString = @"0";
                    if (!error) {
                        [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * transaction) {
                            SCRItem *tempItem = [transaction objectForKey:item.yapKey inCollection:[SCRItem yapCollection]];
                            tempItem.totalCommentCount = totalCommentCount;
                            tempItem.lastCheckedCommentCount = [NSDate date];
                            [tempItem saveWithTransaction:transaction];
                        }];
                        badgeString = [NSString stringWithFormat:@"%d",totalCommentCount];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buttonComment setBadge:badgeString];
                    });
                }];
            }
            
        }
    } else {
        self.buttonComment.hidden = YES;
    }
}

#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)viewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    [self updateFavoriteIcon];
}

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


- (void) setDataView:(id<SCRItemViewControllerDataSource>)dataView withStartAt:(NSIndexPath *)indexPath
{
    self.itemDataSource = dataView;
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
        [self updateFavoriteIcon];
    }
}
             

#pragma mark - Toolbar buttons

- (IBAction)commentButtonClicked:(id)sender
{
    SCRItemPageViewController *itemPage = [[self.pageViewController viewControllers] objectAtIndex:0];
    if (itemPage != nil)
    {
        SCRItem *item = itemPage.item;
        SCRCommentsViewController *commentsController = (SCRCommentsViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"fullScreenItemCommentsView"];
        NSString *post = [item.commentsURL scr_wordpressPostID];
        [commentsController setPostId:post];
        SCRRequireNicknameSegue *segue = [[SCRRequireNicknameSegue alloc] initWithIdentifier:@"" source:self destination:commentsController];
        [self prepareForSegue:segue sender:self];
        [segue perform];
    }
}

- (IBAction)textSizeItemClicked:(id)sender
{
    [self toggleTextSizeView];
}

- (IBAction)markItemAsFavorite:(id)sender
{
    SCRItemPageViewController *itemPage = [[self.pageViewController viewControllers] objectAtIndex:0];
    if (itemPage != nil)
    {
        SCRItem *item = itemPage.item;
        [[SCRAppDelegate sharedAppDelegate] markItem:item asFavorite:![item isFavorite]];
    }
    [self updateFavoriteIcon];
}

- (IBAction)shareItem:(id)sender
{
    SCRItemPageViewController *itemPage = [[self.pageViewController viewControllers] objectAtIndex:0];
    if (itemPage != nil)
    {
        SCRItem *item = itemPage.item;
        NSMutableArray *items = [NSMutableArray array];
        if (item.title) {
            [items addObject:item.title];
        }
        if (item.itemDescription) {
            NSString *body = [item.itemDescription stringByConvertingHTMLToPlainText];
            [items addObject:body];
        }
        if (item.linkURL) {
            [items addObject:item.linkURL];
        }
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        [self presentViewController:activityViewController animated:YES completion:nil];
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

- (void)updateFavoriteIcon
{
    SCRItemPageViewController *itemPage = [[self.pageViewController viewControllers] objectAtIndex:0];
    if (itemPage != nil)
    {
        if ([[itemPage item] isFavorite])
            [self.buttonFavorite setTintColor:self.favoriteButtonSelectedTintColor];
        else
            [self.buttonFavorite setTintColor:self.favoriteButtonDefaultTintColor];
    }
    else
    {
        [self.buttonFavorite setTintColor:self.favoriteButtonDefaultTintColor];
    }
}

@end
