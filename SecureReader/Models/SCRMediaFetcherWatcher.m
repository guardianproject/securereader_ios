//
//  SCRMediaFetcherWatcher.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-28.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaFetcherWatcher.h"
#import "SCRMediaItem.h"
#import "SCRItem.h"
#import "SCRDatabaseManager.h"

@implementation SCRMediaItemDownloadInfo
@end

@implementation SCRItemDownloadInfo

- (SCRMediaItemDownloadInfo *) mediaInfoWithMediaItem:(SCRMediaItem *)mediaItem
{
    for (SCRMediaItemDownloadInfo *info in self.mediaInfos)
    {
        if (info.item == mediaItem)
            return info;
    }
    return nil;
}

- (NSUInteger) bytesTotal
{
    __block NSUInteger res = 0;
    [self.mediaInfos enumerateObjectsUsingBlock:^(SCRMediaItemDownloadInfo *mediaInfo, NSUInteger idx, BOOL *stop) {
        if (mediaInfo.bytesTotal == 0)
        {
            res = 0;
            *stop = YES;
        }
        else
        {
            res += mediaInfo.bytesTotal;
        }
    }];
    return res;
}

- (NSUInteger) bytesDownloaded
{
    __block NSUInteger res = 0;
    [self.mediaInfos enumerateObjectsUsingBlock:^(SCRMediaItemDownloadInfo *mediaInfo, NSUInteger idx, BOOL *stop) {
        res += mediaInfo.bytesDownloaded;
    }];
    return res;
}

- (NSUInteger) numberOfCompleteItems
{
    __block NSUInteger res = 0;
    [self.mediaInfos enumerateObjectsUsingBlock:^(SCRMediaItemDownloadInfo *mediaInfo, NSUInteger idx, BOOL *stop) {
        if (mediaInfo.bytesTotal > 0 && mediaInfo.bytesDownloaded == mediaInfo.bytesTotal)
            res += 1;
    }];
    return res;
}

- (BOOL) isComplete
{
    return [self numberOfCompleteItems] == [self.mediaInfos count];
}

@end

@implementation SCRMediaFetcherWatcher

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

- (NSUInteger) numberOfItems
{
    return [self.downloads count];
}

- (NSUInteger) numberOfCompleteItems
{
    __block NSUInteger nComplete = 0;
    [self.downloads enumerateObjectsUsingBlock:^(SCRItemDownloadInfo *itemInfo, NSUInteger idx, BOOL *stop) {
        if ([itemInfo isComplete])
            nComplete += 1;
    }];
    return nComplete;
}

- (NSUInteger) numberOfInProgressItems
{
    return [self.downloads count] - [self numberOfCompleteItems];
}

#pragma mark MediaFetcher delegate

-(void)mediaFetcher:(SCRMediaFetcher *)mediaFetcher didStartDownload:(SCRMediaItem *)mediaItem
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
            
            SCRMediaItemDownloadInfo *mediaInfo = [itemInfo mediaInfoWithMediaItem:mediaItem];
            if (mediaInfo == nil)
            {
                mediaInfo = [SCRMediaItemDownloadInfo new];
                mediaInfo.item = mediaItem;
                mediaInfo.bytesDownloaded = 0;
                mediaInfo.bytesTotal = 0;
                [itemInfo.mediaInfos addObject:mediaInfo];
            }
        }];
    }];
    if (self.delegate != nil)
        [self.delegate needsUpdate];
}

- (void)mediaFetcher:(SCRMediaFetcher *)mediaFetcher didDownloadProgress:(SCRMediaItem *)mediaItem downloaded:(NSUInteger)countOfBytesReceived ofTotal:(NSUInteger)countOfBytesExpectedToReceive
{
    for (SCRItemDownloadInfo *itemInfo in self.downloads)
    {
        SCRMediaItemDownloadInfo *mediaInfo = [itemInfo mediaInfoWithMediaItem:mediaItem];
        if (mediaInfo != nil)
        {
            mediaInfo.bytesDownloaded = countOfBytesReceived;
            mediaInfo.bytesTotal = countOfBytesExpectedToReceive;
        }
    }
    if (self.delegate != nil)
        [self.delegate needsUpdate];
}

- (void)mediaFetcher:(SCRMediaFetcher *)mediaFetcher didCompleteDownload:(SCRMediaItem *)mediaItem withError:(NSError *)error
{
    for (SCRItemDownloadInfo *itemInfo in self.downloads)
    {
        SCRMediaItemDownloadInfo *mediaInfo = [itemInfo mediaInfoWithMediaItem:mediaItem];
        if (mediaInfo != nil)
        {
            mediaInfo.bytesDownloaded = mediaInfo.bytesTotal;
            //mediaInfo.error = error; // TODO - add error
        }
    }
    if (self.delegate != nil)
        [self.delegate needsUpdate];
}

@end