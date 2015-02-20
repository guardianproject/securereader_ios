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

#define WEB_SEARCH_URL_FORMAT @"http://securereader.guardianproject.info/opml/find.php?lang=%1$@&term=%2$@"

@interface SCRFeedListViewController ()
@property BOOL isInSearchMode;
@property UIActivityIndicatorView *searchModeSpinner;
@property AFHTTPSessionManager *sessionManager;

// Prototype cells for height calculation
@property (nonatomic, strong) SCRFeedListCell *prototypeCellFeed;
@property (nonatomic, strong) SCRFeedListCell *prototypeCellFeedSearch;
@property (nonatomic, strong) YapDatabaseViewMappings *mappingsSubscribed;
@property (nonatomic, strong) YapDatabaseViewMappings *mappingsUnSubscribed;
@property (nonatomic, strong) YapDatabaseViewMappings *searchMappings;
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
@property (nonatomic, strong) YapDatabaseConnection *searchReadConnection;
@property (nonatomic, strong, readonly) NSString *yapViewNameSubscribed;
@property (nonatomic, strong, readonly) NSString *yapViewNameUnSubscribed;
@property (nonatomic, strong, readonly) NSString *yapSearchViewName;
@property (nonatomic, strong) YapDatabaseSearchQueue *searchQueue;
@property NSArray *searchResults;
@property int segmentedControlDesignHeight;
@property int trendingViewDesignHeight;
@property int searchBarDesignHeight;

@end

@implementation SCRFeedListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"SCRFeedListCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];

    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    self.segmentedControlDesignHeight = self.segmentedControlHeightConstraint.constant;
    self.trendingViewDesignHeight = self.trendingViewHeightConstraint.constant; // Save this for later use in animation
    self.searchBarDesignHeight = self.searchBarHeightConstraint.constant;
    
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
    serializer.acceptableContentTypes  = [NSSet setWithObjects:@"application/opml",
                                          nil];
    self.sessionManager.responseSerializer = serializer;
    [self.sessionManager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
        return request;
    }];

    _yapViewNameSubscribed = [SCRDatabaseManager sharedInstance].subscribedFeedsViewName;
    _yapViewNameUnSubscribed = [SCRDatabaseManager sharedInstance].unsubscribedFeedsViewName;
    _yapSearchViewName = [SCRDatabaseManager sharedInstance].allFeedsSearchViewName;
    [self setupMappings];
    [self hideTrendingView:NO];
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
    self.searchResults = nil;
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
    [self searchLocalFeeds:[searchBar text]];
    [self searchWebFeeds:[searchBar text]];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    // Use this for real-time search of local feeds, currently disabled by design
    // [self searchLocalFeeds:searchString];
    return NO;
}

#pragma mark UITableViewDelegate methods

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SCRFeed *feed = [self itemForIndexPath:indexPath inTable:tableView];
    if (feed != nil)
    {
        if (tableView == self.tableView && ![self exploring])
        {
            // Tap on a feed we are following, open up feed
            SCRFeedViewController *feedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"feedViewController"];
            [feedViewController setFeedViewType:SCRFeedViewTypeFeed feed:feed];
            UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            self.navigationItem.backBarButtonItem = backItem;
            [self.navigationController pushViewController:feedViewController animated:YES];
        }
        else
        {
            // Todo - need to figure out how to subscribe. Right now swipe and select "Follow".
            //[[SCRReader sharedInstance] setFeed:feed subscribed:!feed.subscribed];
        }
    }
}

#pragma mark - Table view data source

- (UITableViewCell *) getPrototypeForTable:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        if (!self.prototypeCellFeed)
            self.prototypeCellFeed = [tableView dequeueReusableCellWithIdentifier:@"cellFeed"];
        return self.prototypeCellFeed;
    }
    else
    {
        if (!self.prototypeCellFeedSearch)
            self.prototypeCellFeedSearch = [tableView dequeueReusableCellWithIdentifier:@"cellFeed"];
        return self.prototypeCellFeedSearch;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    if (sender == self.tableView)
    {
        if ([self exploring])
            return [self.mappingsUnSubscribed numberOfSections];
        return [self.mappingsSubscribed numberOfSections];
    }
    return 1 + [self.searchMappings numberOfSections];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView)
    {
        if ([self exploring])
            return [self.mappingsUnSubscribed numberOfItemsInSection:section];
        return [self.mappingsSubscribed numberOfItemsInSection:section];
    }
    else if (section == 0)
    {
        // Local search results in first section
        if (self.searchResults == nil)
            return 0;
        return self.searchResults.count;
    }
    else
    {
        NSInteger numberOfRows = [self.searchMappings numberOfItemsInSection:(section - 1)];
        return numberOfRows;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCRFeedListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellFeed" forIndexPath:indexPath];
    SCRFeed *feed = [self itemForIndexPath:indexPath inTable:tableView];
    [self configureCell:cell forFeed:feed tableView:tableView];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *prototype = [self getPrototypeForTable:tableView andIndexPath:indexPath];
    prototype.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(prototype.bounds));
    SCRFeed *feed = [self itemForIndexPath:indexPath inTable:tableView];
    [self configureCell:(SCRFeedListCell *)prototype forFeed:feed tableView:tableView];
    [prototype setNeedsLayout];
    [prototype layoutIfNeeded];
    CGSize size = [prototype.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height+1;
}

