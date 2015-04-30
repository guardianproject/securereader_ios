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
#import "YapDatabaseViewConnection.h"
#import "YapDatabaseFilteredviewTransaction.h"
#import "YapDatabaseViewMappings.h"
#import "SCRDatabaseManager.h"

@interface SCRMediaItemDownloadInfo : NSObject
@property (nonatomic, strong) NSString *mediaItemYapKey;
@property (nonatomic) BOOL isComplete; //May be able to remove
@property (nonatomic) int64_t bytesDownloaded;
@property (nonatomic) int64_t bytesTotal;
@end

@implementation SCRMediaItemDownloadInfo

@end

@interface SCRMediaDownloadsViewController () <SCRMediaFetcherDelegate>

@property (nonatomic, strong) YapDatabaseConnection *readOnlyConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) SCRItemView *prototype;

@property (nonatomic) dispatch_queue_t isolationQueue;
@property (nonatomic, strong) NSMutableDictionary *progressStateDictionary;

@end

@implementation SCRMediaDownloadsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *label = [NSString stringWithFormat:@"%@-isolation",NSStringFromClass([self class])];
    self.isolationQueue = dispatch_queue_create([label UTF8String], 0);
    
    UINib *nib = [UINib nibWithNibName:@"SCRItemCellMediaDownloads" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellMediaDownload"];
    
    self.readOnlyConnection = [[SCRDatabaseManager sharedInstance].database newConnection];
    
    [self.readOnlyConnection beginLongLivedReadTransaction];
    [[SCRDatabaseManager sharedInstance].readWriteConnection readWriteWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(NSString *group, NSString *collection, NSString *key, id object) {
            
            if ([object isKindOfClass:[SCRMediaItem class]]) {
                SCRMediaItem *mediaItem = (SCRMediaItem *)object;
                if (mediaItem.dataStatus != SCRMediaItemStatusNotDownloaded) {
                    return YES;
                }
            }
            
            return NO;
        }];
        
        NSString *tag = [NSString stringWithFormat:@"%f",[NSDate date].timeIntervalSince1970];
        [[transaction ext:kSCRMediaItemsFilteredViewName] setFiltering:filtering versionTag:tag];
    }];
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[[SCRMediaItem yapCollection]] view:kSCRMediaItemsFilteredViewName];
    [self.readOnlyConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
    }];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yapUpdated:) name:YapDatabaseModifiedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [SCRAppDelegate sharedAppDelegate].mediaFetcher.delegate = self;
    [self asyncUpdateDownloadStatusCompletion:nil];
    
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [SCRAppDelegate sharedAppDelegate].mediaFetcher.delegate = nil;
    [super viewWillDisappear:animated];
}

- (void)asyncUpdateDownloadStatusCompletion:(void (^)(void))completion;
{
    dispatch_async(self.isolationQueue, ^{
        
        SCRMediaFetcher *mediaFetcher = [SCRAppDelegate sharedAppDelegate].mediaFetcher;
        
        [self.readOnlyConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [[transaction ext:kSCRMediaItemsFilteredViewName] enumerateKeysInGroup:[SCRMediaItem yapCollection] usingBlock:^(NSString *collection, NSString *key, NSUInteger index, BOOL *stop) {
               
                NSURLSessionTask *task = [mediaFetcher taskForMediaItemYapKey:key];
                SCRMediaItemDownloadInfo *downloadInfo = [[SCRMediaItemDownloadInfo alloc] init];
                downloadInfo.mediaItemYapKey = key;
                if (task) {
                    downloadInfo.bytesDownloaded = task.countOfBytesReceived;
                    downloadInfo.bytesTotal = task.countOfBytesExpectedToReceive;
                } else {
                    downloadInfo.isComplete = YES;
                }
                
                self.progressStateDictionary[key] = downloadInfo;
            }];
        }];
        
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    });
}

#pragma mark Table View Delegate/Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.mappings numberOfSections];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0 && [self.mappings numberOfItemsInSection:section] > 0)
        return NSLocalizedString(@"MediaDownloads.SectionHeader.InProgress", @"Section header for the items in progress");
    else
        return NSLocalizedString(@"MediaDownloads.SectionHeader.Complete", @"Section header for the complete items");
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.mappings numberOfItemsInSection:section];
}

