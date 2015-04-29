//
//  SCRMediaDownloadsControllerTableViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-27.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaDownloadsViewController.h"
#import "SCRAppDelegate.h"

@interface SCRMediaDownloadsViewController ()
@property (nonatomic, strong) SCRMediaFetcherWatcher *watcher;
@end

@implementation SCRMediaDownloadsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    long index = indexPath.row;
    if (indexPath.section == 1)
        index += [self.watcher numberOfInProgressItems];
    SCRItemDownloadInfo *itemInfo = [self.watcher.downloads objectAtIndex:index];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    cell.textLabel.text = [itemInfo.item title];
    
    if ([itemInfo isComplete])
    {
        cell.detailTextLabel.text = NSLocalizedString(@"MediaDownloads.Progress.Done", @"Display string for download done");
    }
    else
    {
        NSUInteger bytesTotal = [itemInfo bytesTotal];
        if (bytesTotal > 0)
        {
            cell.detailTextLabel.text = [NSString localizedStringWithFormat:NSLocalizedString(@"MediaDownloads.Progress.Bytes", @"Display string for profress with byte count"), (int)(100.0f * [itemInfo bytesDownloaded]) / bytesTotal, [NSByteCountFormatter stringFromByteCount:bytesTotal countStyle:NSByteCountFormatterCountStyleFile]];
        }
        else
        {
            cell.detailTextLabel.text = [NSString localizedStringWithFormat:NSLocalizedString(@"MediaDownloads.Progress.Items", @"Display string for profress with item count"), [itemInfo numberOfCompleteItems], [itemInfo.mediaInfos count]];
        }
    }//%lu%% of %@ downloaded  %lu of %lu items downloaded
    return cell;
}

- (void)needsUpdate
{
    [self.tableView reloadData];
}

@end