- (SCRFeed *) itemForIndexPath:(NSIndexPath *)indexPath fromView:(NSString *)view mapping:(YapDatabaseViewMappings *)mappings
{
    __block SCRFeed *item = nil;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSIndexPath *feedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        item = [[transaction extension:view] objectAtIndexPath:feedIndexPath withMappings:mappings];
    }];
    return item;
}

- (SCRFeed *) itemForIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)tableView
{
    SCRFeed *feed = nil;
    if (tableView == self.tableView)
    {
        if ([self exploring])
        {
            feed = [self itemForIndexPath:indexPath fromView:self.yapViewNameUnSubscribed mapping:self.mappingsUnSubscribed];
        }
        else
        {
            feed = [self itemForIndexPath:indexPath fromView:self.yapViewNameSubscribed mapping:self.mappingsSubscribed];
        }
    }
    else if (indexPath.section == 0)
    {
        // Local search results in first section
        feed = [self.searchResults objectAtIndex:indexPath.row];
    }
    else
    {
        // Search my feeds
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section - 1)];
        feed = [self itemForIndexPath:newIndexPath fromView:self.yapSearchViewName mapping:self.searchMappings];
    }
    return feed;
}

- (void)configureCell:(SCRFeedListCell *)cell forFeed:(SCRFeed *)feed tableView:(UITableView*)tableView
{
    cell.titleView.text = feed.title;
    cell.descriptionView.text = feed.feedDescription;
    if (tableView == self.tableView)
    {
        if ([self exploring])
        {
            cell.rightUtilityButtons = [self rightButtonsExplore];
            cell.delegate = self;
        }
        else
        {
            cell.rightUtilityButtons = [self rightButtonsFollowing];
            cell.delegate = self;
        }
    }
    else if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        if ([feed subscribed])
        {
            cell.rightUtilityButtons = [self rightButtonsExploreFollowed];
            cell.delegate = self;
        }
        else
        {
            cell.rightUtilityButtons = [self rightButtonsExplore];
            cell.delegate = self;
        }
    }
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
     [UIColor colorWithRed:0.188f green:1.0f blue:0.188f alpha:1.0]
                                                title:getLocalizedString(@"Feed_List_Action_Follow", @"Follow")];
    return rightUtilityButtons;
}

- (NSArray *)rightButtonsExploreFollowed
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.78f alpha:1.0]
                                                title:getLocalizedString(@"Feed_List_Action_Followed", @"Already Followed")];
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
        SCRFeed *feed = [self itemForIndexPath:indexPath inTable:tableView];
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

#pragma mark YapDatabase

