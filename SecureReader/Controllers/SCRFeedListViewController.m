//
//  SCRManageFeedsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-29.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFeedListViewController.h"
#import <AFNetworking.h>
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
#import "SCRReader.h"
#import "SCRSettings.h"
#import "SCRFeedTableDelegate.h"
#import "SCRFeedSearchTableDelegate.h"
#import "SCRFeedShareViewController.h"

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

@end

@implementation SCRFeedListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"SCRFeedListCell" bundle:nil];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];

    self.subscribedTableDelegate = [[SCRFeedTableDelegate alloc] initWithTableView:self.tableView viewName:[SCRDatabaseManager sharedInstance].subscribedFeedsViewName delegate:self];
    self.allTableDelegate = [[SCRFeedTableDelegate alloc] initWithTableView:self.tableView viewName:[SCRDatabaseManager sharedInstance].allFeedsViewName delegate:self];
    self.allTableDelegate.showDescription = YES;
    [self.subscribedTableDelegate setActive:YES];

    self.searchTableDelegate = [[SCRFeedSearchTableDelegate alloc] initWithTableView:self.searchDisplayController.searchResultsTableView viewName:[SCRDatabaseManager sharedInstance].allFeedsSearchViewName delegate:self];
    self.searchTableDelegate.showDescription = YES;
    [self.searchTableDelegate setActive:YES];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    self.segmentedControlDesignHeight = self.segmentedControlHeightConstraint.constant;
    self.trendingViewDesignHeight = self.trendingViewHeightConstraint.constant; // Save this for later use in animation
    self.searchBarDesignHeight = self.searchBarHeightConstraint.constant;
    
    [self hideTrendingView:NO];
    [self showShareBarButton:YES];
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
    self.isInSearchMode = YES;
    [self.searchTableDelegate clearSearchResults];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return !self.isInSearchMode;
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.isInSearchMode = NO;
    searchBar.text = @"";
    [self showTrendingView];
    [searchBar endEditing:YES];
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
        [self hideSearchBarSpinner];
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
    if (delegate == self.subscribedTableDelegate)
    {
        SCRFeed *feed = (SCRFeed *)[self.subscribedTableDelegate itemForIndexPath:indexPath];
        if (feed != nil)
        {
            // Tap on a feed we are following, open up feed
            SCRFeedViewController *feedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"feedViewController"];
            [feedViewController setFeedViewType:SCRFeedViewTypeFeed feed:feed];
            UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            self.navigationItem.backBarButtonItem = backItem;
            [self.navigationController pushViewController:feedViewController animated:YES];
        }
    }
    else
    {
        SCRFeed *feed = (SCRFeed *)[delegate itemForIndexPath:indexPath];
        if (feed != nil)
        {
            [[SCRReader sharedInstance] setFeed:feed subscribed:!feed.subscribed];
        }
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
    else if ([(SCRFeed*)item subscribed])
    {
        feedListCell.rightUtilityButtons = [self rightButtonsExplore];
        feedListCell.iconViewWidthConstraint.constant = 70;
        [feedListCell.iconView setImage:[UIImage imageNamed:@"ic_action2_chat.png"]];
        [feedListCell.iconView setHidden:NO];
    }
    else
    {
        feedListCell.rightUtilityButtons = [self rightButtonsExplore];
        feedListCell.iconViewWidthConstraint.constant = 70;
        [feedListCell.iconView setImage:[UIImage imageNamed:@"ic_action2_share.png"]];
        [feedListCell.iconView setHidden:NO];
    }
    feedListCell.delegate = self;
}

- (NSArray *)rightButtonsFollowing
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:getLocalizedString(@"Feed_List_Action_Unfollow", @"Unfollow")];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:getLocalizedString(@"Feed_List_Action_Delete", @"Delete")];
    
    return rightUtilityButtons;
}

- (NSArray *)rightButtonsExplore
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:getLocalizedString(@"Feed_List_Action_Delete", @"Delete")];
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
        SCRFeed *feed = (SCRFeed *)[(SCRYapDatabaseTableDelegate *)tableView.dataSource itemForIndexPath:indexPath];
        if (feed != nil)
        {
            // Pretty sloppy this, allocating new objects for the comparison, but done seldom so...
            //
            if ([cell.rightUtilityButtons sw_isEqualToButtons:[self rightButtonsFollowing]])
            {
                switch (index) {
                    case 0:
                        [[SCRReader sharedInstance] setFeed:feed subscribed:NO];
                        break;
                    case 1:
                        {
                        [[SCRReader sharedInstance] removeFeed:feed];
                        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Feed" message:[@"Remove feed " stringByAppendingString:feed.title] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                        alert.alertViewStyle = UIAlertViewStyleDefault;
                        [alert show];
                        break;
                        }
                }
            }
            else if ([cell.rightUtilityButtons sw_isEqualToButtons:[self rightButtonsExplore]])
            {
                switch (index) {
                    case 0:
                        [[SCRReader sharedInstance] setFeed:feed subscribed:YES];
                        [cell hideUtilityButtonsAnimated:YES];
                        break;
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
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.navigationItem.rightBarButtonItem, btnShare, nil]];
    }
    else
    {
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObject:self.navigationItem.rightBarButtonItem]];
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
