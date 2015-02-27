//
//  SCRMediaFetcher.h
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCRMediaItem;
@class IOCipher;

@interface SCRMediaFetcher : NSObject

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration storage:(IOCipher *)ioCipher;

- (void)downloadMediaItem:(SCRMediaItem *)mediaItem completionQueue:(dispatch_queue_t)queue completionBlock:(void (^)(NSError *error))completion;

@end
