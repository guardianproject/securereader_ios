//
//  NSFormatter+SecureReader.h
//  SecureReader
//
//  Created by Christopher Ballinger on 2/8/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTTTimeIntervalFormatter.h"

@interface NSFormatter (SecureReader)

+ (TTTTimeIntervalFormatter*) scr_sharedIntervalFormatter;

@end
