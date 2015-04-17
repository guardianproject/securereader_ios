//
//  SecureReaderYapTests.m
//  SecureReader
//
//  Created by David Chiles on 3/11/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SCRDatabaseManager.h"
#import "SCRFeedFetcher.h"
#import "URLMock.h"
#import "SCRMediaItem.h"
#import "SCRItem.h"
#import "SCRFeed.h"
#import "SCRPassphraseManager.h"

@interface SecureReaderYapTests : XCTestCase

@property (nonatomic, strong) SCRDatabaseManager *databaseManager;

@end

NSString *const kSecureReaderYapTestsRSSURL = @"http://test.fake/rss";

@implementation SecureReaderYapTests

- (void)setUp {
    [super setUp];
    
    
    //Cleanup any items in temporary directory
    NSString *directory = NSTemporaryDirectory();
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directory];
    
    NSString *file = nil;
    while (file = [enumerator nextObject]) {
        [[NSFileManager defaultManager] removeItemAtPath:[directory stringByAppendingPathComponent:file] error:nil];
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)setupDatabseAtPath:(NSString *)path
{
    //Need to setup a different database per method becuase yap has static variable it checks
    [[SCRPassphraseManager sharedInstance] setDatabasePassphrase:@"password" storeInKeychain:NO];
    self.databaseManager = [[SCRDatabaseManager alloc] initWithPath:path];
    
    XCTAssertNotNil(self.databaseManager.database,@"No database");
    XCTAssertNotNil(self.databaseManager.readConnection,@"No read connection");
    XCTAssertNotNil(self.databaseManager.readWriteConnection,@"No read/write connection");
}

- (NSURLSessionConfiguration *)setupURLMock
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    [UMKMockURLProtocol enable];
    configuration.protocolClasses = @[[UMKMockURLProtocol class]];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"nytimes" ofType:@"xml"];
    __block NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
    UMKMockHTTPResponder *responder = [UMKMockHTTPResponder mockHTTPResponderWithStatusCode:200 body:data];
    UMKMockHTTPRequest *request = [UMKMockHTTPRequest mockHTTPGetRequestWithURL:[NSURL URLWithString:kSecureReaderYapTestsRSSURL]];
    request.responder = responder;
    
    [UMKMockURLProtocol expectMockRequest:request];
    
    
    return configuration;
}

- (void)importDefaultFeed:(void (^)(NSError *error))completion
{
    YapDatabaseConnection *connection = [self.databaseManager.database newConnection];
    NSURLSessionConfiguration *configuration = [self setupURLMock];
    SCRFeedFetcher *feedFetcher = [[SCRFeedFetcher alloc] initWithReadWriteYapConnection:connection sessionConfiguration:configuration];
    
    NSURL *url = [NSURL URLWithString:kSecureReaderYapTestsRSSURL];
    
    [feedFetcher fetchFeedDataFromURL:url completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:completion];
}

- (void)testStorage {
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    [self setupDatabseAtPath:path];
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self importDefaultFeed:^(NSError *error) {
        XCTAssertNil(error,@"Error fetching feed");
        
        [[self.databaseManager.database newConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            
            __block int numberOfFeeds = 0;
            [transaction enumerateKeysAndObjectsInCollection:[SCRFeed yapCollection] usingBlock:^(NSString *key, id object, BOOL *stop) {
                
                XCTAssertTrue([object isKindOfClass:[SCRFeed class]],@"Feed is not SCRFeed");
                SCRFeed *feed = (SCRFeed *)object;
                
                XCTAssertNotNil(feed.feedDescription);
                XCTAssertNotNil(feed.xmlURL);
                XCTAssertNotNil(feed.htmlURL);
                XCTAssertNotNil(feed.title);
                XCTAssertFalse(feed.userAdded);
                XCTAssertFalse(feed.subscribed);
                
                
                numberOfFeeds += 1;
            }];
            
            __block int numberOfItems = 0;
            [transaction enumerateKeysAndObjectsInCollection:[SCRItem yapCollection] usingBlock:^(NSString *key, id object, BOOL *stop) {
                
                XCTAssertTrue([object isKindOfClass:[SCRItem class]],@"Item is not SCRItem");
                SCRItem *item = (SCRItem *)object;
                
                XCTAssertTrue([item.feedYapKey length] > 0 ,@"could not find yap feed key");
                XCTAssertFalse(item.isFavorite,@"Default should be not favorite");
                XCTAssertFalse(item.isReceived,@"Default should be not received");
                XCTAssertNotNil(item.linkURL,@"Could not find link");
                XCTAssertTrue([item.mediaItems count] == 0,@"Should not have stored media Items");
                
                //check if media item key works 
                numberOfItems += 1;
            }];
            
            __block int numberOfMediaItems = 0;
            [transaction enumerateKeysAndObjectsInCollection:[SCRMediaItem yapCollection] usingBlock:^(NSString *key, id object, BOOL *stop) {
                XCTAssertTrue([object isKindOfClass:[SCRMediaItem class]],@"Media item is not SCRMediaItem");
                SCRMediaItem *mediaItem = (SCRMediaItem *)object;
                
                XCTAssertNotNil(mediaItem.url,@"No media Item URL");
                XCTAssertTrue([mediaItem.url.absoluteString length] > 0, @"URL has no length");
                
                numberOfMediaItems += 1;
            }];
            
            XCTAssertEqual(numberOfFeeds, 1, @"Did not find one feed");
            XCTAssertEqual(numberOfItems, 20, @"Did not find all items");
            XCTAssertEqual(numberOfMediaItems, 13, @"Did not find all items");
            
        }];
        
        [expectation fulfill];
    }];
    
    
    [self waitForExpectationsWithTimeout:3000 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error");
        }
    }];
}

