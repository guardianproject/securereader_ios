//
//  SCRFeedTableDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2015-02-25.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFeedTableDelegate.h"
#import "SCRFeedListCell.h"
#import "SCRFeed.h"

@implementation SCRFeedTableDelegate

- (void) registerCellTypesInTable:(UITableView *)tableView
{
    UINib *nib = [UINib nibWithNibName:@"SCRFeedListCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];
    nib = [UINib nibWithNibName:@"SCRFeedListCellWithDescription" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"cellFeedWithDescription"];
}

- (NSString *)identifierForItem:(NSObject *)item
{
    if (self.showDescription)
        return @"cellFeedWithDescription";
    return @"cellFeed";
}

- (void)configureCell:(UITableViewCell *)genericcell forItem:(NSObject *)genericitem
{
    SCRFeedListCell *cell = (SCRFeedListCell *)genericcell;
    SCRFeed *feed = (SCRFeed *)genericitem;
    
    cell.titleView.text = feed.title;
    if (cell.descriptionView != nil)
        cell.descriptionView.text = feed.feedDescription;
}

@end
