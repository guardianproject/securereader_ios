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

@interface SecureReaderYapTests : XCTestCase

@property (nonatomic, strong) SCRDatabaseManager *databaseManager;

@end

NSString *const kSecureReaderYapTestsRSSURL = @"http://test.fake/rss";

@implementation SecureReaderYapTests

- (void)setUp {
    [super setUp];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"yapTest.sqlite"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        XCTAssertNil(error,@"Error removing existing database");
    }
    
    self.databaseManager = [[SCRDatabaseManager alloc] initWithPath:path];
    
    //FIXME Not great that register views happen async in the init method
    XCTestExpectation *expcetation = [self expectationWithDescription:@"datbaseSetup"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNotNil(self.databaseManager.database,@"No database");
        XCTAssertNotNil(self.databaseManager.readConnection,@"No read connection");
        XCTAssertNotNil(self.databaseManager.readWriteConnection,@"No read/write connection");
        XCTAssertNotNil(self.databaseManager.allFeedItemsViewName);
        XCTAssertNotNil(self.databaseManager.allFeedItemsUngroupedViewName);
        XCTAssertNotNil(self.databaseManager.favoriteFeedItemsViewName);
        XCTAssertNotNil(self.databaseManager.receivedFeedItemsViewName);
        XCTAssertNotNil(self.databaseManager.allFeedsSearchViewName);
        XCTAssertNotNil(self.databaseManager.subscribedFeedsViewName);
        XCTAssertNotNil(self.databaseManager.unsubscribedFeedsViewName);
        XCTAssertNotNil(self.databaseManager.allFeedsSearchViewName);
        [expcetation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error");
        }
    }];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSURLSessionConfiguration *)setupURLMock
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
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

- (void)testStorage {
    
    YapDatabaseConnection *connection = [self.databaseManager.database newConnection];
    NSURLSessionConfiguration *configuration = [self setupURLMock];
    SCRFeedFetcher *feedFetcher = [[SCRFeedFetcher alloc] initWithReadWriteYapConnection:connection sessionConfiguration:configuration];
    
    NSURL *url = [NSURL URLWithString:kSecureReaderYapTestsRSSURL];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"testFetching"];
    [feedFetcher fetchFeedDataFromURL:url completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSError *error) {
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
                
                XCTAssertNotNil(item.feedYapKey,@"could not find yap feed key");
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

@end
