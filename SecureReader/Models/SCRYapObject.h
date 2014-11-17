//
//  SCRYapObject.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCRYapObject <NSObject>

- (NSString*) yapKey;
- (NSString*) yapGroup;
+ (NSString*) yapCollection;

@end
