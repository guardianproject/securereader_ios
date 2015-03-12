//
//  SCRDatabaseManager.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YapDatabase.h"

@interface SCRDatabaseManager : NSObject

@property (nonatomic, strong, readonly) YapDatabase *database;

@property (nonatomic, strong, readonly) YapDatabaseConnection *readConnection;
@property (nonatomic, strong, readonly) YapDatabaseConnection *readWriteConnection;

@property (nonatomic, strong, readonly) NSString *allFeedItemsViewName;
@property (nonatomic, strong, readonly) NSString *allFeedItemsUngroupedViewName;
@property (nonatomic, strong, readonly) NSString *favoriteFeedItemsViewName;
@property (nonatomic, strong, readonly) NSString *receivedFeedItemsViewName;
@property (nonatomic, strong, readonly) NSString *allFeedsViewName;
@property (nonatomic, strong, readonly) NSString *subscribedFeedsViewName;
@property (nonatomic, strong, readonly) NSString *unsubscribedFeedsViewName;
@property (nonatomic, strong, readonly) NSString *allFeedsSearchViewName;

- (instancetype) initWithPath:(NSString *)path;

+ (instancetype) sharedInstance;

@end
