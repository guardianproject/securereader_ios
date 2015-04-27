//
//  SCRMediaDownloadsTableDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-27.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaDownloadsTableDelegate.h"
#import "SCRMediaItem.h"
#import "SCRItem.h"
#import "SCRDatabaseManager.h"

@interface SCRMediaDownloadInfo : NSObject
@property (nonatomic, weak) SCRMediaItem *item;
@property NSUInteger bytesDownloaded;
@property NSUInteger bytesTotal;
@end

@interface SCRItemDownloadInfo : NSObject
@property (nonatomic, weak) SCRItem *item;
@property (nonatomic, strong) NSMutableArray *mediaInfos;
- (SCRMediaDownloadInfo *) mediaInfoWithMediaItem:(SCRMediaItem *)mediaItem;
@end

@implementation SCRMediaDownloadInfo
@end

@implementation SCRItemDownloadInfo
- (SCRMediaDownloadInfo *) mediaInfoWithMediaItem:(SCRMediaItem *)mediaItem
{
    for (SCRMediaDownloadInfo *info in self.mediaInfos)
    {
        if (info.item == mediaItem)
            return info;
    }
    return nil;
}
@end

@interface SCRMediaDownloadsTableDelegate ()
@property (nonatomic, strong) NSMutableArray *downloads;
@end

@implementation SCRMediaDownloadsTableDelegate

- (instancetype)initWithMediaFetcher:(SCRMediaFetcher *)fetcher
{
    self = [super init];
    if (self != nil)
    {
        self.downloads = [NSMutableArray new];
        fetcher.delegate = self;
    }
    return self;
}

- (void)mediaDownloadStarted:(SCRMediaItem *)mediaItem
{
    [[SCRDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [mediaItem enumerateItemsInTransaction:transaction block:^(SCRItem *item, BOOL *stop) {

            SCRItemDownloadInfo *itemInfo = nil;
            for (SCRItemDownloadInfo *info in self.downloads)
            {
                if (info.item == item)
                {
                    itemInfo = info;
                    break;
                }
            }
            if (itemInfo == nil)
            {
                itemInfo = [SCRItemDownloadInfo new];
                itemInfo.item = item;
                itemInfo.mediaInfos = [NSMutableArray new];
                [self.downloads addObject:itemInfo];
            }
            
            SCRMediaDownloadInfo *mediaInfo = [itemInfo mediaInfoWithMediaItem:mediaItem];
            if (mediaInfo == nil)
            {
                mediaInfo = [SCRMediaDownloadInfo new];
                mediaInfo.item = mediaItem;
                mediaInfo.bytesDownloaded = 0;
                mediaInfo.bytesTotal = 0;
                [itemInfo.mediaInfos addObject:mediaInfo];
            }
        }];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)mediaDownloadProgress:(SCRMediaItem *)mediaItem downloaded:(NSUInteger)bytes ofTotal:(NSUInteger)total
{
    for (SCRItemDownloadInfo *itemInfo in self.downloads)
    {
        SCRMediaDownloadInfo *mediaInfo = [itemInfo mediaInfoWithMediaItem:mediaItem];
        if (mediaInfo != nil)
        {
            mediaInfo.bytesDownloaded = bytes;
            mediaInfo.bytesTotal = total;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)mediaDownloadCompleted:(SCRMediaItem *)mediaItem withError:(NSError *)error
{
    for (SCRItemDownloadInfo *itemInfo in self.downloads)
    {
        SCRMediaDownloadInfo *mediaInfo = [itemInfo mediaInfoWithMediaItem:mediaItem];
        if (mediaInfo != nil)
        {
            mediaInfo.bytesDownloaded = mediaInfo.bytesTotal;
            //mediaInfo.error = error; // TODO - add error
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.downloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCRItemDownloadInfo *itemInfo = [self.downloads objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    if (cell == nil)
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    cell.textLabel.text = [itemInfo.item title];
    
    BOOL useItemCount = NO;
    int nDone = 0;
    int nTotal = 0;
    int cbDone = 0;
    int cbTotal = 0;
    for (SCRMediaDownloadInfo *mediaInfo in itemInfo.mediaInfos)
    {
        if (mediaInfo.bytesTotal == 0)
            useItemCount = YES;
        else if (mediaInfo.bytesTotal == mediaInfo.bytesDownloaded)
        {
            nDone += 1;
        }
        nTotal += 1;
        cbTotal += mediaInfo.bytesTotal;
        cbDone += mediaInfo.bytesDownloaded;
    }
    
    if (useItemCount)
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d of %d items downloaded", nDone, nTotal];
    }
    else if (cbTotal > 0 && cbTotal == cbDone)
    {
        cell.detailTextLabel.text = @"Done";
    }
    else
    {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d of %d bytes downloaded", cbDone, cbTotal];
    }
    //[cell setNeedsUpdateConstraints];
    //[cell updateConstraintsIfNeeded];
    return cell;
}

//- (UITableViewCell *) cellForItemIfVisible:(SCRMediaItem *)item
//{
//    NSUInteger idx = [self.downloads indexOfObject:item];
//    if (idx != NSNotFound)
//    {
//        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
//        if (visibleIndexPaths != nil && visibleIndexPaths.count > 0)
//        {
//            NSIndexPath *firstVisible = [visibleIndexPaths firstObject];
//            NSIndexPath *lastVisible = [visibleIndexPaths lastObject];
//            if (firstVisible.row <= idx && lastVisible.row >= idx)
//            {
//                return [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
//            }
//        }
//    }
//    return nil;
//}

@end
