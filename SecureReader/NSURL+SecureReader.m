//
//  NSURL+SecureReader.m
//  SecureReader
//
//  Created by David Chiles on 7/29/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "NSURL+SecureReader.h"

@implementation NSURL (SecureReader)


//http://stackoverflow.com/questions/8756683/best-way-to-parse-url-string-to-get-values-for-keys
- (NSString *)scr_wordpressPostID
{
    NSArray *urlComponents = [self.absoluteString componentsSeparatedByString:@"&"];
    
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        
        if([key isEqualToString:@"p"]   ) {
            return value;
        }
    }
    return nil;
}

@end
