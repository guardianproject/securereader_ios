//
//  SCRItemTableDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2015-02-24.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRItemTableDelegate.h"
#import "SCRItem.h"
#import "SCRItemView.h"
#import "NSFormatter+SecureReader.h"
#import "UIImageView+AFNetworking.h"
#import "SCRDatabaseManager.h"
#import "SCRItemTagCell.h"
#import "SCRMediaItem.h"
#import "SCRAppDelegate.h"
#import "SCRSettings.h"

@interface SCRItemTableDelegate()
@property (nonatomic, weak) SCRFeed *filter;
@property (nonatomic) NSTimer *updateTimeStampTimer;
@property (nonatomic, strong) SCRItemTagCell *cellTagPrototype;
@end

@implementation SCRItemTableDelegate

- (id)initWithTableView:(UITableView *)tableView viewName:(NSString*)viewName filter:(SCRFeed *)feed delegate:(id<SCRYapDatabaseTableDelegateDelegate>)delegate
{
    self = [super initWithTableView:tableView viewName:viewName delegate:delegate];
    if (self != nil)
    {
        self.filter = feed;
    }
    return self;
}

- (void) registerCellTypesInTable:(UITableView *)tableView
{
    UINib *nib = [UINib nibWithNibName:@"SCRItemCellNoPhotos" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"cellNoPhotos"];
    nib = [UINib nibWithNibName:@"SCRItemCellLandscapePhotos" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"cellLandscapePhotos"];
}

- (NSString *)identifierForItem:(NSObject *)item
{
    SCRItem *nativeItem = (SCRItem*)item;
    NSString *cellIdentifier = @"cellNoPhotos";
    //if (nativeItem.thumbnailURL) {
        cellIdentifier = @"cellLandscapePhotos";
    //}
    return cellIdentifier;
}

- (void)configureCell:(UITableViewCell *)genericcell forItem:(NSObject *)genericitem
{
    SCRItemView *cell = (SCRItemView *)genericcell;
    SCRItem *item = (SCRItem *)genericitem;

    // Store item pointer
    cell.item = item;
    
    cell.titleView.text = item.title;
    cell.sourceView.labelSource.text = [item.linkURL host];
    cell.sourceView.labelDate.text = [[NSFormatter scr_sharedIntervalFormatter] stringForTimeIntervalFromDate:[NSDate date] toDate:item.publicationDate];
    [cell.mediaCollectionView setItem:item];
    
    // If we have a filter, i.e. we are showing a single feed, show tags as well
    //
    if (cell.tagCollectionView != nil)
    {
        if (self.filter != nil)
        {
            UINib *nib = [UINib nibWithNibName:@"SCRItemTagCell" bundle:nil];
            [cell.tagCollectionView registerNib:nib forCellWithReuseIdentifier:@"cellTag"];
            if (self.cellTagPrototype == nil)
                self.cellTagPrototype = [[nib instantiateWithOwner:nil options:nil] objectAtIndex:0];
            cell.tagCollectionView.delegate = self;
            cell.tagCollectionView.dataSource = self;
        }
        else
        {
            // Collapse the tag view
            cell.tagCollectionViewHeightConstraint.constant = 0;
            cell.tagCollectionViewBottomConstraint.constant = 0;
            cell.tagCollectionView.delegate = nil;
            cell.tagCollectionView.dataSource = nil;
        }
    }
}

- (void)onCellConfigured:(UITableViewCell *)cell forItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
    {
        BOOL download = ([self isActive] && [SCRSettings downloadMedia]);
        [((SCRItemView *)cell).mediaCollectionView createThumbnails:download completion:nil];
    }
}


- (void)createMappings
{
    self.yapMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        if (self.filter != nil)
        {
            return [group isEqualToString:[self.filter yapKey]];
        }
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewName];
}

- (void)setActive:(BOOL)active
{
    [super setActive:active];
    if (active)
    {
        if (_updateTimeStampTimer != nil)
            [_updateTimeStampTimer invalidate];
        _updateTimeStampTimer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(updateTimeStampTimerDidFire) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_updateTimeStampTimer forMode:NSRunLoopCommonModes];
    }
    else
    {
        if (_updateTimeStampTimer != nil)
            [_updateTimeStampTimer invalidate];
        _updateTimeStampTimer = nil;
    }
}

- (void)updateTimeStampTimerDidFire
{
    NSArray *visibleCells = [self.tableView visibleCells];
    for (SCRItemView *cell in visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSObject *item = [self itemForIndexPath:indexPath];
        [self configureCell:cell forItem:item];
        [cell setNeedsLayout];
    }
}

- (SCRItem *)itemFromTagCollectionView:(UICollectionView *)collectionView
{
    id view = [collectionView superview];
    while (view && [view isKindOfClass:[UITableViewCell class]] == NO) {
        view = [view superview];
    }
    SCRItemView *parentCell = (SCRItemView *)view;
    return (SCRItem *)parentCell.item;
}

- (void)configureTagCell:(SCRItemTagCell *)cell forCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath
{
    SCRItem *item = [self itemFromTagCollectionView:collectionView];
    NSString *tag = [item.tags objectAtIndex:indexPath.row];
    cell.labelName.text = [@"#" stringByAppendingString:tag];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    SCRItem *item = [self itemFromTagCollectionView:collectionView];
    return item.tags.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SCRItemTagCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellTag" forIndexPath:indexPath];
    [self configureTagCell:cell forCollectionView:collectionView indexPath:indexPath];
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    SCRItemTagCell *cell = self.cellTagPrototype;
    [self configureTagCell:cell forCollectionView:collectionView indexPath:indexPath];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size;
}

// -------------------------------------------------------------------------------
//	loadImagesForOnscreenRows
//  This method is used in case the user scrolled into a set of cells that don't
//  have their media loaded yet.
// -------------------------------------------------------------------------------
- (void)loadMediaForOnscreenRows
{
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    if (visiblePaths != nil)
    {
        for (NSIndexPath *indexPath in visiblePaths)
        {
            SCRItemView *cell = (SCRItemView*)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.mediaCollectionView createThumbnails:[SCRSettings downloadMedia] completion:nil];
        }
    }
}

@end
