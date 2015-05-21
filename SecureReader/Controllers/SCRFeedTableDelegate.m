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
#import "SCRFeedIconFetcher.h"
#import "SCRAppDelegate.h"

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
    
    if (feed.feedImage) {
        cell.imageView.image = feed.feedImage;
    } else {
        NSURLSessionConfiguration *sessionConfiguration = [SCRAppDelegate sharedAppDelegate].torManager.currentConfiguration;
        SCRFeedIconFetcher *iconFetcher = [[SCRFeedIconFetcher alloc] initWithSessionConfiguration:sessionConfiguration];
        NSURL *url = feed.htmlURL;
        if (!url) {
            url = feed.xmlURL;
        }
        if (!url) {
            url = feed.sourceURL;
        }
        [iconFetcher fetchIconForURL:url completionQueue:dispatch_get_main_queue() completion:^(UIImage *image, NSError *error) {
            if (image) {
                feed.feedImage = image;
                cell.imageView.image = image;
                [cell setNeedsLayout];
            }
        }];
    }
}

@end
