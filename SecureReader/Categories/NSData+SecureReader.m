//
//  NSData+SecureReader.m
//  SecureReader
//
//  Created by David Chiles on 3/10/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "NSData+SecureReader.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSData (SecureReader)

- (NSString *)scr_sha1
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(self.bytes, (CC_LONG)self.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

@end
