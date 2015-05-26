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
#import "SCRDatabaseManager.h"

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
        cell.imageView.image = [UIImage imageNamed:@"ic_feed_placeholder"];
    }
}

- (void)onCellConfigured:(UITableViewCell *)cell forItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath
{
    /** Fetch favicon if no image found or if it's been a while */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SCRFeed *feed = (SCRFeed *)item;
        
        //7 days ago
        NSDate *shortTimeAgo = [NSDate dateWithTimeIntervalSinceNow:-1*7*24*60*60];
        //30 days ago
        NSDate *longTimeAgo = [NSDate dateWithTimeIntervalSinceNow:-1*30*24*60*60];
        
        /**
         * Reason to check for a feed image
         * 1. Never checked before lastFetchedFeedImageDate == nil
         * 2. No feed Image and it's been 7 days
         * 3. Feed image exists but it's been 30 days
         */
        if ((!feed.feedImage && [feed.lastFetchedFeedImageDate compare:shortTimeAgo] == NSOrderedAscending) ||
            (feed.feedImage && [feed.lastFetchedFeedImageDate compare:longTimeAgo] == NSOrderedAscending) ||
            !feed.lastFetchedFeedImageDate) {
            
            //Save and update lastFetchedFeedImageDate
            [[SCRDatabaseManager sharedInstance].readWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                SCRFeed *fetchedFeed = [transaction objectForKey:feed.yapKey inCollection:[SCRFeed yapCollection]];
                if (fetchedFeed) {
                    fetchedFeed.lastFetchedFeedImageDate = [NSDate date];
                    [fetchedFeed saveWithTransaction:transaction];
                }
                else {
                    feed.lastFetchedFeedImageDate = [NSDate date];
                }
            }];
            
            // Get correct URL and Fetch feed icon
            NSURLSessionConfiguration *sessionConfiguration = [SCRAppDelegate sharedAppDelegate].torManager.currentConfiguration;
            SCRFeedIconFetcher *iconFetcher = [[SCRFeedIconFetcher alloc] initWithSessionConfiguration:sessionConfiguration];
            NSURL *url = feed.htmlURL;
            if (!url) {
                url = feed.xmlURL;
            }
            if (!url) {
                url = feed.sourceURL;
            }
            
            [iconFetcher fetchIconForURL:url completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(UIImage *image, NSError *error) {
                if (image) {
                    
                    //If possible save new icon to database
                    [[SCRDatabaseManager sharedInstance].readWriteConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                        SCRFeed *fetchedFeed = [transaction objectForKey:feed.yapKey inCollection:[SCRFeed yapCollection]];
                        
                        //Check if it's a database object. If not, update tableview in place (search view)
                        if (!fetchedFeed) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                feed.feedImage = image;
                                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                            });
                        } else {
                            fetchedFeed.feedImage = image;
                            [fetchedFeed saveWithTransaction:transaction];
                        }
                        
                        
                    }];
                }
            }];
        }
    });
    
}

@end
