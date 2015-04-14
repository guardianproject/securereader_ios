//
//  SCRDatabaseManager.h
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YapDatabase.h"

extern NSString *const kSCRAllFeedItemsViewName;
extern NSString *const kSCRAllFeedItemsUngroupedViewName;
extern NSString *const kSCRFavoriteFeedItemsViewName;
extern NSString *const kSCRReceivedFeedItemsViewName;
extern NSString *const kSCRAllFeedsViewName;
extern NSString *const kSCRSubscribedFeedsViewName;
extern NSString *const kSCRUnsubscribedFeedsViewName;
extern NSString *const kSCRAllFeedsSearchViewName;
extern NSString *const kSCRRelationshipExtensionName;
extern NSString *const kSCRAllPostItemsViewName;

extern NSString *const SCRRemoveYapConnectionsNotification;

@interface SCRDatabaseManager : NSObject

@property (nonatomic, strong, readonly) YapDatabase *database;

@property (nonatomic, strong, readonly) YapDatabaseConnection *readConnection;
@property (nonatomic, strong, readonly) YapDatabaseConnection *readWriteConnection;

- (instancetype) initWithPath:(NSString *)path;

/** Removes all connections and nils out database */
- (void) teardownDatabase;

+ (instancetype) sharedInstance;

/** Default path for database */
+ (NSString *) defaultDatabasePath;
/** Checks if database file has been created */
+ (BOOL) databaseExists;

@end
