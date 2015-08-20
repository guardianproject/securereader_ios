//
//  SCRManageFeedsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-29.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFeedListViewController.h"
#import "Ono.h"
#import "YapDatabase.h"
#import "YapDatabaseFullTextSearch.h"
#import "YapDatabaseSearchQueue.h"
#import <YapDatabaseSearchResultsViewTransaction.h>
#import "SCRDatabaseManager.h"
#import "YapDatabaseView.h"
#import "SCRFeedListCell.h"
#import "SCRFeed.h"
#import "SCRFeedViewController.h"
#import "SCRFeedFetcher.h"
#import "SCRNavigationController.h"
#import "SCRApplication.h"
#import "SCRSettings.h"
#import "SCRFeedTableDelegate.h"
#import "SCRFeedSearchTableDelegate.h"
#import "SCRFeedShareViewController.h"
#import "SCRAppDelegate.h"

#define WEB_SEARCH_URL_FORMAT @"http://securereader.guardianproject.info/opml/find.php?lang=%1$@&term=%2$@"

@interface SCRFeedListViewController ()
@property BOOL isInSearchMode;
@property UIActivityIndicatorView *searchModeSpinner;

@property (nonatomic, strong) SCRFeedTableDelegate *subscribedTableDelegate;
@property (nonatomic, strong) SCRFeedTableDelegate *allTableDelegate;
@property (nonatomic, strong) SCRFeedSearchTableDelegate *searchTableDelegate;

@property int segmentedControlDesignHeight;
@property int trendingViewDesignHeight;
@property int searchBarDesignHeight;

@property (nonatomic, strong) NSMutableArray *feedsToAdd;

@end

@implementation SCRFeedListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"SCRFeedListCell" bundle:nil];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];

    self.subscribedTableDelegate = [[SCRFeedTableDelegate alloc] initWithTableView:self.tableView viewName:kSCRSubscribedFeedsViewName delegate:self];
    self.allTableDelegate = [[SCRFeedTableDelegate alloc] initWithTableView:self.tableView viewName:kSCRAllFeedsViewName delegate:self];
    self.allTableDelegate.showDescription = YES;
    [self.subscribedTableDelegate setActive:YES];

    self.searchTableDelegate = [[SCRFeedSearchTableDelegate alloc] initWithTableView:self.searchDisplayController.searchResultsTableView viewName:kSCRAllFeedsSearchViewName delegate:self];
    self.searchTableDelegate.showDescription = YES;
    [self.searchTableDelegate setActive:YES];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    self.segmentedControlDesignHeight = self.segmentedControlHeightConstraint.constant;
    self.trendingViewDesignHeight = self.trendingViewHeightConstraint.constant; // Save this for later use in animation
    self.searchBarDesignHeight = self.searchBarHeightConstraint.constant;
    
    [self hideTrendingView:NO];
    [self showShareBarButton:YES];
    
    // Hide empty rows at end of table
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.searchDisplayController.searchResultsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    // Prevent search bar from using black tint
    self.searchBar.backgroundImage = [[UIImage alloc] init];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (BOOL) exploring
{
    return self.segmentedControl.selectedSegmentIndex == 1;
}

#pragma mark - UISearchBarDelegate Methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self animateTrendingViewToHeight:0 andSearchBarTo:self.searchBarDesignHeight andSegmentedControlTo:0];
    [self.searchTableDelegate clearSearchResults];
    return YES;
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if (self.feedsToAdd != nil)
    {
        for (SCRFeed *feed in self.feedsToAdd)
        {
            [[SCRAppDelegate sharedAppDelegate] setFeed:feed subscribed:YES];
        }
        self.feedsToAdd = nil;
    }
    
    self.isInSearchMode = NO;
    searchBar.text = @"";
    [self showTrendingView];
    [searchBar endEditing:YES];
    [self.segmentedControl setSelectedSegmentIndex:0];
    [self segmentedControlValueChanged:self.segmentedControl];
}

