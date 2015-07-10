//
//  SCRFeedIconFetcher.m
//  SecureReader
//
//  Created by David Chiles on 5/18/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFeedIconFetcher.h"

@implementation SCRFeedIconFetcher

- (void)fetchIconForURL:(NSURL *)url completionQueue:(dispatch_queue_t)queue completion:(void (^)(UIImage *, NSError *))completion
{
    if (!completion) {
        return;
    }
    if (!queue) {
        queue = dispatch_get_main_queue();
    }
    if (!url) {
        dispatch_async(queue, ^{
            completion(nil, [NSError errorWithDomain:@"info.guardianproject.SecureReader" code:124 userInfo:@{NSLocalizedDescriptionKey: @"No URL supplied!"}]);
        });
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *scheme = [url scheme];
        NSString *hostname = [url host];
        
        if (([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) && [hostname length])
        {
            NSURL *faviconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/favicon.ico",scheme,hostname]];
            
            [self downloadDataFor:faviconURL completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionBlock:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    dispatch_async(queue, ^{
                        completion(nil,error);
                    });
                }
                else {
                    UIImage *image = [UIImage imageWithData:data];
                    if (image) {
                        dispatch_async(queue, ^{
                            completion(image,nil);
                        });
                    } else {
                        dispatch_async(queue, ^{
                            completion(nil, [NSError errorWithDomain:@"info.guardianproject.SecureReader" code:123 userInfo:@{NSLocalizedDescriptionKey: @"Error decoding UIImage from NSData"}]);
                        });
                    }
                    
                }
            }];
        } else {
            //Error
            dispatch_async(queue, ^{
                completion(nil,nil);
            });
        }
    });
}

@end
