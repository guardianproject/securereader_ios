//
//  SCRYapDatabaseTableDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2015-02-24.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRYapDatabaseTableDelegate.h"
#import "YapDatabase.h"
#import "YapDatabaseView.h"
#import "SCRDatabaseManager.h"

@interface SCRYapDatabaseTableDelegate ()
@property (nonatomic, strong) NSMutableDictionary *prototypes;
@property (nonatomic, strong) YapDatabaseConnection *readConnection;
@end

#define mustOverride() @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%s must be overridden in a subclass/category", __PRETTY_FUNCTION__] userInfo:nil]

@implementation SCRYapDatabaseTableDelegate

- (id)initWithTableView:(UITableView *)tableView viewName:(NSString *)viewName delegate:(id<SCRYapDatabaseTableDelegateDelegate>)delegate
{
    self = [super init];
    if (self != nil)
    {
        self.delegate = delegate;
        self.tableView = tableView;
        self.yapViewName = viewName;
        self.prototypes = [[NSMutableDictionary alloc] init];
        [self registerCellTypesInTable:tableView];
        [self setupMappings];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeYapConnections:) name:SCRRemoveYapConnectionsNotification object:[SCRDatabaseManager sharedInstance]];

    }
    return self;
}

- (YapDatabaseConnection*) readConnection {
    if (!_readConnection) {
        _readConnection = [[SCRDatabaseManager sharedInstance].database newConnection];
    }
    return _readConnection;
}

- (void) removeYapConnections:(NSNotification*)notification {
    self.readConnection = nil;
    self.yapMappings = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YapDatabaseModifiedNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCRRemoveYapConnectionsNotification object:[SCRDatabaseManager sharedInstance]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YapDatabaseModifiedNotification object:nil];
}

- (BOOL)isActive
{
    return (self.tableView.delegate == self);
}

- (void)setActive:(BOOL)active
{
    if (active)
    {
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
            [self.yapMappings updateWithTransaction:transaction];
        }];
        [self.tableView reloadData];
    }
}

- (void) registerCellTypesInTable:(UITableView *)tableView
{
    mustOverride();
}

- (NSString *)identifierForItem:(NSObject *)item
{
    mustOverride();
    return @"";
}

- (void)configureCell:(UITableViewCell *)cell forItem:(NSObject *)item
{
    mustOverride();
}

- (void)onCellConfigured:(UITableViewCell *)cell forItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath
{
    // Do nothing
}

- (void)createMappings
{
    self.yapMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewName];
}

- (UITableViewCell *)prototypeWithIdentifier:(NSString *)identifier
{
    if ([self.prototypes objectForKey:identifier] == nil)
    {
        [self.prototypes setObject:[self.tableView dequeueReusableCellWithIdentifier:identifier] forKey:identifier];
    }
    return [self.prototypes objectForKey:identifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [self.yapMappings numberOfSections];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.yapMappings numberOfItemsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *item = [self itemForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self identifierForItem:item] forIndexPath:indexPath];
    [self configureCell:cell forItem:item];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(configureCell:item:delegate:)])
        [self.delegate configureCell:cell item:item delegate:self];
    [self onCellConfigured:cell forItem:item atIndexPath:indexPath];
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *item = [self itemForIndexPath:indexPath];
    UITableViewCell *prototype = [self prototypeWithIdentifier:[self identifierForItem:item]];
    [self configureCell:prototype forItem:item];
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(configureCell:item:delegate:)])
        [self.delegate configureCell:prototype item:item delegate:self];
    [prototype setNeedsUpdateConstraints];
    [prototype updateConstraintsIfNeeded];
    prototype.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(prototype.bounds));
    [prototype setNeedsLayout];
    [prototype layoutIfNeeded];
    CGSize size = [prototype.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height+1;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (NSObject *) itemForIndexPath:(NSIndexPath *)indexPath
{
    __block NSObject *item = nil;
    [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        item = [[transaction extension:self.yapViewName] objectAtIndexPath:indexPath withMappings:self.yapMappings];
    }];
    return item;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(didSelectRowAtIndexPath:delegate:)])
        [self.delegate didSelectRowAtIndexPath:indexPath delegate:self];
}



#pragma mark YapDatabase

- (void) setupMappings {
    [self createMappings];
    
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
        [self.yapMappings updateWithTransaction:transaction];
    }];
    
    // And register for notifications when the database changes.
    // Our method will be invoked on the main-thread,
    // and will allow us to move our stable data-source from our existing state to an updated state.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.readConnection.database];
}

/**
 * Return the section offset where the actual data starts. This is so that you can have e.g. section 0
 * contain custom data and the rest contain data from the DB.
 */
- (int) tableSectionIndexOffset
{
    return 0;
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    
    NSArray *notifications = [self.readConnection beginLongLivedReadTransaction];
    
    // If the view isn't visible, we might decide to skip the UI animation stuff.
    if (!(self.tableView != nil && self.tableView.dataSource == self && self.tableView.window))
    {
        // Since we moved our databaseConnection to a new commit,
        // we need to update the mappings too.
        [self.readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
            [self.yapMappings updateWithTransaction:transaction];
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
                                                               withMappings:self.yapMappings];
    
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
                    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:(sectionChange.index + [self tableSectionIndexOffset])]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeInsert :
                {
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:(sectionChange.index + [self tableSectionIndexOffset])]
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
            
            indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section + [self tableSectionIndexOffset])];
            newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:(newIndexPath.section + [self tableSectionIndexOffset])];
            
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
}

// -------------------------------------------------------------------------------
//	loadMediaForOnscreenRows
//  This method is used in case the user scrolled into a set of cells that don't
//  have their media loaded yet.
// -------------------------------------------------------------------------------
- (void)loadMediaForOnscreenRows
{
}

#pragma mark - UIScrollViewDelegate

// -------------------------------------------------------------------------------
//	scrollViewDidEndDragging:willDecelerate:
//  Load images for all onscreen rows when scrolling is finished.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        [self loadMediaForOnscreenRows];
    }
}

// -------------------------------------------------------------------------------
//	scrollViewDidEndDecelerating:scrollView
//  When scrolling stops, proceed to load images for onscreen rows.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadMediaForOnscreenRows];
}

@end