-(void)hideTrendingView:(BOOL)hideSegmentedControl
{
    [self animateTrendingViewToHeight:0 andSearchBarTo:0 andSegmentedControlTo:(hideSegmentedControl ? 0 : self.segmentedControlDesignHeight)];
}

-(void)showTrendingView
{
    [self animateTrendingViewToHeight:([self exploring] ? self.trendingViewDesignHeight : 0) andSearchBarTo:([self exploring] ? self.searchBarDesignHeight : 0) andSegmentedControlTo:self.segmentedControlDesignHeight];
}

-(void)animateTrendingViewToHeight:(int)height andSearchBarTo:(int)heightSearchBar andSegmentedControlTo:(int)segmentedControlHeight
{
    [self.view layoutIfNeeded];
    self.segmentedControlHeightConstraint.constant = segmentedControlHeight;
    self.trendingViewHeightConstraint.constant = height;
    self.searchBarHeightConstraint.constant = heightSearchBar;
    [UIView animateWithDuration:.4
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished){
                     }];

}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isInSearchMode)
        {
            [self hideSearchBarSpinner];
            searchBar.text = @"";
            [self showTrendingView];
            [self.segmentedControl setSelectedSegmentIndex:0];
            [self segmentedControlValueChanged:self.segmentedControl];
        }
    });
}

- (void) showSearchBarSpinner
{
    if (self.searchModeSpinner == nil)
    {
        self.searchModeSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    CGFloat size = self.searchBar.frame.size.height;
    self.searchModeSpinner.frame = CGRectMake(0, 0, size, size);
    [self.searchBar addSubview:self.searchModeSpinner];
    [self.searchModeSpinner startAnimating];

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1,1), NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.searchBar setImage:blank
            forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
}

