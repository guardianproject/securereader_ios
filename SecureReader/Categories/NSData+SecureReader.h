//
//  NSData+SecureReader.h
//  SecureReader
//
//  Created by David Chiles on 3/10/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SecureReader)

- (NSString *)scr_sha1;

@end
