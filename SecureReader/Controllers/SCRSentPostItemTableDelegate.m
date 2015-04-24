//
//  SCRSentPostItemTableDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRSentPostItemTableDelegate.h"
#import "SCRItemView.h"
#import "SCRPostItem.h"
#import "NSFormatter+SecureReader.h"

@implementation SCRSentPostItemTableDelegate

- (void) registerCellTypesInTable:(UITableView *)tableView
{
    UINib *nib = [UINib nibWithNibName:@"SCRItemCellLandscapePhotos" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"cellLandscapePhotos"];
}

- (NSString *)identifierForItem:(NSObject *)item
{
    return @"cellLandscapePhotos";
}

- (void)createMappings
{
    self.yapMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        if ([group isEqualToString:@"Sent"])
            return YES;
        return NO;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewName];
}

- (void)configureCell:(UITableViewCell *)genericcell forItem:(NSObject *)genericitem
{
    SCRItemView *cell = (SCRItemView *)genericcell;
    SCRPostItem *item = (SCRPostItem *)genericitem;
    
    // Store item pointer
    cell.item = item;
    
    cell.titleView.text = item.title;
    cell.sourceView.labelSource.text = @"";
    cell.sourceView.labelDate.text = [[NSFormatter scr_sharedIntervalFormatter] stringForTimeIntervalFromDate:[NSDate date] toDate:item.lastEdited];
    [cell.mediaCollectionView setItem:item];
}

@end
