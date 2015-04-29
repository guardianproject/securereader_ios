//
//  SCRMediaDownloadsControllerTableViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-27.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaDownloadsViewController.h"
#import "SCRAppDelegate.h"
#import "SCRItemView.h"
#import "UIView+Theming.h"

@interface SCRMediaDownloadsViewController ()
@property (nonatomic, strong) SCRMediaFetcherWatcher *watcher;
@property (nonatomic, strong) SCRItemView *prototype;
@end

@implementation SCRMediaDownloadsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UINib *nib = [UINib nibWithNibName:@"SCRItemCellMediaDownloads" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellMediaDownload"];
    self.watcher = [[SCRAppDelegate sharedAppDelegate] mediaFetcherWatcher];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[SCRAppDelegate sharedAppDelegate] mediaFetcherWatcher].delegate = self;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[SCRAppDelegate sharedAppDelegate] mediaFetcherWatcher].delegate = nil;
    [super viewWillDisappear:animated];
}

#pragma mark Table View Delegate/Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int sections = 0;
    if ([self.watcher numberOfInProgressItems] > 0)
        sections += 1;
    if ([self.watcher numberOfCompleteItems] > 0)
        sections += 1;
    return sections;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView* view = [[UIView alloc] init];
    UILabel* label = [[UILabel alloc] init];
    
    [view setTheme:@"MediaDownloadsSectionStyle"];
    label.text = [self tableView: tableView titleForHeaderInSection: section];
    label.textAlignment = NSTextAlignmentCenter;
    [label setTheme:@"MediaDownloadsSectionStyle"];
    [label sizeToFit];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:label];
    [view addConstraints:
     @[[NSLayoutConstraint constraintWithItem:label
                                    attribute:NSLayoutAttributeLeading
                                    relatedBy:NSLayoutRelationEqual
                                       toItem:view
                                    attribute:NSLayoutAttributeLeading
                                   multiplier:1 constant:15],
       [NSLayoutConstraint constraintWithItem:label
                                    attribute:NSLayoutAttributeCenterY
                                    relatedBy:NSLayoutRelationEqual
                                       toItem:view
                                    attribute:NSLayoutAttributeCenterY
                                   multiplier:1 constant:0]]];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && [self.watcher numberOfInProgressItems] > 0)
        return NSLocalizedString(@"MediaDownloads.SectionHeader.InProgress", @"Section header for the items in progress");
    else
        return NSLocalizedString(@"MediaDownloads.SectionHeader.Complete", @"Section header for the complete items");
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && [self.watcher numberOfInProgressItems] > 0)
        return [self.watcher numberOfInProgressItems];
    else
        return [self.watcher numberOfCompleteItems];
}

- (long) indexFromIndexPath:(NSIndexPath *)indexPath
{
    long index = indexPath.row;
    if (indexPath.section == 1)
        index += [self.watcher numberOfInProgressItems];
    return index;
}

- (void) configureCell:(SCRItemView *)cell forIndexPath:(NSIndexPath *)indexPath
{
    SCRItemDownloadInfo *itemInfo = [self.watcher.downloads objectAtIndex:[self indexFromIndexPath:indexPath]];
    
    [cell.mediaCollectionView setItem:itemInfo.item];
    cell.titleView.text = [itemInfo.item title];
    
    if ([itemInfo isComplete])
    {
        cell.textView.text = NSLocalizedString(@"MediaDownloads.Progress.Done", @"Display string for download done");
    }
    else
    {
        NSUInteger bytesTotal = [itemInfo bytesTotal];
        if (bytesTotal > 0)
        {
            cell.textView.text = [NSString localizedStringWithFormat:NSLocalizedString(@"MediaDownloads.Progress.Bytes", @"Display string for profress with byte count"), (int)(100.0f * [itemInfo bytesDownloaded]) / bytesTotal, [NSByteCountFormatter stringFromByteCount:bytesTotal countStyle:NSByteCountFormatterCountStyleFile]];
        }
        else
        {
            cell.textView.text = [NSString localizedStringWithFormat:NSLocalizedString(@"MediaDownloads.Progress.Items", @"Display string for profress with item count"), [itemInfo numberOfCompleteItems], [itemInfo.mediaInfos count]];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.prototype == nil)
        self.prototype = [self.tableView dequeueReusableCellWithIdentifier:@"cellMediaDownload"];
    [self configureCell:self.prototype forIndexPath:indexPath];
    [self.prototype setNeedsUpdateConstraints];
    [self.prototype updateConstraintsIfNeeded];
    self.prototype.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(self.prototype.bounds));
    [self.prototype setNeedsLayout];
    [self.prototype layoutIfNeeded];
    CGSize size = [self.prototype.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCRItemView *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cellMediaDownload" forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    [cell.mediaCollectionView createThumbnails:NO completion:nil];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    SCRItemDownloadInfo *itemInfo = [self.watcher.downloads objectAtIndex:[self indexFromIndexPath:indexPath]];
    if ([itemInfo isComplete])
    {
        [self.tabBarController setSelectedIndex:0];
    }
 }

- (void)needsUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
