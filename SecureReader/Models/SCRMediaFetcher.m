//
//  SCRMediaFetcher.m
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaFetcher.h"
#import "AFNetworking.h"
#import "SCRMediaItem.h"
#import "IOCipher.h"

@interface SCRMediaFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;
@property (nonatomic, strong) NSMutableDictionary *dataTaskDictionary;
@property (nonatomic, strong) IOCipher *ioCipher;

@property (nonatomic) dispatch_queue_t isolationQueue;
@property (nonatomic) dispatch_queue_t workQueue;

@end

@implementation SCRMediaFetcher

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration storage:(IOCipher *)ioCipher
{
    if (self = [self init]) {
        NSString *isolationLabel = [NSString stringWithFormat:@"%@.isolation.%p", [self class], self];
        self.isolationQueue = dispatch_queue_create([isolationLabel UTF8String], 0);
        
        NSString *workLabel = [NSString stringWithFormat:@"%@.work.%p", [self class], self];
        self.workQueue = dispatch_queue_create([isolationLabel UTF8String], 0);
        
        self.ioCipher = ioCipher;
        
        self.httpSessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
        self.httpSessionManager.completionQueue = self.workQueue;
        AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
        self.httpSessionManager.responseSerializer = serializer;
        __weak typeof(self)weakSelf = self;
        [self.httpSessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            NSString *localPath = [strongSelf localPathForDataTask:dataTask];
            
            [strongSelf receivedData:data forPath:localPath];
        }];
    }
    return self;
}


- (void)downloadMediaItem:(SCRMediaItem *)mediaItem completionQueue:(dispatch_queue_t)completionQueue completionBlock:(void (^)(NSError *))completion
{
    if (!completion) {
        return;
    }
    
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    NSURLSessionDataTask *dataTask = [self.httpSessionManager GET:mediaItem.remoteURL.absoluteString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        [self removeDataTask:task];
        dispatch_async(completionQueue, ^{
            completion(nil);
        });
        
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self removeDataTask:task];
        dispatch_async(completionQueue, ^{
            completion(error);
        });
    }];
    
    [self addDataTask:dataTask forLocalPath:[mediaItem localPath]];
}

#pragma - mark Private Methods

- (void)receivedData:(NSData *)data forPath:(NSString *)path
{
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        [self.ioCipher writeDataToFileAtPath:path data:[NSData dataWithBytes:bytes length:byteRange.length] offset:byteRange.location error:nil];
    }];
}

#pragma - mark dataTaskDictionary Isolatoin Methods
//Taken mostly from http://www.objc.io/issue-2/low-level-concurrency-apis.html


- (void)addDataTask:(NSURLSessionDataTask *)dataTask forLocalPath:(NSString *)localPath
{
    dispatch_async(self.isolationQueue, ^{
        if (dataTask && [localPath length]) {
            [self.dataTaskDictionary setObject:localPath forKey:@(dataTask.taskIdentifier)];
        }
    });
}

- (NSString *)localPathForDataTask:(NSURLSessionDataTask *)dataTask
{
    __block NSString *localPath = nil;
    dispatch_sync(self.isolationQueue, ^{
        localPath = [self.dataTaskDictionary objectForKey:@(dataTask.taskIdentifier)];
    });
    
    return localPath;
}

- (void)removeDataTask:(NSURLSessionDataTask *)dataTask
{
    dispatch_async(self.isolationQueue, ^{
        if (dataTask) {
            [self.dataTaskDictionary removeObjectForKey:@(dataTask.taskIdentifier)];
        }
    });
}

@end
