//
//  SCRAddPostViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-03-31.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRAddPostViewController.h"
#import "SCRDatabaseManager.h"

@interface SCRAddPostViewController ()
@property (nonatomic, strong) SCRPostItem *item;
@property BOOL isEditing;
@end

@implementation SCRAddPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self showPostBarButton:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.item == nil)
    {
        self.item = [[SCRPostItem alloc] init];
        self.item.uuid = [[NSUUID UUID] UUIDString];
        self.isEditing = NO;
    }
    [self populateUIfromItem];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveDraft];
}

- (void) showPostBarButton:(BOOL) show
{
    if (show)
    {
        UIBarButtonItem *btnPost = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(post:)];
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.navigationItem.rightBarButtonItem, btnPost, nil]];
    }
    else
    {
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObject:self.navigationItem.rightBarButtonItem]];
    }
}

- (void)editItem:(SCRPostItem *)item
{
    self.item = item;
    self.isEditing = YES;
}

- (void)populateUIfromItem
{
    self.titleView.text = self.item.title;
    self.descriptionView.text = self.item.content;
}

- (void)populateItemFromUI
{
    self.item.title = self.titleView.text;
    self.item.content = self.descriptionView.text;
}

- (void)post:(id)sender
{
    [self populateItemFromUI];
    
    //TODO check valid for post
    self.item.isSent = YES;
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self.item saveWithTransaction:transaction];
    }];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveDraft
{
    if (self.item != nil && self.item.isSent == NO)
    {
        [self populateItemFromUI];
        [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [self.item saveWithTransaction:transaction];
        }];
    }
}

@end
