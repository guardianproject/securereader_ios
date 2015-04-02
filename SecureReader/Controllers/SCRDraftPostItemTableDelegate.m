//
//  SCRDraftPostItemTableDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRDraftPostItemTableDelegate.h"
#import "SCRPostItem.h"
#import "SCRPostItemCellDraft.h"

@implementation SCRDraftPostItemTableDelegate

- (void) registerCellTypesInTable:(UITableView *)tableView
{
    UINib *nib = [UINib nibWithNibName:@"SCRPostItemCellDraft" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"cellDraft"];
}

- (NSString *)identifierForItem:(NSObject *)item
{
    return @"cellDraft";
}

- (void)createMappings
{
    self.yapMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        if ([group isEqualToString:@"Drafts"])
            return YES;
        return NO;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewName];
}

- (void)configureCell:(UITableViewCell *)genericcell forItem:(NSObject *)genericitem
{
    SCRPostItemCellDraft *cell = (SCRPostItemCellDraft *)genericcell;
    SCRPostItem *item = (SCRPostItem *)genericitem;
    
    cell.item = item;
    
    cell.titleView.text = item.title;
    cell.textView.text = item.content;
    [cell.btnEdit addTarget:self action:@selector(editButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.btnDelete addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    //[cell.mediaCollectionView setItem:item];
    
    // If we have a filter, i.e. we are showing a single feed, show tags as well
    //
//    if (cell.tagCollectionView != nil)
//    {
//        if (self.filter != nil)
//        {
//            UINib *nib = [UINib nibWithNibName:@"SCRItemTagCell" bundle:nil];
//            [cell.tagCollectionView registerNib:nib forCellWithReuseIdentifier:@"cellTag"];
//            if (self.cellTagPrototype == nil)
//                self.cellTagPrototype = [[nib instantiateWithOwner:nil options:nil] objectAtIndex:0];
//            cell.tagCollectionView.delegate = self;
//            cell.tagCollectionView.dataSource = self;
//        }
//        else
//        {
//            // Collapse the tag view
//            cell.tagCollectionViewHeightConstraint.constant = 0;
//            cell.tagCollectionViewBottomConstraint.constant = 0;
//            cell.tagCollectionView.delegate = nil;
//            cell.tagCollectionView.dataSource = nil;
//        }
//    }
}

- (SCRPostItem *)itemFromSubView:(UIView *)subview
{
    id view = [subview superview];
    while (view && [view isKindOfClass:[UITableViewCell class]] == NO) {
        view = [view superview];
    }
    SCRPostItemCellDraft *parentCell = (SCRPostItemCellDraft *)view;
    return (SCRPostItem *)parentCell.item;
}

- (void)editButtonPressed:(id)sender
{
    if (self.delegate != nil && [self.delegate conformsToProtocol:@protocol(SCRDraftPostItemTableDelegateDelegate)])
    {
        id<SCRDraftPostItemTableDelegateDelegate> delegate = (id<SCRDraftPostItemTableDelegateDelegate>)self.delegate;
        if ([delegate respondsToSelector:@selector(editDraftItem:)])
            [delegate editDraftItem:[self itemFromSubView:sender]];
    }
}

- (void)deleteButtonPressed:(id)sender
{
    if (self.delegate != nil && [self.delegate conformsToProtocol:@protocol(SCRDraftPostItemTableDelegateDelegate)])
    {
        id<SCRDraftPostItemTableDelegateDelegate> delegate = (id<SCRDraftPostItemTableDelegateDelegate>)self.delegate;
        if ([delegate respondsToSelector:@selector(deleteDraftItem:)])
            [delegate deleteDraftItem:[self itemFromSubView:sender]];
    }
}

@end
