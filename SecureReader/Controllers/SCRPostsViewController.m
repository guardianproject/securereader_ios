//
//  SCRPostsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-02-24.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPostsViewController.h"
#import <AFNetworking.h>
#import "Ono.h"
#import "YapDatabase.h"
#import "YapDatabaseFullTextSearch.h"
#import "YapDatabaseSearchQueue.h"
#import <YapDatabaseSearchResultsViewTransaction.h>
#import "SCRDatabaseManager.h"
#import "YapDatabaseView.h"
#import "SCRItemView.h"
#import "SCRFeed.h"
#import "SCRFeedViewController.h"
#import "SCRFeedFetcher.h"
#import "SCRNavigationController.h"
#import "SCRApplication.h"
#import "SCRSettings.h"
#import "SCRItemTableDelegate.h"
#import <SWTableViewCell.h>

@interface SCRPostsViewController ()
@property (nonatomic, strong) SCRItemTableDelegate *postsTableDelegate;
@property (nonatomic, strong) SCRItemTableDelegate *draftsTableDelegate;
@end

@implementation SCRPostsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.postsTableDelegate = [[SCRItemTableDelegate alloc] initWithTableView:self.tableView viewName:kSCRAllFeedItemsUngroupedViewName filter:nil delegate:self];
    self.draftsTableDelegate = [[SCRItemTableDelegate alloc] initWithTableView:self.tableView viewName:kSCRAllFeedItemsUngroupedViewName filter:nil delegate:self];
    [self.postsTableDelegate setActive:YES];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (BOOL) draftMode
{
    return self.segmentedControl.selectedSegmentIndex == 1;
}

-(void)configureCell:(UITableViewCell *)cell item:(NSObject *)item delegate:(SCRYapDatabaseTableDelegate *)delegate
{
    SWTableViewCell *swCell = (SWTableViewCell *)cell;
    if (swCell != nil)
    {
        swCell.delegate = self;
        if (delegate == self.postsTableDelegate)
            swCell.rightUtilityButtons = [self rightButtonsPost];
        else
            swCell.rightUtilityButtons = [self rightButtonsDraft];
    }
}

- (NSArray *)rightButtonsDraft
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:getLocalizedString(@"Feed_List_Action_Unfollow", @"Unfollow")];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:getLocalizedString(@"Feed_List_Action_Delete", @"Delete")];
    
    return rightUtilityButtons;
}

- (NSArray *)rightButtonsPost
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.188f green:1.0f blue:0.188f alpha:1.0]
                                                title:getLocalizedString(@"Feed_List_Action_Follow", @"Follow")];
    return rightUtilityButtons;
}


- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    
    // Find table view
    //
    id view = [cell superview];
    while (view && [view isKindOfClass:[UITableView class]] == NO) {
        view = [view superview];
    }
    UITableView *tableView = (UITableView *)view;
    
    NSIndexPath *indexPath = [tableView indexPathForCell:cell];
    if (indexPath != nil)
    {
        SCRYapDatabaseTableDelegate *tableDelegate = (SCRYapDatabaseTableDelegate *)tableView.dataSource;
        SCRItem *item = (SCRItem*)[tableDelegate itemForIndexPath:indexPath];
        if (item != nil)
        {
            // Pretty sloppy this, allocating new objects for the comparison, but done seldom so...
            //
            if ([cell.rightUtilityButtons sw_isEqualToButtons:[self rightButtonsDraft]])
            {
                switch (index) {
                }
            }
            else if ([cell.rightUtilityButtons sw_isEqualToButtons:[self rightButtonsPost]])
            {
                switch (index) {
                }
            }
        }
    }
}

- (IBAction)segmentedControlValueChanged:(id)sender {
    [self.postsTableDelegate setActive:![self draftMode]];
    [self.draftsTableDelegate setActive:[self draftMode]];
}

@end