- (void) configureCell:(SCRItemView *)cell forIndexPath:(NSIndexPath *)indexPath
{
    __block SCRMediaItem *mediaItem = nil;
    __block SCRItem *item = nil;
    [self.readOnlyConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        mediaItem = [[transaction ext:kSCRMediaItemsFilteredViewName] objectAtIndexPath:indexPath withMappings:self.mappings];
        [mediaItem enumerateItemsInTransaction:transaction block:^(SCRItem *blockItem, BOOL *stop) {
            item = blockItem;
            //Only need one item for display
            *stop = YES;
        }];
    }];

    SCRMediaItemDownloadInfo *itemInfo = self.progressStateDictionary[mediaItem.yapKey];
    
    [cell.mediaCollectionView setItem:item];
    cell.titleView.text = [item title];
    
    if ([itemInfo isComplete])
    {
        cell.textView.text = NSLocalizedString(@"MediaDownloads.Progress.Done", @"Display string for download done");
    }
    else
    {
        int64_t bytesTotal = [itemInfo bytesTotal];
        if (bytesTotal > 0)
        {
            cell.textView.text = [NSString localizedStringWithFormat:NSLocalizedString(@"MediaDownloads.Progress.Bytes", @"Display string for profress with byte count"), (int)(100.0f * [itemInfo bytesDownloaded]) / bytesTotal, [NSByteCountFormatter stringFromByteCount:bytesTotal countStyle:NSByteCountFormatterCountStyleFile]];
        }
        else
        {
//            cell.textView.text = [NSString localizedStringWithFormat:NSLocalizedString(@"MediaDownloads.Progress.Items", @"Display string for profress with item count"), [itemInfo numberOfCompleteItems], [itemInfo.mediaInfos count]];
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

- (void)needsUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma - mark MediaFetcherDelegate Methods

- (void)mediaFetcher:(SCRMediaFetcher *)mediaFetcher didStartDownload:(SCRMediaItem *)mediaItem
{
    SCRMediaItemDownloadInfo *info = [[SCRMediaItemDownloadInfo alloc] init];
    info.mediaItemYapKey = mediaItem.yapKey;
    
    dispatch_async(self.isolationQueue, ^{
        self.progressStateDictionary[info.mediaItemYapKey] = info;
        //Update TableView
    });
}

- (void)mediaFetcher:(SCRMediaFetcher *)mediaFetcher didDownloadProgress:(SCRMediaItem *)mediaItem downloaded:(int64_t)countOfBytesReceived ofTotal:(int64_t)countOfBytesExpectedToReceive
{
    dispatch_async(self.isolationQueue, ^{
        SCRMediaItemDownloadInfo *info =  self.progressStateDictionary[mediaItem.yapKey];
        
        info.bytesTotal = countOfBytesExpectedToReceive;
        info.bytesDownloaded = countOfBytesReceived;
        //update tableview
    });
}

- (void)mediaFetcher:(SCRMediaFetcher *)mediaFetcher didCompleteDownload:(SCRMediaItem *)mediaItem withError:(NSError *)error
{
    dispatch_async(self.isolationQueue, ^{
        SCRMediaItemDownloadInfo *info =  self.progressStateDictionary[mediaItem.yapKey];
        
        info.bytesTotal = info.bytesDownloaded;
        info.isComplete = YES;
        //update tableview
    });
}



#pragma - mark Yap

- (void)yapUpdated:(NSNotification *)notification
{
    NSArray *notifications = [self.readOnlyConnection beginLongLivedReadTransaction];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.readOnlyConnection ext:kSCRMediaItemsFilteredViewName] getSectionChanges:&sectionChanges
                                                                         rowChanges:&rowChanges
                                                                   forNotifications:notifications
                                                                       withMappings:self.mappings];
    
    if ([sectionChanges count] == 0 && [rowChanges count] == 0 ) {
        return;
    }
    
    [self.tableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate:
            case YapDatabaseViewChangeMove:
                break;
        }
    }
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.tableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
}

@end
