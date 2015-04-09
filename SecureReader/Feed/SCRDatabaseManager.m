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
#import "SCRPostItem.h"
#import "SSKeychain.h"

NSString *const kSCRAllFeedItemsViewName = @"kSCRAllFeedItemsViewName";
NSString *const kSCRAllFeedItemsUngroupedViewName = @"kSCRAllFeedItemsUngroupedViewName";
NSString *const kSCRFavoriteFeedItemsViewName = @"kSCRFavoriteFeedItemsViewName";
NSString *const kSCRReceivedFeedItemsViewName = @"kSCRReceivedFeedItemsViewName";
NSString *const kSCRAllFeedsViewName = @"kSCRAllFeedsViewName";
NSString *const kSCRSubscribedFeedsViewName = @"kSCRSubscribedFeedsViewName";
NSString *const kSCRUnsubscribedFeedsViewName = @"kSCRUnsubscribedFeedsViewName";
NSString *const kSCRAllFeedsSearchViewName = @"kSCRAllFeedsSearchViewName";
NSString *const kSCRRelationshipExtensionName = @"kSCRRelationshipExtensionName";
NSString *const kSCRAllPostItemsViewName = @"kSCRAllPostItemsViewName";

static NSString * const SCRDatabasePassphraseKey    = @"SCRDatabasePassphraseKey";

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
        options.cipherKeyBlock = ^{
            NSString *passphrase = [self databasePassphrase];
            NSData *passphraseData = [passphrase dataUsingEncoding:NSUTF8StringEncoding];
            if (!passphraseData.length) {
                [NSException raise:@"Must have passphrase of length > 0" format:@"password length is %d.", (int)passphrase.length];
            }
            return passphraseData;
        };
        _database = [[YapDatabase alloc] initWithPath:path serializer:nil deserializer:nil options:options];
        self.database.defaultObjectCacheEnabled = YES;
        self.database.defaultObjectCacheLimit = 5000;
        self.database.defaultObjectPolicy = YapDatabasePolicyShare;
        _readWriteConnection = [self.database newConnection];
        _readConnection = [self.database newConnection];
        [self registerViews];
    }
    return self;
}

/** Returns db passphrase from keychain (will generate if needed) */
- (NSString*) databasePassphrase {
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    NSString *passphrase = [SSKeychain passwordForService:SCRDatabasePassphraseKey account:SCRDatabasePassphraseKey];
    if (!passphrase.length) {
        // no passphrase found, generating new one
        int passphraseBytes = 30;
        NSMutableData* passphraseData = [NSMutableData dataWithLength:passphraseBytes];
        SecRandomCopyBytes(kSecRandomDefault, passphraseBytes, [passphraseData mutableBytes]);
        passphrase = [passphraseData base64EncodedStringWithOptions:0];
        [SSKeychain setPassword:passphrase forService:SCRDatabasePassphraseKey account:SCRDatabasePassphraseKey];
    }
    NSAssert(passphrase.length > 0, @"Must have a passphrase!");
    return passphrase;
}


- (void) registerViews {
    
    YapDatabaseRelationship *databaseRelationship = [[YapDatabaseRelationship alloc] init];
    [self.database registerExtension:databaseRelationship withName:kSCRRelationshipExtensionName];
    [self registerAllFeedItemsView];
    [self registerAllFeedItemsUngroupedView];
    [self registerAllFeedsView];
    [self registerAllFeedsSearchView];
    [self registerAllPostItemsView];
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
    [self.database registerExtension:databaseView withName:kSCRAllFeedItemsViewName];
    [self registerFavoriteFeedItemsView];
    [self registerReceivedFeedItemsView];
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
    [self.database registerExtension:databaseView withName:kSCRAllFeedItemsUngroupedViewName];
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
    
    [self.database registerExtension:filteredView withName:kSCRFavoriteFeedItemsViewName];
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
    [self.database registerExtension:filteredView withName:kSCRReceivedFeedItemsViewName];
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
    
    [self.database registerExtension:databaseView withName:kSCRAllFeedsViewName];
        
    YapDatabaseViewFiltering *filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL (NSString *group, NSString *collection, NSString *key, id object)
    {
        return [(SCRFeed *)object subscribed];
    }];
    
    YapDatabaseFilteredView *subscribedFeedsView = [[YapDatabaseFilteredView alloc] initWithParentViewName:kSCRAllFeedsViewName filtering:filtering];
    
    [self.database registerExtension:subscribedFeedsView withName:kSCRSubscribedFeedsViewName];
    
    filtering = [YapDatabaseViewFiltering withObjectBlock:^BOOL (NSString *group, NSString *collection, NSString *key, id object)
                                           {
                                               return ![(SCRFeed *)object subscribed];
                                           }];
    
    YapDatabaseFilteredView *unsubscribedFeedsView = [[YapDatabaseFilteredView alloc] initWithParentViewName:kSCRAllFeedsViewName filtering:filtering];
    [self.database registerExtension:unsubscribedFeedsView withName:kSCRUnsubscribedFeedsViewName];
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
    
    [self.database registerExtension:fts withName:@"SCRAllFeedsSearchViewNameFTS"];

    YapDatabaseSearchResultsViewOptions *searchViewOptions = [[YapDatabaseSearchResultsViewOptions alloc] init];
    searchViewOptions.isPersistent = NO;
    YapDatabaseSearchResultsView *searchResultsView =
    [[YapDatabaseSearchResultsView alloc] initWithFullTextSearchName:@"SCRAllFeedsSearchViewNameFTS"
                                                      parentViewName:kSCRAllFeedsViewName
                                                          versionTag:@"1"
                                                             options:searchViewOptions];
    [self.database registerExtension:searchResultsView withName:kSCRAllFeedsSearchViewName];
}

- (void) registerAllPostItemsView {
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[SCRPostItem class]]) {
            SCRPostItem *item = object;
            return item.yapGroup;
        }
        return nil;
    }];
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, SCRPostItem *item1, NSString *collection2, NSString *key2, SCRPostItem *item2) {
        return [item2.lastEdited compare:item1.lastEdited];
    }];
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting versionTag:@"1" options:nil];
    [self.database registerExtension:databaseView withName:kSCRAllPostItemsViewName];
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
