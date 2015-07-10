//
//  SCRMediaServer.h
//  SecureReader
//
//  Created by David Chiles on 2/27/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOCipher.h"

@interface SCRMediaServer : NSObject

@property (nonatomic, readonly) NSUInteger port;

- (instancetype)initWithIOCipher:(IOCipher *)cipher;

- (void)startOnPort:(uint16_t)port error:(NSError **)error;

@end
