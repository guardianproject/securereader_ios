//
//  SCRMediaFetcherWatcher.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-28.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCRMediaFetcher.h"
#import "SCRItem.h"
#import "SCRMediaItem.h"

@protocol SCRMediaFetcherWatcherDelegate<NSObject>
- (void)needsUpdate;
@end

@interface SCRMediaItemDownloadInfo : NSObject
@property (nonatomic, weak) SCRMediaItem *item;
@property NSUInteger bytesDownloaded;
@property NSUInteger bytesTotal;
@end

@interface SCRItemDownloadInfo : NSObject
@property (nonatomic, weak) SCRItem *item;
@property (nonatomic, strong) NSMutableArray *mediaInfos;
- (SCRMediaItemDownloadInfo *) mediaInfoWithMediaItem:(SCRMediaItem *)mediaItem;
- (NSUInteger) bytesTotal;
- (NSUInteger) bytesDownloaded;
- (NSUInteger) numberOfCompleteItems;
- (BOOL) isComplete;
@end

@interface SCRMediaFetcherWatcher : NSObject<SCRMediaFetcherDelegate>
- (instancetype)initWithMediaFetcher:(SCRMediaFetcher *)fetcher;
- (NSUInteger) numberOfItems;
- (NSUInteger) numberOfCompleteItems;
- (NSUInteger) numberOfInProgressItems;
@property (nonatomic, weak) id<SCRMediaFetcherWatcherDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *downloads;
@end
