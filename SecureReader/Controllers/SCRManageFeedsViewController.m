//
//  SCRManageFeedsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-29.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRManageFeedsViewController.h"
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

@interface SCRManageFeedsViewController ()
@property BOOL isInSearchMode;
@property UIActivityIndicatorView *searchModeSpinner;
@property AFHTTPSessionManager *sessionManager;

// Prototype cells for height calculation
@property (nonatomic, strong) SCRFeedListCell *prototypeCellFeed;
@property (nonatomic, strong) SCRFeedListCell *prototypeCellFeedSearch;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *searchMappings;
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
@property (nonatomic, strong) YapDatabaseConnection *searchReadConnection;
@property (nonatomic, strong, readonly) NSString *yapViewName;
@property (nonatomic, strong, readonly) NSString *yapSearchViewName;
@property (nonatomic, strong) YapDatabaseSearchQueue *searchQueue;
@property NSArray *searchResults;
@property int trendingViewDesignHeight;

@end

@implementation SCRManageFeedsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"SCRFeedListCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];

    self.trendingViewDesignHeight = self.searchBarOffsetConstraint.constant; // Save this for later use in animation
    
    self.sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
    serializer.acceptableContentTypes  = [NSSet setWithObjects:@"application/opml",
                                          nil];
    self.sessionManager.responseSerializer = serializer;
    [self.sessionManager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
        return request;
    }];

    _yapViewName = [SCRDatabaseManager sharedInstance].allFeedsViewName;
    _yapSearchViewName = [SCRDatabaseManager sharedInstance].allFeedsSearchViewName;
    [self setupMappings];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate Methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self hideTrendingView];
    self.isInSearchMode = YES;
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return !self.isInSearchMode;
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.isInSearchMode = NO;
    
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [self showTrendingView];
}

-(void)hideTrendingView
{
    [self animateTrendingViewToHeight:0];
}

-(void)showTrendingView
{
    [self animateTrendingViewToHeight:(self.segmentedControl.selectedSegmentIndex == 1 ? 0 : self.trendingViewDesignHeight)];
}

-(void)animateTrendingViewToHeight:(int)height
{
    [self.view layoutIfNeeded];
    self.searchBarOffsetConstraint.constant = height;
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
    [self showSearchBarSpinner];
    
    NSString *urlString = [NSString stringWithFormat:@"http://securereader.guardianproject.info/opml/find.php?lang=en_US&term=%@", searchBar.text];
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
        
        NSError *error2 = nil;
        ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:responseObject error:&error2];
        if (error2) {
            return;
        }

        NSMutableArray *results = [[NSMutableArray alloc] init];
        [document enumerateElementsWithXPath:@"//body/outline" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            NSString *title = [[element attributes] objectForKey:@"text"];
            NSLog(@"Title is %@", title);
            [results addObject:title];
        }];
        self.searchResults = results;
        [self.searchDisplayController.searchResultsTableView reloadData];
    }];
    [dataTask resume];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    if (self.segmentedControl.selectedSegmentIndex == 1)
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
        return NO;
    }
    return NO;
}

