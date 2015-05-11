//
//  SCRPanicController.h
//  SecureReader
//
//  Created by David Chiles on 5/11/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCRPanicController : NSObject

+ (void)clearAllDataCompletionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(NSError *error))completionBlock;

@end