- (void) hideSearchBarSpinner
{
    if (self.searchModeSpinner != nil)
    {
        [self.searchModeSpinner removeFromSuperview];
        [self.searchBar setImage:nil
                forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.isInSearchMode = YES;
    [self.searchTableDelegate performSearchWithString:[searchBar text]];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    // Use this for real-time search of local feeds, currently disabled by design
    // [self searchLocalFeeds:searchString];
    return NO;
}

- (void)didStartSearch
{
    [self showSearchBarSpinner];
}

- (void)didFinishSearch
{
    [self hideSearchBarSpinner];
}

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath delegate:(SCRYapDatabaseTableDelegate *)delegate
{
    [delegate.tableView deselectRowAtIndexPath:indexPath animated:YES];

    SCRFeed *feed = (SCRFeed *)[delegate itemForIndexPath:indexPath];
    if (feed == nil)
    {
        return;
    }
    
    if (delegate == self.subscribedTableDelegate)
    {
        // Tap on a feed we are following, open up feed
        SCRFeedViewController *feedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"feedViewController"];
        [feedViewController setFeedViewType:SCRFeedViewTypeFeed feed:feed];
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = backItem;
        [self.navigationController pushViewController:feedViewController animated:YES];
    }
    else if (delegate == self.searchTableDelegate)
    {
        if (self.feedsToAdd == nil)
            self.feedsToAdd = [NSMutableArray array];
        if ([self.feedsToAdd containsObject:feed])
            [self.feedsToAdd removeObject:feed];
        else
            [self.feedsToAdd addObject:feed];
        [delegate.tableView beginUpdates];
        [delegate.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [delegate.tableView endUpdates];
    }
    else
    {
        [[SCRAppDelegate sharedAppDelegate] setFeed:feed subscribed:!feed.subscribed];
    }
}

- (void)configureCell:(UITableViewCell *)cell item:(NSObject *)item delegate:(SCRYapDatabaseTableDelegate *)delegate
{
    SCRFeedListCell *feedListCell = (SCRFeedListCell *)cell;
    if (delegate == self.subscribedTableDelegate)
    {
        feedListCell.rightUtilityButtons = [self rightButtonsFollowing];
        feedListCell.iconViewWidthConstraint.constant = 20;
        [feedListCell.iconView setHidden:YES];
    }
    else if (delegate == self.searchTableDelegate)
    {
        feedListCell.rightUtilityButtons = [self rightButtonsExplore];
        feedListCell.iconViewWidthConstraint.constant = 70;
        if ([self.feedsToAdd containsObject:item])
            [feedListCell.iconView setImage:[UIImage imageNamed:@"ic_toggle_selected"]];
        else
            [feedListCell.iconView setImage:[UIImage imageNamed:@"ic_toggle_add"]];
        [feedListCell.iconView setHidden:NO];
    }
    else
    {
        feedListCell.rightUtilityButtons = [self rightButtonsExplore];
        feedListCell.iconViewWidthConstraint.constant = 70;
        if ([(SCRFeed*)item subscribed])
            [feedListCell.iconView setImage:[UIImage imageNamed:@"ic_toggle_selected"]];
        else
            [feedListCell.iconView setImage:[UIImage imageNamed:@"ic_toggle_add"]];
        [feedListCell.iconView setHidden:NO];
    }
    feedListCell.delegate = self;
}

- (NSArray *)rightButtonsFollowing
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SCRSwipeUtilityButtons" owner:self options:nil];
    [rightUtilityButtons addObject:[objects objectAtIndex:1]]; // Unfollow
    [rightUtilityButtons addObject:[objects objectAtIndex:0]]; // Delete
    return rightUtilityButtons;
}

- (NSArray *)rightButtonsExplore
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SCRSwipeUtilityButtons" owner:self options:nil];
    [rightUtilityButtons addObject:[objects objectAtIndex:0]]; // Delete
    return rightUtilityButtons;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    
    // Find table view
    //
    id view = [cell superview];
    while (view && [view isKindOfClass:[UITableView class]] == NO) {
        view = [view superview];
    }
    UITableView *tableView = (UITableView *)view;
    
    NSIndexPath *indexPath = [tableView indexPathForCell:cell];
    if (indexPath != nil)
    {
        SCRYapDatabaseTableDelegate *tableDelegate = (SCRYapDatabaseTableDelegate *)tableView.dataSource;
        SCRFeed *feed = (SCRFeed *)[tableDelegate itemForIndexPath:indexPath];
        if (feed != nil)
        {
            UIView *selectedButton = [cell.rightUtilityButtons objectAtIndex:index];
            
            if (tableDelegate == self.subscribedTableDelegate)
            {
                if ([@"delete" isEqualToString:selectedButton.restorationIdentifier])
                {
                    [[SCRAppDelegate sharedAppDelegate] setFeed:feed subscribed:NO];
                    if (feed.userAdded)
                        [[SCRAppDelegate sharedAppDelegate] removeFeed:feed];
                }
                else if ([@"unfollow" isEqualToString:selectedButton.restorationIdentifier])
                {
                    [[SCRAppDelegate sharedAppDelegate] removeFeed:feed];
                }
            }
            else
            {
                if ([@"delete" isEqualToString:selectedButton.restorationIdentifier])
                {
                    [[SCRAppDelegate sharedAppDelegate] removeFeed:feed];
                }
            }
        }
    }
}

- (IBAction)segmentedControlValueChanged:(id)sender {
    
    [self.subscribedTableDelegate setActive:![self exploring]];
    [self.allTableDelegate setActive:[self exploring]];
    [self showTrendingView];
    [self showShareBarButton:![self exploring]];
}

- (void) showShareBarButton:(BOOL) show
{
    if (show)
    {
        UIBarButtonItem *btnShare = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
        [self.navigationItem setRightBarButtonItem:btnShare];
    }
    else
    {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (void)share:(id)sender
{
    SCRFeedShareViewController *feedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"feedShareViewController"];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
    [self.navigationController pushViewController:feedViewController animated:YES];
}

@end