#pragma mark UITableViewDelegate methods

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
        return [self.mappings numberOfSections];
    else if (self.segmentedControl.selectedSegmentIndex == 1)
        return [self.searchMappings numberOfSections];
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView)
    {
        if (self.segmentedControl.selectedSegmentIndex == 0)
            return 0; // TODO, 0 for now for "explore"...
        NSInteger numberOfRows = [self.mappings numberOfItemsInSection:section];
        return numberOfRows;
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1)
    {
        NSInteger numberOfRows = [self.searchMappings numberOfItemsInSection:section];
        return numberOfRows;
    }
    else
    {
        // Search
        if (self.searchResults == nil)
            return 0;
        return self.searchResults.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellFeed" forIndexPath:indexPath];
        if ([cell isKindOfClass:[SCRFeedListCell class]])
        {
            SCRFeedListCell *feedListCell = (SCRFeedListCell *)cell;
            SCRFeed *feed = [self itemForIndexPath:indexPath fromSearch:NO];
            if (feed != nil)
                [self configureCellWithCount:feedListCell forItem:feed showSwitch:(self.segmentedControl.selectedSegmentIndex == 1) tableView:tableView];
        }
        return cell;
    }
    else if (self.segmentedControl.selectedSegmentIndex == 1)
    {
        // Search my feeds
        NSString *cellIdentifier = @"cellFeed"; //[self getCellIdentifierForIndexPath:indexPath];
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if ([cell isKindOfClass:[SCRFeedListCell class]])
        {
            SCRFeedListCell *feedListCell = (SCRFeedListCell *)cell;
            SCRFeed *feed = [self itemForIndexPath:indexPath fromSearch:YES];
            if (feed != nil)
                [self configureCellWithCount:feedListCell forItem:feed showSwitch:YES tableView:tableView];
        }
        return cell;
    }
    else
    {
        SCRFeedListCell *cell = (SCRFeedListCell*)[self.tableView
                                 dequeueReusableCellWithIdentifier:@"cellFeed"];
        NSString *title = [self.searchResults objectAtIndex:indexPath.row];
        cell.titleView.text = title;
        cell.descriptionView.text = @"Description";
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView || (self.segmentedControl.selectedSegmentIndex == 1))
    {
        UITableViewCell *prototype = [self getPrototypeForTable:tableView andIndexPath:indexPath];
        prototype.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(prototype.bounds));
        SCRFeed *feed = [self itemForIndexPath:indexPath fromSearch:(self.searchDisplayController.searchResultsTableView == tableView)];
        if (feed != nil)
            [self configureCellWithCount:(SCRFeedListCell *)prototype forItem:feed showSwitch:(self.segmentedControl.selectedSegmentIndex == 1) tableView:tableView];
        [prototype setNeedsLayout];
        [prototype layoutIfNeeded];
        CGSize size = [prototype.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        NSLog(@"Measured item %@ to %f", feed.title, size.height);
        return size.height+1;
    }
    return 80;
}

- (SCRFeed *) itemForIndexPath:(NSIndexPath *)indexPath fromSearch:(BOOL)fromSearch
{
    __block SCRFeed *item = nil;
    if (fromSearch)
    {
        [self.searchReadConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            NSIndexPath *feedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
            item = [[transaction extension:self.yapSearchViewName] objectAtIndexPath:feedIndexPath withMappings:self.searchMappings];
        }];
    }
    else
    {
        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            NSIndexPath *feedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        item = [[transaction extension:self.yapViewName] objectAtIndexPath:feedIndexPath withMappings:self.mappings];
        }];
    };
    return item;
}

- (void)configureCellWithCount:(SCRFeedListCell *)cell forItem:(SCRFeed *)item showSwitch:(BOOL)showSwitch tableView:(UITableView*)tableView
{
    cell.titleView.text = item.title;
    cell.descriptionView.text = item.feedDescription;
    [cell setShowSwitch:showSwitch];
    if (showSwitch)
    {
        [cell.switchView setTag:(tableView == self.tableView ? 0 : 1)];
        [cell.switchView addTarget:self action:@selector(toggleFeedSubscription:) forControlEvents:UIControlEventValueChanged];
    }
    else
    {
        [cell.switchView removeTarget:self action:@selector(toggleFeedSubscription:) forControlEvents:UIControlEventValueChanged];
    }
}

- (void) toggleFeedSubscription:(id)sender
{
    // From http://stackoverflow.com/questions/1802707/detecting-which-uibutton-was-pressed-in-a-uitableview
    //
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = nil;
    BOOL inSearchTable = ([(UISwitch *)sender tag] != 0);
    if (!inSearchTable)
        indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    else
        indexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:buttonPosition];
    if (indexPath != nil)
    {
        SCRFeed *feed = [self itemForIndexPath:indexPath fromSearch:inSearchTable];
        if (feed != nil)
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Feed" message:[@"Toggle subscription for feed " stringByAppendingString:feed.title] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            alert.alertViewStyle = UIAlertViewStyleDefault;
            [alert show];
        }
    }
}

#pragma mark YapDatabase

- (void) setupMappings {
    self.readConnection = [[SCRDatabaseManager sharedInstance].database newConnection];
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewName];

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
        [self.mappings updateWithTransaction:transaction];
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
            [self.mappings updateWithTransaction:transaction];
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
    
    [[self.readConnection ext:self.yapViewName] getSectionChanges:&sectionChanges
                                                       rowChanges:&rowChanges
                                                 forNotifications:notifications
                                                     withMappings:self.mappings];
    
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
                    [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeInsert :
                {
                    [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
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
    [self.tableView reloadData];
    [self showTrendingView];
}

@end
