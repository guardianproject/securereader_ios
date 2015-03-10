//
//  SecureReaderDownloadTests.m
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IOCipher.h"
#import "SCRMediaItem.h"
#import "SCRMediaFetcher.h"
#import "SCRFileManager.h"

@interface SecureReaderDownloadTests : XCTestCase

@property (nonatomic, strong) SCRFileManager *fileManager;

@end

@implementation SecureReaderDownloadTests

- (void)setUp {
    [super setUp];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    
    NSString *path = [documentsPath stringByAppendingPathComponent:@"test.sqlite"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    self.fileManager = [[SCRFileManager alloc] init];
    [self.fileManager setupWithPath:path password:@"password"];
    
    XCTAssertNotNil(self.fileManager);
    XCTAssertNotNil(self.fileManager.ioCipher);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMediaDownlaod {
    XCTestExpectation *expectation = [self expectationWithDescription:@"testMediaDownlaod"];
    SCRMediaFetcher *mediaFetcher = [[SCRMediaFetcher alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] storage:self.fileManager.ioCipher];
    mediaFetcher.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block SCRMediaItem *mediaItem = [[SCRMediaItem alloc] init];
    mediaItem.itemYapKey = @"itemKey";
    
    //Easiest way to test, fetch the octocat from github.
    mediaItem.remoteURL = [NSURL URLWithString:@"https://assets-cdn.github.com/images/modules/logos_page/Octocat.png"];
    [mediaFetcher downloadMediaItem:mediaItem completionBlock:^(NSError *error) {
        XCTAssertNil(error);
        
        NSDictionary *attributes = [self.fileManager.ioCipher fileAttributesAtPath:[mediaItem localPath] error:&error];
        XCTAssertNotNil(attributes);
        XCTAssertNil(error);
        
        [self.fileManager dataForPath:[mediaItem localPath] completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSData *data, NSError *error) {
            XCTAssertNil(error);
            XCTAssertNotNil(data);
            [expectation fulfill];
        }];
        
        
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        NSLog(@"Timeout Error");
    }];
}

@end
