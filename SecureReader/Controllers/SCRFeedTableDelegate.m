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
}

- (NSString *)identifierForItem:(NSObject *)item
{
    return @"cellFeed";
}

- (void)configureCell:(UITableViewCell *)genericcell forItem:(NSObject *)genericitem
{
    SCRFeedListCell *cell = (SCRFeedListCell *)genericcell;
    SCRFeed *feed = (SCRFeed *)genericitem;
    
    cell.titleView.text = feed.title;
    cell.descriptionView.text = feed.feedDescription;
}

@end
