//
//  SRMainViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeedViewController.h"
#import "SCRItem.h"
#import "SCRItemView.h"
#import "SCRFeedFetcher.h"
#import "YapDatabase.h"
#import "SCRDatabaseManager.h"
#import "YapDatabaseView.h"
#import "SCRItemViewController.h"
#import "SCRItemViewControllerSegue.h"
#import "SCRAppDelegate.h"
#import "NSFormatter+SecureReader.h"
#import "SCRNavigationController.h"
#import "SCRItemTableDelegate.h"

@interface SCRFeedViewController ()
@property (nonatomic, strong) SCRItemTableDelegate *itemsTableDelegate;
@property (strong,nonatomic) SCRItemViewController *itemViewController;
@property (nonatomic) SCRFeedViewType currentType;
@property (nonatomic, strong) SCRFeed *currentFeed;
@end

@implementation SCRFeedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [(SCRNavigationController *)self.navigationController registerScrollViewForHideBars:self.tableView];
    [self.itemsTableDelegate setActive:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.itemsTableDelegate setActive:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO];
}

- (void) setFeedViewType:(SCRFeedViewType)type feed:(SCRFeed *)feed
{
    switch (type) {
        case SCRFeedViewTypeAllFeeds:
            self.navigationItem.title = NSLocalizedString(@"FeedList.Navbar.AllFeeds", @"Navbar title for all feeds");
            break;
            
        case SCRFeedViewTypeFavorites:
            self.navigationItem.title = NSLocalizedString(@"FeedList.Navbar.Favorites", @"Navbar title for favorites");
            break;
            
        case SCRFeedViewTypeFeed:
            self.navigationItem.title = feed.title;
            break;
            
        case SCRFeedViewTypeReceived:
            self.navigationItem.title = NSLocalizedString(@"FeedList.Navbar.Received", @"Navbar title for received items");
            break;
            
        default:
            self.navigationItem.title = NSLocalizedString(@"FeedList.Navbar.Feed", @"Navbar default title for items list");
            break;
    }

    self.currentType = type;
    self.currentFeed = feed;

    NSString *viewName = kSCRAllFeedItemsUngroupedViewName;
    if (type == SCRFeedViewTypeFavorites)
        viewName = kSCRFavoriteFeedItemsViewName;
    else if (type == SCRFeedViewTypeReceived)
        viewName = kSCRReceivedFeedItemsViewName;
    else if (type == SCRFeedViewTypeFeed)
        viewName = kSCRAllFeedItemsViewName;
    
    self.itemsTableDelegate = [[SCRItemTableDelegate alloc] initWithTableView:self.tableView viewName:viewName filter:feed delegate:self];
    [self.itemsTableDelegate setActive:YES];
}

- (SCRItem *) itemForIndexPath:(NSIndexPath *) indexPath
{
    return (SCRItem *)[self.itemsTableDelegate itemForIndexPath:indexPath];
}

#pragma mark SCRYapDatabaseTableDelegateDelegate methods

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath delegate:(SCRYapDatabaseTableDelegate *)delegate
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    //if (self.itemViewController == nil)
    {
         self.itemViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"itemView"];
    }
    [self.itemViewController setDataView:self withStartAt:indexPath];
    SCRItemViewControllerSegue *segue = [[SCRItemViewControllerSegue alloc] initWithIdentifier:@"" source:self destination:self.itemViewController];
    [self prepareForSegue:segue sender:self];
    [segue perform];
}

@end
