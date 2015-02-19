//
//  SCRYapObject.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YapDatabaseReadWriteTransaction;

@protocol SCRYapObject <NSObject>
@required
- (NSString *)yapKey;
- (NSString *)yapGroup;
- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

+ (NSString *)yapCollection;
@end
