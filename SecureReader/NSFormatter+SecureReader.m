//
//  NSFormatter+SecureReader.m
//  SecureReader
//
//  Created by Christopher Ballinger on 2/8/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "NSFormatter+SecureReader.h"

@implementation NSFormatter (SecureReader)

+ (TTTTimeIntervalFormatter*) scr_sharedIntervalFormatter {
    static TTTTimeIntervalFormatter *_intervalFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _intervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
    });
    return _intervalFormatter;
}

@end
