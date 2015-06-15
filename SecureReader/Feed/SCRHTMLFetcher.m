//
//  SCRHTMLFetcher.m
//  SecureReader
//
//  Created by David Chiles on 6/15/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRHTMLFetcher.h"
#import "SCRItem.h"
#import "IOCipher.h"

@interface SCRHTMLFetcher ()

@property (nonatomic, strong) dispatch_queue_t internalQueue;
@property (nonatomic, strong) IOCipher *storage;

@end

@implementation SCRHTMLFetcher

- (instancetype)init
{
    if (self = [super init]) {
        self.internalQueue = dispatch_queue_create("SCRHTMLFetcher-Internal", NULL);
    }
    return self;
}

- (instancetype)initWithStorage:(IOCipher *)storage
{
    if (self = [self init]) {
        self.storage = storage;
    }
    return self;
}

- (void)fetchHTMLFor:(SCRItem *)item completionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(NSError *error))completionBlock
{
    if (!completionBlock) {
        return;
    }
    
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    [self downloadDataFor:item.linkURL completionQueue:self.internalQueue completionBlock:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error && [data length]) {
            [self.storage writeDataToFileAtPath:[item pathForDownloadedHTML] data:data offset:0 error:&error];
        }
        
        //What to do about images?
        
        dispatch_async(completionQueue, ^{
            completionBlock(error);
        });
        
    }];
}

@end
