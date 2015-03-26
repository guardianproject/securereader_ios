//
//  SCRFileManager.m
//  SecureReader
//
//  Created by David Chiles on 2/27/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFileManager.h"
#import "IOCipher.h"

@interface SCRFileManager ()

@end

@implementation SCRFileManager

- (void)setupWithPath:(NSString *)path password:(NSString *)password
{
    _ioCipher = [[IOCipher alloc] initWithPath:path password:password];
}

- (BOOL)hasDataForPath:(NSString *)path
{
    if (![path length])
        return NO;
    return [self.ioCipher fileExistsAtPath:path isDirectory:nil];
}

- (void)dataForPath:(NSString *)path
    completionQueue:(dispatch_queue_t)completionQueue
         completion:(void (^)(NSData *data, NSError *error))completion
{
    if (!completion || ![path length]) {
        return;
    }
    
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [self.ioCipher readDataFromFileAtPath:path error:&error];
        dispatch_async(completionQueue, ^{
            completion(data,error);
        });
    });
}

- (void)removeDataForPath:(NSString *)path
          completionQueue:(dispatch_queue_t)completionQueue
               completion:(void (^)(BOOL sucess, NSError *error))completion
{
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block NSError *error = nil;
        __block BOOL success = [self.ioCipher removeItemAtPath:path error:&error];
        if (completion) {
            dispatch_async(completionQueue, ^{
                completion(success,error);
            });
        }
    });
}

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

@end
