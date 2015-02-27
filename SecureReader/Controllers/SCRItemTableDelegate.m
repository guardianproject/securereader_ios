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

@interface SCRItemTableDelegate()
@property (nonatomic, weak) SCRFeed *filter;
@property (nonatomic) NSTimer *updateTimeStampTimer;
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
    if (nativeItem.thumbnailURL) {
        cellIdentifier = @"cellLandscapePhotos";
    }
    return cellIdentifier;
}

- (void)configureCell:(UITableViewCell *)genericcell forItem:(NSObject *)genericitem
{
    SCRItemView *cell = (SCRItemView *)genericcell;
    SCRItem *item = (SCRItem *)genericitem;
    
    cell.titleView.text = item.title;
    cell.sourceView.labelSource.text = [item.linkURL host];
    cell.sourceView.labelDate.text = [[NSFormatter scr_sharedIntervalFormatter] stringForTimeIntervalFromDate:[NSDate date] toDate:item.publicationDate];
    cell.imageView.image = nil;
    if (item.thumbnailURL) {
        [cell.imageView setImageWithURL:item.thumbnailURL];
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

@end
