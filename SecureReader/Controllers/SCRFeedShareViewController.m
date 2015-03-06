//
//  SCRFeedShareViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-03-04.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFeedShareViewController.h"
#import "SCRDatabaseManager.h"
#import "SCRFeedTableDelegate.h"
#import "SCRFeed.h"
#import "SCRFeedListCell.h"

@interface SCRFeedShareViewController ()
@property (nonatomic, strong) SCRYapDatabaseTableDelegate *subscribedTableDelegate;
@property (nonatomic, strong) NSMutableArray *selectedFeeds;
@end

@implementation SCRFeedShareViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedFeeds = [NSMutableArray new];
    
    UINib *nib = [UINib nibWithNibName:@"SCRFeedListCell" bundle:nil];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];
    
    self.subscribedTableDelegate = [[SCRFeedTableDelegate alloc] initWithTableView:self.tableView viewName:[SCRDatabaseManager sharedInstance].subscribedFeedsViewName delegate:self];
    [self.subscribedTableDelegate setActive:YES];
    [self updateTitle];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void) updateTitle
{
    [self setTitle:[NSString stringWithFormat:@"%lu Selected", (unsigned long)self.selectedFeeds.count]];
}

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath delegate:(SCRYapDatabaseTableDelegate *)delegate
{
    [delegate.tableView deselectRowAtIndexPath:indexPath animated:YES];

    SCRFeed *feed = (SCRFeed *)[self.subscribedTableDelegate itemForIndexPath:indexPath];
    if (feed != nil)
    {
        if ([self.selectedFeeds containsObject:feed])
            [self.selectedFeeds removeObject:feed];
        else
            [self.selectedFeeds addObject:feed];
        [delegate.tableView beginUpdates];
        [delegate.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [delegate.tableView endUpdates];
    }
    [self updateTitle];
}

- (void)configureCell:(UITableViewCell *)cell item:(NSObject *)item delegate:(SCRYapDatabaseTableDelegate *)delegate
{
    SCRFeedListCell *feedListCell = (SCRFeedListCell *)cell;
    if ([self.selectedFeeds containsObject:(SCRFeed*)item])
    {
        [feedListCell.iconView setImage:[UIImage imageNamed:@"ic_action2_chat.png"]];
    }
    else
    {
        [feedListCell.iconView setImage:[UIImage imageNamed:@"ic_action2_share.png"]];
    }
}

- (IBAction)doShareAction:(id)sender
{
    NSString *textToShare = @"Share data goes here";
    NSURL *myWebsite = [NSURL URLWithString:@"http://www.guardianproject.info/"];
    NSArray *objectsToShare = @[textToShare, myWebsite];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    activityVC.excludedActivityTypes = excludeActivities;
    [self presentViewController:activityVC animated:YES completion:nil];
}

@end