- (void)testRelationships
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    [self setupDatabseAtPath:path];
    XCTestExpectation *expectation = [self expectationWithDescription:@"testFetching"];
    [self importDefaultFeed:^(NSError *error) {
        
        __block int numberOfMediaItems = 0;
        __block int numberOfItems = 0;
        [[self.databaseManager.database newConnection] readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            
            [transaction enumerateKeysAndObjectsInCollection:[SCRFeed yapCollection] usingBlock:^(NSString *key, id object, BOOL *stop) {
                XCTAssertTrue([object isKindOfClass:[SCRFeed class]]);
                __block SCRFeed *feed = (SCRFeed *)object;
                
                
                [feed enumerateItemsInTransaction:transaction block:^(SCRItem *item, BOOL *stop) {
                    XCTAssertTrue([item isKindOfClass:[SCRItem class]]);
                    XCTAssertTrue([item.feedYapKey isEqualToString:feed.yapKey]);
                    numberOfItems += 1;
                }];
            }];
            
            [transaction enumerateKeysAndObjectsInCollection:[SCRItem yapCollection] usingBlock:^(NSString *key, id object, BOOL *stop) {
                XCTAssertTrue([object isKindOfClass:[SCRItem class]]);
                __block SCRItem *item = (SCRItem *)object;
                
                [item enumerateMediaItemsInTransaction:transaction block:^(SCRMediaItem *mediaItem, BOOL *stop) {
                    XCTAssertTrue([mediaItem isKindOfClass:[SCRMediaItem class]],@"Not correct media item class");
                    XCTAssertTrue([item.mediaItemsYapKeys containsObject:mediaItem.yapKey],@"Key is not in item");
                    numberOfMediaItems += 1;
                }];
            }];
            
            [transaction enumerateKeysAndObjectsInCollection:[SCRMediaItem yapCollection] usingBlock:^(NSString *key, id object, BOOL *stop) {
                XCTAssertTrue([object isKindOfClass:[SCRMediaItem class]]);
                __block SCRMediaItem *mediaItem = (SCRMediaItem *)object;
                
                [mediaItem enumerateItemsInTransaction:transaction block:^(SCRItem *item, BOOL *stop) {
                    XCTAssertTrue([item isKindOfClass:[SCRItem class]],@"Not correct item class");
                    XCTAssertTrue([item.mediaItemsYapKeys containsObject:mediaItem.yapKey],@"Key is not in item");
                }];
            }];
            
            
            
        }];
        
        XCTAssertEqual(numberOfItems, 20);
        XCTAssertEqual(numberOfMediaItems,13, @"Not all media items found");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error");
        }
    }];
}

- (void)testDelete
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    
    [self setupDatabseAtPath:path];
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    [self importDefaultFeed:^(NSError *error) {
        
        YapDatabaseConnection *connection = [self.databaseManager.database newConnection];
        [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            
            NSMutableArray *feeds = [NSMutableArray array];
            [transaction enumerateKeysAndObjectsInCollection:[SCRFeed yapCollection] usingBlock:^(NSString *key, id object, BOOL *stop) {
                XCTAssertTrue([object isKindOfClass:[SCRFeed class]]);
                SCRFeed *feed = (SCRFeed *)object;
                [feeds addObject:feed];
            }];
            
            XCTAssertEqual([feeds count], 1);
            
            for (SCRFeed *feed in feeds) {
                [SCRFeed removeFeed:feed inTransaction:transaction storage:nil];
            }
        }];
        
        [connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [transaction enumerateKeysInAllCollectionsUsingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
                XCTAssertTrue(NO,@"There should not be anything in the databse");
            }];
        }];
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:500 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error");
        }
    }];
}

@end
