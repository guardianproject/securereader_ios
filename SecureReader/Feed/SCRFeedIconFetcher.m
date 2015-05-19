//
//  SCRFeedIconFetcher.m
//  SecureReader
//
//  Created by David Chiles on 5/18/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFeedIconFetcher.h"

@implementation SCRFeedIconFetcher

- (instancetype) initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    if (self = [self init]) {
        self.urlSessionConfiguration = configuration;
    }
    return self;
}

- (void)fetchIconForURL:(NSURL *)url completionQueue:(dispatch_queue_t)queue completion:(void (^)(UIImage *, NSError *))completion
{
    if (!queue) {
        queue = dispatch_get_main_queue();
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *scheme = [url scheme];
        NSString *hostname = [url host];
        
        if (([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) && [hostname length])
        {
            NSURL *faviconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/favicon.ico",scheme,hostname]];
            
            [self.networkOperationQueue addOperationWithBlock:^{
                NSURLSession *session = [NSURLSession sessionWithConfiguration:self.urlSessionConfiguration];
                NSURLSessionDataTask *dataTask = [session dataTaskWithURL:faviconURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        dispatch_async(queue, ^{
                            completion(nil,error);
                        });
                    }
                    else {
                        UIImage *image = [UIImage imageWithData:data];
                        dispatch_async(queue, ^{
                            completion(image,nil);
                        });
                    }
                }];
                [dataTask resume];
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
