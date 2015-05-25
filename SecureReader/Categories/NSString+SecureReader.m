//
//  NSString+SecureReader.m
//  SecureReader
//
//  Created by N-Pex on 2015-05-25.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "NSData+SecureReader.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (SecureReader)

- (NSString *)scr_md5
{
    // Create pointer to the string as UTF8
    const char *ptr = [self UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end
