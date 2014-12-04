//
//  SCRSideMenuViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-03.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRSideMenuViewController.h"
#import "YapDatabase.h"
#import "SCRDatabaseManager.h"
#import "YapDatabaseView.h"
#import "SCRMenuItemWithCountCell.h"
#import "SCRFeed.h"

@interface SCRSideMenuViewController ()

// Prototype cells for height calculation
@property (nonatomic, strong) UITableViewCell *prototypeCellButtonOptions;
@property (nonatomic, strong) SCRMenuItemWithCountCell *prototypeCellWithCount;

@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
@property (nonatomic, strong, readonly) NSString *yapViewName;

@end

@implementation SCRSideMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _yapViewName = [SCRDatabaseManager sharedInstance].allFeedsViewName;
    [self setupMappings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (NSString *) getCellIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"cellWithCount";
    if (indexPath.section == 0 && indexPath.row == 0)
    {
        cellIdentifier = @"cellButtonOptions";
    }
    return cellIdentifier;
}

- (UITableViewCell *) getPrototypeForIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self getCellIdentifierForIndexPath:indexPath];
    if ([cellIdentifier compare:@"cellButtonOptions"] == NSOrderedSame)
    {
        if (!self.prototypeCellButtonOptions)
            self.prototypeCellButtonOptions = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        return self.prototypeCellButtonOptions;
    }
    else
    {
        // No photos
        if (!self.prototypeCellWithCount)
            self.prototypeCellWithCount = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        return self.prototypeCellWithCount;
    }
}

#pragma mark UITableViewDelegate methods

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)feedSectionOffset
{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    NSInteger numberOfSections = [self.mappings numberOfSections];
    return 1 + numberOfSections;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 1;
    NSInteger numberOfRows = [self.mappings numberOfItemsInSection:section - [self feedSectionOffset]];
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self getCellIdentifierForIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView
                         dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if ([cell isKindOfClass:[SCRMenuItemWithCountCell class]])
    {
        SCRFeed *feed = [self itemForIndexPath:indexPath];
        if (feed != nil)
            [self configureCellWithCount:(SCRMenuItemWithCountCell *)cell forItem:feed];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *prototype = [self getPrototypeForIndexPath:indexPath];
    [prototype layoutIfNeeded];
    CGSize size = [prototype.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height+1;
}

- (SCRFeed *) itemForIndexPath:(NSIndexPath *) indexPath
{
    __block SCRFeed *item = nil;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSIndexPath *feedIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - [self feedSectionOffset]];
        item = [[transaction extension:self.yapViewName] objectAtIndexPath:feedIndexPath withMappings:self.mappings];
    }];
    return item;
}

- (void)configureCellWithCount:(SCRMenuItemWithCountCell *)cell forItem:(SCRFeed *)item
{
    cell.titleView.text = item.title;
}

#pragma mark YapDatabase

- (void) setupMappings {
    self.readConnection = [[SCRDatabaseManager sharedInstance].database newConnection];
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewName];
    
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
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }
    
    [self.tableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index + [self feedSectionOffset]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index + [self feedSectionOffset]]
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
        
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section + [self feedSectionOffset]];
        newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section + [self feedSectionOffset]];
        
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



@end
