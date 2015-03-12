//
//  SCRDatabaseManager.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRDatabaseManager.h"
#import "YapDatabaseView.h"
#import "YapDatabaseRelationship.h"
#import "YapDatabaseFullTextSearch.h"
#import "YapDatabaseSearchResultsView.h"
#import "YapDatabaseFilteredView.h"
#import "SCRItem.h"
#import "SCRFeed.h"

NSString *const kSCRAllFeedItemsViewName = @"kSCRAllFeedItemsViewName";
NSString *const kSCRAllFeedItemsUngroupedViewName = @"kSCRAllFeedItemsUngroupedViewName";
NSString *const kSCRFavoriteFeedItemsViewName = @"kSCRFavoriteFeedItemsViewName";
NSString *const kSCRReceivedFeedItemsViewName = @"kSCRReceivedFeedItemsViewName";
NSString *const kSCRAllFeedsViewName = @"kSCRAllFeedsViewName";
NSString *const kSCRSubscribedFeedsViewName = @"kSCRSubscribedFeedsViewName";
NSString *const kSCRUnsubscribedFeedsViewName = @"kSCRUnsubscribedFeedsViewName";
NSString *const kSCRAllFeedsSearchViewName = @"kSCRAllFeedsSearchViewName";
NSString *const kSCRRelationshipExtensionName = @"kSCRRelationshipExtensionName";

@implementation SCRDatabaseManager

- (instancetype) init
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    NSString *databaseDirectoryName = @"SecureReader.database";
    NSString *databaseDirectoryPath = [applicationSupportDirectory stringByAppendingPathComponent:databaseDirectoryName];
    NSString *databaseName = @"SecureReader.sqlite";
    
    return [self initWithPath:[databaseDirectoryPath stringByAppendingPathComponent:databaseName]];
}

- (instancetype) initWithPath:(NSString *)path {
    if (self = [super init]) {
        NSAssert([path length] > 0, @"Required path");
        
        NSString *directory = [path stringByDeletingLastPathComponent];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        
        YapDatabaseOptions *options = [[YapDatabaseOptions alloc] init];
        options.corruptAction = YapDatabaseCorruptAction_Fail;
        options.passphraseBlock = ^{
            // Fetch from keychain or in-memory passphrase
            NSString *passphrase = @"super secure password";
            if (!passphrase.length) {
                [NSException raise:@"Must have passphrase of length > 0" format:@"password length is %d.", (int)passphrase.length];
            }
            return passphrase;
        };
        _database = [[YapDatabase alloc] initWithPath:path objectSerializer:nil objectDeserializer:nil metadataSerializer:nil metadataDeserializer:nil objectSanitizer:nil metadataSanitizer:nil options:options];
        self.database.defaultObjectCacheEnabled = YES;
        self.database.defaultObjectCacheLimit = 5000;
        self.database.defaultObjectPolicy = YapDatabasePolicyShare;
        _readWriteConnection = [self.database newConnection];
        _readConnection = [self.database newConnection];
        [self registerViews];
    }
    return self;
}

- (void) registerViews {
    
    YapDatabaseRelationship *databaseRelationship = [[YapDatabaseRelationship alloc] init];
    [self.database registerExtension:databaseRelationship withName:kSCRRelationshipExtensionName];
    [self registerAllFeedItemsView];
    [self registerAllFeedItemsUngroupedView];
    [self registerAllFeedsView];
    [self registerAllFeedsSearchView];
}

- (void) registerAllFeedItemsView {
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[SCRItem class]]) {
            SCRItem *item = object;
            return item.yapGroup;
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, SCRItem *item1, NSString *collection2, NSString *key2, SCRItem *item2) {
        return [item2.publicationDate compare:item1.publicationDate];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"3" options:nil];
    [self.database asyncRegisterExtension:databaseView withName:kSCRAllFeedItemsViewName completionBlock:^(BOOL ready) {
        [self registerFavoriteFeedItemsView];
        [self registerReceivedFeedItemsView];
    }];
}

- (void) registerAllFeedItemsUngroupedView {
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[SCRItem class]]) {
            return @"All";
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, SCRItem *item1, NSString *collection2, NSString *key2, SCRItem *item2) {
        return [item2.publicationDate compare:item1.publicationDate];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"1" options:nil];
    [self.database asyncRegisterExtension:databaseView withName:kSCRAllFeedItemsUngroupedViewName completionBlock:^(BOOL ready) {
        NSLog(@"%@ ready %d",kSCRAllFeedItemsUngroupedViewName, ready);
    }];
}

