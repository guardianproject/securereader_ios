//
//  SCRPickFeedsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-05-13.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPickFeedsViewController.h"
#import "SCRFeedTableDelegate.h"
#import "SCRDatabaseManager.h"
#import "SCRAppDelegate.h"
#import "SCRFeedListCell.h"
#import "SCRFeedListCategoryCell.h"
#import "RSSParser.h"
#import "NSString+SecureReader.h"
#import "SCRPassphraseManager.h"

@interface SCRPickFeedsViewController ()
@property (nonatomic, strong) NSMutableDictionary *feedsDictionary;
@property (nonatomic, strong) NSMutableArray *categoriesArray; // For deterministic ordering!
@property (nonatomic, strong) UITableViewCell *prototype;
@property (nonatomic, strong) NSArray *feeds;
@end

@implementation SCRPickFeedsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    UINib *nib = [UINib nibWithNibName:@"SCRFeedListCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];
    nib = [UINib nibWithNibName:@"SCRFeedListCellWithDescription" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellFeedWithDescription"];
    nib = [UINib nibWithNibName:@"SCRFeedListCategoryCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellFeedCategory"];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSString *opmlPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"opml"];
    NSData *opmlData = [NSData dataWithContentsOfFile:opmlPath];
    
    RSSParser *parser = [SCRFeedFetcher defaultParser];
    
    [parser feedsFromOPMLData:opmlData completionBlock:^(NSArray *feeds, NSError *error) {
        self.feeds = feeds;
        [self processFeeds:feeds];
    } completionQueue:dispatch_get_main_queue()];
}

- (BOOL) shouldPerformSegueWithIdentifier:(nonnull NSString *)identifier sender:(nullable id)sender {
    if ([identifier isEqualToString:@"finishFeedCuration"]) {
        
        // Save all subscribed feeds to a property list so that we can
        // add them later, when we have created the DB. Only add hashes for the URLs, to avoid
        // plain text URLs being kept.
        NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        NSURL *processedFileURL = [[tmpDirURL URLByAppendingPathComponent:@"filtered"] URLByAppendingPathExtension:@"opml"];
        
        NSMutableArray *array = [NSMutableArray new];
        for (SCRFeed *feed in self.feeds)
        {
            if (feed.subscribed)
                [array addObject:[[feed.xmlURL absoluteString] scr_md5]];
        }
        
        NSString *errorStr;
        NSData *dataRep = [NSPropertyListSerialization dataFromPropertyList:array
                                                                     format:NSPropertyListXMLFormat_v1_0
                                                           errorDescription:&errorStr];
        if (!dataRep) {
            // Handle error
        }
        else{
            [dataRep writeToURL:processedFileURL atomically:YES];
        }
        
        // Setup db on first run
        [[SCRTouchLock sharedInstance] deletePasscode];
        NSString *passphrase = [[SCRPassphraseManager sharedInstance] generateNewPassphrase];
        [[SCRPassphraseManager sharedInstance] setDatabasePassphrase:passphrase storeInKeychain:YES];
        BOOL success = [[SCRAppDelegate sharedAppDelegate] setupDatabase];
        if (!success) {
            NSLog(@"Error setting up database!");
        }
    }
    return YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void) processFeeds:(NSArray *)feeds
{
    _feedsDictionary = [NSMutableDictionary dictionary];
    _categoriesArray = [NSMutableArray array];
    for (SCRFeed *feed in feeds)
    {
        feed.subscribed = YES; //default all feeds to subscribed
        NSString *category = nil;
        if ([feed.feedCategory length] > 0)
            category = feed.feedCategory;
        
        category = [[NSBundle mainBundle] localizedStringForKey:category value:category table:@"FeedCategories"];
        
        NSMutableArray *categoryFeeds = [_feedsDictionary objectForKey:category];
        if (categoryFeeds == nil)
        {
            categoryFeeds = [NSMutableArray new];
            [_feedsDictionary setObject:categoryFeeds forKey:category];
            [_categoriesArray addObject:category];
        }
        [categoryFeeds addObject:feed];
    }
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [_categoriesArray count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableArray *sectionFeeds = [_feedsDictionary objectForKey:[_categoriesArray objectAtIndex:section]];
    return [sectionFeeds count];
}

- (void)configureCell:(UITableViewCell *)genericcell forItem:(NSObject *)genericitem
{
    SCRFeedListCell *cell = (SCRFeedListCell *)genericcell;
    SCRFeed *feed = (SCRFeed *)genericitem;
    
    cell.titleView.text = feed.title;
    if (cell.descriptionView != nil)
        cell.descriptionView.text = feed.feedDescription;
    
    cell.iconViewWidthConstraint.constant = 70;
    if ([feed subscribed])
        [cell.iconView setImage:[UIImage imageNamed:@"ic_toggle_selected"]];
    else
        [cell.iconView setImage:[UIImage imageNamed:@"ic_toggle_add"]];
    [cell.iconView setHidden:NO];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *key = [_categoriesArray objectAtIndex:section];
    if (key.length == 0)
        return @"Uncategorized";
    return key;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SCRFeedListCategoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellFeedCategory"];
    cell.titleView.text = [self tableView:tableView titleForHeaderInSection:section];
    
    NSString *category = (NSString *)[_categoriesArray objectAtIndex:section];
    if ([@"World News" isEqualToString:category])
    {
        [cell.categoryImage setArtworkPath:@"img_cat-worldnews"];
    }
    else if ([@"National News" isEqualToString:category])
    {
        [cell.categoryImage setArtworkPath:@"img_cat-nationalnews"];
    }
    else if ([@"Arts & Culture" isEqualToString:category])
    {
        [cell.categoryImage setArtworkPath:@"img_cat-artsculture"];
    }
    else if ([@"Business" isEqualToString:category])
    {
        [cell.categoryImage setArtworkPath:@"img_cat-business"];
    }
    else if ([@"Sports" isEqualToString:category])
    {
        [cell.categoryImage setArtworkPath:@"img_cat-sports"];
    }
    else if ([@"Technology" isEqualToString:category])
    {
        [cell.categoryImage setArtworkPath:@"img_cat-technology"];
    }
    else
    {
        // Default
        // [cell.categoryImage setArtworkPath:@"onboard-category"];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *item = [self itemForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellFeedWithDescription" forIndexPath:indexPath];
    [self configureCell:cell forItem:item];
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    return cell;
}

- (UITableViewCell *)prototypeWithIdentifier:(NSString *)identifier
{
    if (self.prototype == nil)
    {
        self.prototype = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    }
    return self.prototype;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *item = [self itemForIndexPath:indexPath];
    UITableViewCell *prototype = [self prototypeWithIdentifier:@"cellFeedWithDescription"];
    [self configureCell:prototype forItem:item];
    [prototype setNeedsUpdateConstraints];
    [prototype updateConstraintsIfNeeded];
    prototype.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(prototype.bounds));
    [prototype setNeedsLayout];
    [prototype layoutIfNeeded];
    CGSize size = [prototype.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height+1;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (NSObject *) itemForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *feedsInSection = [_feedsDictionary objectForKey:[_categoriesArray objectAtIndex:indexPath.section]];
    return [feedsInSection objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    SCRFeed *feed = (SCRFeed *)[self itemForIndexPath:indexPath];
    feed.subscribed = !feed.subscribed;
    [self.tableView reloadData];
}

@end
