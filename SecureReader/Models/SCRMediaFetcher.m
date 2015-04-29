//
//  SCRMediaFetcher.m
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaFetcher.h"
#import "SCRMediaItem.h"
#import "IOCipher.h"

typedef void (^SCRURLSesssionDataTaskCompletion)(NSURLSessionTask *dataTask, NSError *error);

@interface SCRURLSessionDataTaskInfo : NSObject 

@property (nonatomic, strong) SCRMediaItem *item;
@property (nonatomic, weak) NSURLSessionTask *sessionTask;
@property (nonatomic, strong) NSString *localPath;
@property (nonatomic, copy) SCRURLSesssionDataTaskCompletion completion;
@property (nonatomic) NSUInteger offset;

@end

@implementation SCRURLSessionDataTaskInfo
@end

@interface SCRMediaFetcher () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableDictionary *dataTaskDictionary;
@property (nonatomic, strong) IOCipher *ioCipher;

@property (nonatomic) dispatch_queue_t isolationQueue;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation SCRMediaFetcher

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration storage:(IOCipher *)ioCipher
{
    if (self = [self init]) {
        NSString *isolationLabel = [NSString stringWithFormat:@"%@.isolation.%p", [self class], self];
        self.isolationQueue = dispatch_queue_create([isolationLabel UTF8String], 0);
        
        self.dataTaskDictionary = [[NSMutableDictionary alloc] init];
        
        self.ioCipher = ioCipher;
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        self.urlSessionConfiguration = sessionConfiguration;
    }
    return self;
}

- (void)setUrlSessionConfiguration:(NSURLSessionConfiguration *)urlSessionConfiguration
{
    if (![self.urlSession.configuration isEqual:urlSessionConfiguration]) {
        [self invalidate];
        _urlSession = [NSURLSession sessionWithConfiguration:urlSessionConfiguration delegate:self delegateQueue:self.operationQueue];
    }
}

- (NSURLSessionConfiguration *)urlSessionConfiguration
{
    return self.urlSession.configuration;
}

- (void) invalidate {
    [self.urlSession invalidateAndCancel];
    _urlSession = nil;
}

- (dispatch_queue_t)completionQueue
{
    if (!_completionQueue) {
        return dispatch_get_main_queue();
    }
    return _completionQueue;
}


- (void)downloadMediaItem:(SCRMediaItem *)mediaItem completionBlock:(void (^)(NSError *))completion
{
    [self.networkOperationQueue addOperationWithBlock:^{
        NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithURL:mediaItem.url];
        dataTask.taskDescription = mediaItem.yapKey;
        
        [self addDataTask:dataTask forMediaItem:mediaItem completion:^(NSURLSessionTask *task, NSError *error) {
            if (completion) {
                completion(error);
            }
        }];
        [dataTask resume];
    }];
    
}

- (void)saveMediaItem:(SCRMediaItem *)mediaItem data:(NSData *)data completionBlock:(void (^)(NSError *error))completion
{
    if (!completion) {
        return;
    }
    
    dispatch_async(self.isolationQueue, ^{
        NSError *error = nil;
        [self receivedData:data forPath:mediaItem.localPath atOffset:0 error:&error];
        completion(error);
    });
}

#pragma - mark Private Methods

- (void)receivedData:(NSData *)data forPath:(NSString *)path atOffset:(NSUInteger)offset error:(NSError **)error;
{
    [NSThread sleepForTimeInterval:3];
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        NSError *err = nil;
        [self.ioCipher writeDataToFileAtPath:path data:[NSData dataWithBytesNoCopy:(void*)bytes length:byteRange.length freeWhenDone:NO] offset:(offset+byteRange.location) error:&err];
        if(err) {
            *stop = YES;
            *error = err;
        }
    }];
}

#pragma - mark dataTaskDictionary Isolatoin Methods
//Taken mostly from http://www.objc.io/issue-2/low-level-concurrency-apis.html


- (void)addDataTask:(NSURLSessionDataTask *)dataTask forMediaItem:(SCRMediaItem *)mediaItem completion:(SCRURLSesssionDataTaskCompletion)completion
{
    __block SCRURLSessionDataTaskInfo *taskInfo = [[SCRURLSessionDataTaskInfo alloc] init];
    taskInfo.item = mediaItem;
    taskInfo.sessionTask = dataTask;
    taskInfo.localPath = mediaItem.localPath;
    taskInfo.completion = completion;
    taskInfo.offset = 0;
    
    dispatch_async(self.isolationQueue, ^{
        if (dataTask && [mediaItem.localPath length]) {
            [self.dataTaskDictionary setObject:taskInfo forKey:mediaItem.yapKey];
        }
    });
    
    if ([self.delegate respondsToSelector:@selector(mediaFetcher:didStartDownload:)])
    {
        [self.delegate mediaFetcher:self didStartDownload:mediaItem];
    }
}

- (SCRURLSessionDataTaskInfo *)infoForKey:(NSString *)key
{
    __block SCRURLSessionDataTaskInfo *dataInfo = nil;
    dispatch_sync(self.isolationQueue, ^{
        dataInfo = [self.dataTaskDictionary objectForKey:key];
    });
    
    return dataInfo;
}

- (void)removeDataTask:(NSURLSessionDataTask *)dataTask
{
    dispatch_async(self.isolationQueue, ^{
        if (dataTask) {
            [self.dataTaskDictionary removeObjectForKey:dataTask.taskDescription];
        }
    });
}

#pragma - mark NSURLSessionDataDelegate Methods

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if([session isEqual:self.urlSession])
    {
        SCRURLSessionDataTaskInfo *info = [self infoForKey:dataTask.taskDescription];
        
        NSError *error = nil;
        [self receivedData:data forPath:info.localPath atOffset:info.offset error:&error];
        if (error) {
            [dataTask cancel];
            if (info.completion) {
                dispatch_async(self.completionQueue, ^{
                    info.completion(dataTask,error);
                });
            }
        }
        info.offset += [data length];
        
        if ([self.delegate respondsToSelector:@selector(mediaFetcher:didDownloadProgress:downloaded:ofTotal:)])
        {
            [self.delegate mediaFetcher:self didDownloadProgress:info.item downloaded:info.offset ofTotal:dataTask.countOfBytesExpectedToReceive];
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if([session isEqual:self.urlSession]) {
        SCRURLSessionDataTaskInfo *info = [self infoForKey:task.taskDescription];
        if (info.completion)
        {
            dispatch_async(self.completionQueue, ^{
                info.completion(task,error);
            });
        }
        if ([self.delegate respondsToSelector:@selector(mediaFetcher:didCompleteDownload:withError:)])
        {
            [_delegate mediaFetcher:self didCompleteDownload:info.item withError:error];
        }
    }
}

- (NSURLSessionTask *)taskForMediaItemYapKey:(NSString *)yapKey
{
    NSURLSessionTask *task = nil;
    if ([yapKey length]) {
        SCRURLSessionDataTaskInfo *taskInfo = [self infoForKey:yapKey];
        task = taskInfo.sessionTask;
    }
    return task;
}

@end