- (void) registerFavoriteFeedItemsView {
    
    YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(NSString *group, NSString *collection, NSString *key, id object) {
        SCRItem *item = object;
        if (item.isFavorite) {
            return YES;
        }
        return NO;
    }];
    
    YapDatabaseFilteredView *filteredView =
    [[YapDatabaseFilteredView alloc] initWithParentViewName:kSCRAllFeedItemsViewName
                                             filtering:filtering];
    
    [self.database asyncRegisterExtension:filteredView withName:kSCRFavoriteFeedItemsViewName completionBlock:^(BOOL ready) {
        NSLog(@"%@ ready %d", kSCRFavoriteFeedItemsViewName, ready);
    }];
}

- (void) registerReceivedFeedItemsView {
    YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(NSString *group, NSString *collection, NSString *key, id object) {
        SCRItem *item = object;
        if (item.isReceived) {
            return YES;
        }
        return NO;
    }];
    YapDatabaseFilteredView *filteredView =
    [[YapDatabaseFilteredView alloc] initWithParentViewName:kSCRAllFeedItemsViewName
                                                  filtering:filtering];
    [self.database asyncRegisterExtension:filteredView withName:kSCRReceivedFeedItemsViewName completionBlock:^(BOOL ready) {
        NSLog(@"%@ ready %d", kSCRReceivedFeedItemsViewName, ready);
    }];
}

- (void) registerAllFeedsView {
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[SCRFeed class]]) {
            SCRFeed *item = object;
            return item.yapGroup;
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, SCRFeed *item1, NSString *collection2, NSString *key2, SCRFeed *item2) {
        return [item1.title compare:item2.title];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"1" options:nil];
    [self.database asyncRegisterExtension:databaseView withName:kSCRAllFeedsViewName completionBlock:^(BOOL ready) {
        NSLog(@"%@ ready %d", kSCRAllFeedsViewName, ready);
        
        YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL (NSString *group, NSString *collection, NSString *key, id object)
        {
            return [(SCRFeed *)object subscribed];
        }];
        
        YapDatabaseFilteredView *subscribedFeedsView = [[YapDatabaseFilteredView alloc] initWithParentViewName:kSCRAllFeedsViewName filtering:filtering];
        [self.database asyncRegisterExtension:subscribedFeedsView withName:kSCRSubscribedFeedsViewName completionBlock:^(BOOL ready) {
            NSLog(@"%@ ready %d", kSCRSubscribedFeedsViewName, ready);
        }];
        
        filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL (NSString *group, NSString *collection, NSString *key, id object)
                                               {
                                                   return ![(SCRFeed *)object subscribed];
                                               }];
        
        YapDatabaseFilteredView *unsubscribedFeedsView = [[YapDatabaseFilteredView alloc] initWithParentViewName:kSCRAllFeedsViewName filtering:filtering];
        [self.database asyncRegisterExtension:unsubscribedFeedsView withName:kSCRUnsubscribedFeedsViewName completionBlock:^(BOOL ready) {
            NSLog(@"%@ ready %d", kSCRUnsubscribedFeedsViewName, ready);
        }];

    }];
}

- (void) registerAllFeedsSearchView {
    
    YapDatabaseFullTextSearchHandler *fullTextSearchHandler = [YapDatabaseFullTextSearchHandler withObjectBlock:^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[SCRFeed class]]) {
            SCRFeed *feed = (SCRFeed *)object;
            [dict setObject:feed.title forKey:@"title"];
            [dict setObject:feed.feedDescription forKey:@"description"];
        }
    }];
    
    YapDatabaseFullTextSearch *fts = [[YapDatabaseFullTextSearch alloc] initWithColumnNames:@[@"title", @"description"]
                                                                                    handler:fullTextSearchHandler
                                                                                 versionTag:@"2"];
    
    [self.database asyncRegisterExtension:fts withName:@"SCRAllFeedsSearchViewNameFTS" completionBlock:^(BOOL ready) {
        YapDatabaseSearchResultsViewOptions *searchViewOptions = [[YapDatabaseSearchResultsViewOptions alloc] init];
        searchViewOptions.isPersistent = NO;
        YapDatabaseSearchResultsView *searchResultsView =
        [[YapDatabaseSearchResultsView alloc] initWithFullTextSearchName:@"SCRAllFeedsSearchViewNameFTS"
                                                          parentViewName:kSCRAllFeedsViewName
                                                              versionTag:@"1"
                                                                 options:searchViewOptions];
        [self.database asyncRegisterExtension:searchResultsView withName:kSCRAllFeedsSearchViewName completionBlock:^(BOOL ready) {
            NSLog(@"%@ ready %d", kSCRAllFeedsSearchViewName, ready);
        }];
    }];
}

+ (instancetype) sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}


@end
