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
#import "SCRAddPostViewController.h"
#import "SCRSentPostItemTableDelegate.h"
#import "SCRDraftPostItemTableDelegate.h"
#import "UIAlertView+SecureReader.h"

@interface SCRPostsViewController ()
@property (nonatomic, strong) SCRSentPostItemTableDelegate *postsTableDelegate;
@property (nonatomic, strong) SCRDraftPostItemTableDelegate *draftsTableDelegate;
@end

@implementation SCRPostsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.postsTableDelegate = [[SCRSentPostItemTableDelegate alloc] initWithTableView:self.tableView viewName:kSCRAllPostItemsViewName delegate:self];
    self.draftsTableDelegate = [[SCRDraftPostItemTableDelegate alloc] initWithTableView:self.tableView viewName:kSCRAllPostItemsViewName delegate:self];
    [self.postsTableDelegate setActive:YES];
    [self showAddPostBarButton:NO];
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
                                                title:getLocalizedString(@"Post_Draft_Action_Unfollow", @"Edit")];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:getLocalizedString(@"Post_Draft_Action_Delete", @"Delete")];
    
    return rightUtilityButtons;
}

- (NSArray *)rightButtonsPost
{
    return nil;
//    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
//    [rightUtilityButtons sw_addUtilityButtonWithColor:
//     [UIColor colorWithRed:0.188f green:1.0f blue:0.188f alpha:1.0]
//                                                title:getLocalizedString(@"Feed_List_Action_Follow", @"Follow")];
//    return rightUtilityButtons;
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
        SCRPostItem *item = (SCRPostItem*)[tableDelegate itemForIndexPath:indexPath];
        if (item != nil)
        {
            if ([cell.rightUtilityButtons sw_isEqualToButtons:[self rightButtonsDraft]])
            {
                switch (index) {
                    case 0:
                        [self editDraftItem:item];
                        break;
                    case 1:
                        {
                        UIAlertView *deleteAction = [[UIAlertView alloc] initWithTitle:getLocalizedString(@"Post_Draft_Delete_Alert_Title", @"Delete this post?")
                                                                               message:getLocalizedString(@"Post_Draft_Delete_Alert_Message", @"It will be permanently removed.")
                                                                              delegate:self
                                                                     cancelButtonTitle:getLocalizedString(@"Post_Draft_Delete_Alert_Cancel", @"Cancel")
                                                                     otherButtonTitles:getLocalizedString(@"Post_Draft_Delete_Alert_Delete", @"Delete"), nil];
                        [deleteAction showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                            if (buttonIndex == 1)
                                [self deleteDraftItem:item];
                        }];
                        }
                        break;
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
    [self showAddPostBarButton:[self draftMode]];
}

- (void) showAddPostBarButton:(BOOL) show
{
    if (show)
    {
        UIBarButtonItem *btnAddPost = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(addPost:)];
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.navigationItem.rightBarButtonItem, btnAddPost, nil]];
    }
    else
    {
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObject:self.navigationItem.rightBarButtonItem]];
    }
}

- (void)addPost:(id)sender
{
    SCRAddPostViewController *addPostViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"addPostViewController"];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
    [self.navigationController pushViewController:addPostViewController animated:YES];
}

- (void)editDraftItem:(SCRPostItem *)item
{
    SCRAddPostViewController *addPostViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"addPostViewController"];
    [addPostViewController editItem:item];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
    [self.navigationController pushViewController:addPostViewController animated:YES];
}

- (void)deleteDraftItem:(SCRPostItem *)item
{
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:item.yapKey inCollection:[[item class] yapCollection]];
    }];
}

@end