- (void) setupMappings {
    self.readConnection = [[SCRDatabaseManager sharedInstance].database newConnection];
    
    self.mappingsSubscribed = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewNameSubscribed];
    
    self.mappingsUnSubscribed = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewNameUnSubscribed];

    self.searchMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapSearchViewName];
    
    // Freeze our databaseConnection on the current commit.
    // This gives us a snapshot-in-time of the database,
    // and thus a stable data source for our UI thread.
    [self.readConnection beginLongLivedReadTransaction];
    
    // Initialize our mappings.
    // Note that we do this after we've started our database longLived transaction.
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        
        // Calling this for the first time will initialize the mappings,
        // and will allow mappings to cache certain information
        // such as the counts for each section.
        [self.mappingsSubscribed updateWithTransaction:transaction];
        [self.mappingsUnSubscribed updateWithTransaction:transaction];
        [self.searchMappings updateWithTransaction:transaction];
    }];
    
    // And register for notifications when the database changes.
    // Our method will be invoked on the main-thread,
    // and will allow us to move our stable data-source from our existing state to an updated state.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.readConnection.database];
    [self.tableView reloadData];
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    
    NSArray *notifications = [self.readConnection beginLongLivedReadTransaction];
    
    // If the view isn't visible, we might decide to skip the UI animation stuff.
    if (!([self isViewLoaded] && self.view.window))
    {
        // Since we moved our databaseConnection to a new commit,
        // we need to update the mappings too.
        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
            [self.mappingsSubscribed updateWithTransaction:transaction];
        }];
        return;
    }
    
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    //
    // Note: the getSectionChanges:rowChanges:forNotifications:withMappings: method
    // automatically invokes the equivalent of [mappings updateWithTransaction:] for you.
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    if ([self exploring])
    {
        [[self.readConnection ext:self.yapViewNameUnSubscribed] getSectionChanges:&sectionChanges
                                                       rowChanges:&rowChanges
                                                 forNotifications:notifications
                                                     withMappings:self.mappingsUnSubscribed];
    }
    else
    {
        [[self.readConnection ext:self.yapViewNameSubscribed] getSectionChanges:&sectionChanges
                                                                     rowChanges:&rowChanges
                                                               forNotifications:notifications
                                                                   withMappings:self.mappingsSubscribed];
    }
    
    // No need to update mappings.
    // The above method did it automatically.
    
    if ([sectionChanges count] > 0 || [rowChanges count] > 0)
    {
        [self.tableView beginUpdates];
        for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
        {
            switch (sectionChange.type)
            {
                case YapDatabaseViewChangeDelete :
                {
                    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeInsert :
                {
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
            case YapDatabaseViewChangeMove:
            {
                break;
            }
            case YapDatabaseViewChangeUpdate:
            {
                break;
            }
        }
    }
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        NSIndexPath *indexPath = rowChange.indexPath;
        NSIndexPath *newIndexPath = rowChange.newIndexPath;
        
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section];
        
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
    }
    
    
    //Search
    //
    //
    //notifications = [self.searchReadConnection beginLongLivedReadTransaction];
    [[self.readConnection ext:self.yapSearchViewName] getSectionChanges:&sectionChanges
                                                       rowChanges:&rowChanges
                                                 forNotifications:notifications
                                                     withMappings:self.searchMappings];
    if ([sectionChanges count] > 0 || [rowChanges count] > 0)
    {
        UITableView *tableView = self.searchDisplayController.searchResultsTableView;
        [tableView beginUpdates];
        for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
        {
            switch (sectionChange.type)
            {
                case YapDatabaseViewChangeDelete :
                {
                    [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index + 1]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeInsert :
                {
                    [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index + 1]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeMove:
                {
                    break;
                }
                case YapDatabaseViewChangeUpdate:
                {
                    break;
                }
            }
        }
        
        for (YapDatabaseViewRowChange *rowChange in rowChanges)
        {
            NSIndexPath *indexPath = rowChange.indexPath;
            NSIndexPath *newIndexPath = rowChange.newIndexPath;
            
            indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section + 1];
            newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section + 1];
            
            switch (rowChange.type)
            {
                case YapDatabaseViewChangeDelete :
                {
                    [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeInsert :
                {
                    [tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeMove :
                {
                    [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    [tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeUpdate :
                {
                    [tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                          withRowAnimation:UITableViewRowAnimationNone];
                    break;
                }
            }
        }
        
        [tableView endUpdates];
    }

}

- (IBAction)segmentedControlValueChanged:(id)sender {
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        if ([self exploring])
            [self.mappingsUnSubscribed updateWithTransaction:transaction];
        else
            [self.mappingsSubscribed updateWithTransaction:transaction];
    }];
    [self.tableView reloadData];
    [self showTrendingView];
}

- (void)searchWebFeeds:(NSString *)searchString
{
    [self showSearchBarSpinner];
    
    NSString *urlString = [NSString stringWithFormat:WEB_SEARCH_URL_FORMAT, [SCRSettings getUiLanguage], searchString];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *dataTask = [self.sessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideSearchBarSpinner];
            NSLog(@"Error: %@", error);
        });
        
        if (error) {
            return;
        }
        NSAssert([responseObject isKindOfClass:[NSData class]], @"responseObject must be NSData!");
        if (![responseObject isKindOfClass:[NSData class]]) {
            return;
        }
        
        ONOXMLDocument *doc = [ONOXMLDocument XMLDocumentWithData:responseObject error:nil];
        if (doc != nil)
        {
            //TODO - handle errors
            self.searchResults = [SCRFeed feedsFromOPMLDocument:doc error:nil];
            [self.searchDisplayController.searchResultsTableView reloadData];
        };
    }];
    [dataTask resume];
}

- (void)searchLocalFeeds:(NSString *)searchString
{
    if (self.searchReadConnection == nil)
        self.searchReadConnection = [[SCRDatabaseManager sharedInstance].database newConnection];
    
    if (self.searchQueue == nil)
        self.searchQueue = [[YapDatabaseSearchQueue alloc] init];
    
    // Parse the text into a proper search query
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    
    NSArray *searchComponents = [searchString componentsSeparatedByCharactersInSet:whitespace];
    NSMutableString *query = [NSMutableString string];
    
    for (NSString *term in searchComponents)
    {
        if ([term length] > 0)
            [query appendString:@""];
        
        [query appendFormat:@"%@*", term];
    }
    
    NSLog(@"searchString(%@) -> query(%@)", searchString, query);
    [self.searchQueue enqueueQuery:query];
    
    [self.searchReadConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction)
     {
         [[transaction ext:_yapSearchViewName] performSearchWithQueue:self.searchQueue];
     }];
}


@end
