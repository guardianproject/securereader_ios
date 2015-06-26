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
#import "SCRItemViewController.h"
#import "SCRItemViewControllerSegue.h"

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
    
    UIBarButtonItem *btnAddPost = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(addPost:)];
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.navigationItem.rightBarButtonItem, btnAddPost, nil]];

    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    // Hide empty rows at end of table
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SCRSwipeUtilityButtons" owner:self options:nil];
    [rightUtilityButtons addObject:[objects objectAtIndex:0]]; // Delete
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
            UIView *selectedButton = [cell.rightUtilityButtons objectAtIndex:index];
            
            if (tableDelegate == self.draftsTableDelegate)
            {
                if ([@"edit" isEqualToString:selectedButton.restorationIdentifier])
                {
                    [self editDraftItem:item];
                }
                else if ([@"delete" isEqualToString:selectedButton.restorationIdentifier])
                {
                    UIAlertView *deleteAction = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Posts.Draft.Delete.Title", @"Title when deleting post")
                                                                           message:NSLocalizedString(@"Posts.Draft.Delete.Message", @"Message when deleting post")
                                                                          delegate:self
                                                                 cancelButtonTitle:NSLocalizedString(@"Posts.Draft.Delete.Cancel", @"Delete post action cancel")
                                                                 otherButtonTitles:NSLocalizedString(@"Posts.Draft.Delete.Delete", @"Delete post action delete"), nil];
                    [deleteAction showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                        if (buttonIndex == 1)
                            [self deleteDraftItem:item];
                    }];
                }
            }
        }
    }
}

- (IBAction)segmentedControlValueChanged:(id)sender {
    [self.postsTableDelegate setActive:![self draftMode]];
    [self.draftsTableDelegate setActive:[self draftMode]];
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

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath delegate:(SCRYapDatabaseTableDelegate *)delegate
{
    [delegate.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SCRPostItem *item = (SCRPostItem*)[delegate itemForIndexPath:indexPath];
    if (item != nil)
    {
        if (delegate == self.draftsTableDelegate)
        {
            [self editDraftItem:item];
        }
        else if (delegate == self.postsTableDelegate)
        {
            [self showPostItem:indexPath];
        }
    }
}

- (void)showPostItem:(NSIndexPath *)indexPath
{
    SCRItemViewController *itemViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"itemView"];
    [itemViewController setDataView:self withStartAt:indexPath];
    SCRItemViewControllerSegue *segue = [[SCRItemViewControllerSegue alloc] initWithIdentifier:@"" source:self destination:itemViewController];
    [self prepareForSegue:segue sender:self];
    [segue perform];
}

- (SCRItem *)itemForIndexPath:(NSIndexPath *)indexPath
{
    return (SCRItem*)[self.postsTableDelegate itemForIndexPath:indexPath];
}

@end
