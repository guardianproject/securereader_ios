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
#import "SCRItemTagCell.h"
#import "SCRApplication.h"

@interface SCRDraftPostItemTableDelegate()
@property (nonatomic, strong) SCRItemTagCell *cellTagPrototype;
@end

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
    if (cell.titleView.text.length == 0)
        cell.titleView.text = getLocalizedString(@"Add_Post_Item_No_Title", @"(No title set)");
    cell.textView.text = item.content;
    if (cell.textView.text.length == 0)
        cell.textView.text = getLocalizedString(@"Add_Post_Item_No_Description", @"(No description set)");
    [cell.btnEdit addTarget:self action:@selector(editButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.btnDelete addTarget:self action:@selector(deleteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cell.mediaCollectionView setItem:item];

    if (item.tags != nil && item.tags.count > 0)
    {
        UINib *nib = [UINib nibWithNibName:@"SCRItemTagCell" bundle:nil];
        [cell.tagCollectionView registerNib:nib forCellWithReuseIdentifier:@"cellTag"];
        if (self.cellTagPrototype == nil)
            self.cellTagPrototype = [[nib instantiateWithOwner:nil options:nil] objectAtIndex:0];
        cell.tagCollectionViewHeightConstraint.constant = 40;
        cell.tagCollectionViewBottomConstraint.constant = 10;
        cell.tagCollectionView.delegate = self;
        cell.tagCollectionView.dataSource = self;
    }
    else
    {
        // Collapse the tag view
        cell.tagCollectionViewHeightConstraint.constant = 0;
        cell.tagCollectionViewBottomConstraint.constant = 0;
        cell.tagCollectionView.delegate = nil;
        cell.tagCollectionView.dataSource = nil;
    }
}

- (void)onCellConfigured:(UITableViewCell *)cell forItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
        [((SCRItemView *)cell).mediaCollectionView createThumbnails:NO completion:nil];
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

#pragma mark - UICollectionViewDataSource

- (SCRPostItem *)itemFromTagCollectionView:(UICollectionView *)collectionView
{
    id view = [collectionView superview];
    while (view && [view isKindOfClass:[UITableViewCell class]] == NO) {
        view = [view superview];
    }
    SCRPostItemCellDraft *parentCell = (SCRPostItemCellDraft *)view;
    return (SCRPostItem *)parentCell.item;
}

- (void)configureTagCell:(SCRItemTagCell *)cell forCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath
{
    SCRPostItem *item = [self itemFromTagCollectionView:collectionView];
    NSString *tag = [item.tags objectAtIndex:indexPath.row];
    cell.labelName.text = [@"#" stringByAppendingString:tag];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    SCRPostItem *item = [self itemFromTagCollectionView:collectionView];
    return item.tags.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SCRItemTagCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellTag" forIndexPath:indexPath];
    [self configureTagCell:cell forCollectionView:collectionView indexPath:indexPath];
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    SCRItemTagCell *cell = self.cellTagPrototype;
    [self configureTagCell:cell forCollectionView:collectionView indexPath:indexPath];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size;
}

@end
