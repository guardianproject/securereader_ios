//
//  SCRHTMLFetcher.h
//  SecureReader
//
//  Created by David Chiles on 6/15/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRNetworkFetcher.h"

@class SCRItem, IOCipher;

@interface SCRHTMLFetcher : SCRNetworkFetcher

- (instancetype)initWithStorage:(IOCipher *)storage;

- (void)fetchHTMLFor:(SCRItem *)item completionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(NSError *error))completionBlock;

@end
