//
//  NSUserDefaults+SecureReader.m
//  SecureReader
//
//  Created by David Chiles on 4/3/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "NSUserDefaults+SecureReader.h"

@implementation NSUserDefaults (SecureReader)

- (BOOL)scr_useTor
{
    return [[self objectForKey:@"useTor"] boolValue];
}

@end
