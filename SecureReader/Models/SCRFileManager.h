//
//  SCRFileManager.h
//  SecureReader
//
//  Created by David Chiles on 2/27/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IOCipher;

@interface SCRFileManager : NSObject

@property (nonatomic, strong, readonly) IOCipher *ioCipher;

- (void)setupWithPath:(NSString *)path password:(NSString *)password;

- (BOOL)hasDataForPath:(NSString *)path;

- (void)dataForPath:(NSString *)path
    completionQueue:(dispatch_queue_t)completionQueue
         completion:(void (^)(NSData *data, NSError *error))completion;

- (void)removeDataForPath:(NSString *)path
          completionQueue:(dispatch_queue_t)completionQueue
               completion:(void (^)(BOOL sucess, NSError *error))completion;

+ (instancetype)sharedInstance;

@end
