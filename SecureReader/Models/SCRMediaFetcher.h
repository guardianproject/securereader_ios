//
//  SCRMediaFetcher.h
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRNetworkFetcher.h"

@class SCRMediaItem, IOCipher;
@protocol SCRMediaFetcherDelegate;

@interface SCRMediaFetcher : SCRNetworkFetcher

@property (nonatomic, weak) id<SCRMediaFetcherDelegate> delegate;

@property (nonatomic, strong, readonly) NSURLSession *urlSession;

/*
 The queue on which downloadMediaItem:completionBlock will be called. defaults to the main queue;
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

/**
 The required way to initatie a SCRMediaFetcher.
 
 @param sessionConfiguration The configuration to be used for all subsequent downloads. Make sure to use a configuration policy that includes NSURLCacheStorageAllowedInMemoryOnly or NSURLCacheStorageNotAllowed.
 @param ioCipher The secure storage object where all downloads will be stored
 @return A newly created SCRMediaFetcher for downloading any data to secure storage.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration storage:(IOCipher *)ioCipher;

/** Invalidates the internal NSURLSession */
- (void) invalidate;

/**
 Asynchronously download a SCRMediaItem. Uses the mediaItem remoteURL and localPath to fetch from and store in IOCipher.
 
 @param mediaItem The media item to download
 @param completion The completion block to be called once the download is complete or an error is encountered
 */
- (void)downloadMediaItem:(SCRMediaItem *)mediaItem completionBlock:(void (^)(NSError *error))completion;

/**
 Asynchronously save a SCRMediaItem. Uses the data provided and the localPath to store in IOCipher.
 
 @param mediaItem The media item to save data for
 @param data The data to save
 @param completion The completion block to be called once the save is complete or an error is encountered
 */
- (void)saveMediaItem:(SCRMediaItem *)mediaItem data:(NSData *)data completionBlock:(void (^)(NSError *error))completion;

- (NSURLSessionTask *)taskForMediaItemYapKey:(NSString *)yapKey;

@end

@protocol SCRMediaFetcherDelegate <NSObject>
@optional
- (void) mediaFetcher:(SCRMediaFetcher *)mediaFetcher didStartDownload:(SCRMediaItem *)mediaItem;

- (void) mediaFetcher:(SCRMediaFetcher *)mediaFetcher
  didDownloadProgress:(SCRMediaItem *)mediaItem
           downloaded:(NSUInteger)countOfBytesReceived
              ofTotal:(NSUInteger)countOfBytesExpectedToReceive;

- (void) mediaFetcher:(SCRMediaFetcher *)mediaFetcher didCompleteDownload:(SCRMediaItem *)mediaItem withError:(NSError *)error;
@end
