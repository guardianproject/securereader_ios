//
//  SCRReadabilityScoreFetcher.m
//  SecureReader
//
//  Created by David Chiles on 8/31/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRReadabilityScoreFetcher.h"

NSString *const kSCRScoreURLString = @"https://securereader.guardianproject.info/readability/score_feed.php";

@implementation SCRReadabilityScoreFetcher

- (void)fetchScoreForURL:(NSURL *)url language:(NSString *)language completionQueue:(dispatch_queue_t)completionQueue completionBlock:(void (^)(NSNumber *, NSError *))completionBlock
{
    if(!completionBlock) {
        return;
    }
    
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    if (!url) {
        dispatch_async(completionQueue, ^{
            completionBlock(nil, [NSError errorWithDomain:@"info.guardianproject.SecureReader" code:124 userInfo:@{NSLocalizedDescriptionKey: @"No URL supplied!"}]);
        });
        return;
    }
    
    __block NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:kSCRScoreURLString] resolvingAgainstBaseURL:YES];
    
    if (![language length]) {
        language = @"en_US";
    }
    
    NSString *parameters = [NSString stringWithFormat:@"lang=%@&feed=%@",language,url.absoluteString];
    components.query = parameters;
    
    __weak typeof(self)weakSelf = self;
    [self.networkOperationQueue addOperationWithBlock:^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        NSURLSession *session = [NSURLSession sessionWithConfiguration:strongSelf.urlSessionConfiguration];
        NSURLSessionDataTask *dataTask = [session dataTaskWithURL:components.URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                dispatch_async(completionQueue, ^{
                    completionBlock(nil,error);
                });
            } else {
                NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error) {
                    dispatch_async(completionQueue, ^{
                        completionBlock(nil,error);
                    });
                }
                
                //I can't belive it's not a BOOL
                if ([jsonResponse[@"sucess"] isEqualToString:@"false"]) {
                    
                    NSString *description = @"Unable to parse supplied feed";
                    if ([jsonResponse[@"message"] length]) {
                        description = jsonResponse[@"message"];
                    }
                    
                    dispatch_async(completionQueue, ^{
                        completionBlock(nil, [NSError errorWithDomain:@"info.guardianproject.SecureReader" code:124 userInfo:@{NSLocalizedDescriptionKey: description}]);
                    });
                } else {
                    id score = jsonResponse[@"readability_score"];
                    if ([score isKindOfClass:[NSNumber class]]) {
                        dispatch_async(completionQueue, ^{
                            completionBlock(score,nil);
                        });
                    }
                }
            }
        }];
        [dataTask resume];
    }];
}

@end
