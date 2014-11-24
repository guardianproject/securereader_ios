//
//  SCRDatabaseManager.m
//  SecureReader
//
//  Created by Christopher Ballinger on 11/17/14.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRDatabaseManager.h"
#import "YapDatabaseView.h"
#import "SCRItem.h"

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


+ (instancetype) sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}


@end
