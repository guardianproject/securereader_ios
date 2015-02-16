//
//  SCRDatabaseManager.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRDatabaseManager.h"
#import "YapDatabaseView.h"
#import "YapDatabaseFullTextSearch.h"
#import "YapDatabaseSearchResultsView.h"
#import "YapDatabaseFilteredView.h"
#import "SCRItem.h"
#import "SCRFeed.h"

@implementation SCRDatabaseManager

- (instancetype) init {
    if (self = [super init]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *applicationSupportDirectory = [paths firstObject];
        NSString *databaseDirectoryName = @"SecureReader.database";
        NSString *databaseDirectoryPath = [applicationSupportDirectory stringByAppendingPathComponent:databaseDirectoryName];
        [[NSFileManager defaultManager] createDirectoryAtPath:databaseDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *databaseName = @"SecureReader.sqlite";
        NSString *databasePath = [databaseDirectoryPath stringByAppendingPathComponent:databaseName];
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
        _database = [[YapDatabase alloc] initWithPath:databasePath objectSerializer:nil objectDeserializer:nil metadataSerializer:nil metadataDeserializer:nil objectSanitizer:nil metadataSanitizer:nil options:options];
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
    [self registerAllFeedItemsView];
    [self registerFavoriteFeedItemsView];
    [self registerAllFeedsView];
    [self registerAllFeedsSearchView];
}

- (void) registerAllFeedItemsView {
    _allFeedItemsViewName = @"SRCAllFeedItemsViewName";
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[SCRItem class]]) {
            SCRItem *item = object;
            return item.yapGroup;
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, SCRItem *item1, NSString *collection2, NSString *key2, SCRItem *item2) {
        return [item1.publicationDate compare:item2.publicationDate];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"1" options:nil];
    [self.database asyncRegisterExtension:databaseView withName:self.allFeedItemsViewName completionBlock:^(BOOL ready) {
        NSLog(@"%@ ready %d", self.allFeedItemsViewName, ready);
    }];
}

- (void) registerFavoriteFeedItemsView {
    _favoriteFeedItemsViewName = @"SRCFavoriteFeedItemsViewName";
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[SCRItem class]]) {
            SCRItem *item = object;
            if ([item isFavorite])
                return item.yapGroup;
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, SCRItem *item1, NSString *collection2, NSString *key2, SCRItem *item2) {
        return [item1.publicationDate compare:item2.publicationDate];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"1" options:nil];
    [self.database asyncRegisterExtension:databaseView withName:self.favoriteFeedItemsViewName completionBlock:^(BOOL ready) {
        NSLog(@"%@ ready %d", self.favoriteFeedItemsViewName, ready);
    }];
}

- (void) registerAllFeedsView {
    _allFeedsViewName = @"SCRAllFeedsViewName";
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
    [self.database asyncRegisterExtension:databaseView withName:self.allFeedsViewName completionBlock:^(BOOL ready) {
        NSLog(@"%@ ready %d", self.allFeedsViewName, ready);
        
        _subscribedFeedsViewName = @"SCRSubscribedFeedsViewName";
        YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL (NSString *group, NSString *collection, NSString *key, id object)
        {
            return [(SCRFeed *)object subscribed];
        }];
        
        YapDatabaseFilteredView *subscribedFeedsView = [[YapDatabaseFilteredView alloc] initWithParentViewName:_allFeedsViewName filtering:filtering];
        [self.database asyncRegisterExtension:subscribedFeedsView withName:self.subscribedFeedsViewName completionBlock:^(BOOL ready) {
            NSLog(@"%@ ready %d", self.subscribedFeedsViewName, ready);
        }];
        
        _unsubscribedFeedsViewName = @"SCRUnSubscribedFeedsViewName";
        filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL (NSString *group, NSString *collection, NSString *key, id object)
                                               {
                                                   return ![(SCRFeed *)object subscribed];
                                               }];
        
        YapDatabaseFilteredView *unsubscribedFeedsView = [[YapDatabaseFilteredView alloc] initWithParentViewName:_allFeedsViewName filtering:filtering];
        [self.database asyncRegisterExtension:unsubscribedFeedsView withName:self.unsubscribedFeedsViewName completionBlock:^(BOOL ready) {
            NSLog(@"%@ ready %d", self.unsubscribedFeedsViewName, ready);
        }];

    }];
}

- (void) registerAllFeedsSearchView {
    _allFeedsSearchViewName = @"SCRAllFeedsSearchViewName";
    YapDatabaseFullTextSearchBlockType ftsBlockType = YapDatabaseFullTextSearchBlockTypeWithObject;
    YapDatabaseFullTextSearchWithObjectBlock ftsBlock =
    ^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object){
        if ([object isKindOfClass:[SCRFeed class]]) {
            SCRFeed *feed = (SCRFeed *)object;
            [dict setObject:feed.title forKey:@"title"];
            [dict setObject:feed.feedDescription forKey:@"description"];
        }
    };
    YapDatabaseFullTextSearch *fts =
    [[YapDatabaseFullTextSearch alloc] initWithColumnNames:@[ @"title", @"description" ]
                                                     block:ftsBlock
                                                 blockType:ftsBlockType
                                                versionTag:@"2"];
    [self.database asyncRegisterExtension:fts withName:@"SCRAllFeedsSearchViewNameFTS" completionBlock:^(BOOL ready) {
        YapDatabaseSearchResultsViewOptions *searchViewOptions = [[YapDatabaseSearchResultsViewOptions alloc] init];
        searchViewOptions.isPersistent = NO;
        YapDatabaseSearchResultsView *searchResultsView =
        [[YapDatabaseSearchResultsView alloc] initWithFullTextSearchName:@"SCRAllFeedsSearchViewNameFTS"
                                                          parentViewName:_allFeedsViewName
                                                              versionTag:@"1"
                                                                 options:searchViewOptions];
        [self.database asyncRegisterExtension:searchResultsView withName:self.allFeedsSearchViewName completionBlock:^(BOOL ready) {
            NSLog(@"%@ ready %d", self.allFeedsSearchViewName, ready);
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
