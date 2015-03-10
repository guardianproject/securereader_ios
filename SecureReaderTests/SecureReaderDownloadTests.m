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
#import "URLMock.h"

@interface SecureReaderDownloadTests : XCTestCase

@property (nonatomic, strong) SCRFileManager *fileManager;

@end

@implementation SecureReaderDownloadTests

- (void)setUp {
    [super setUp];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.sqlite"];
    
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
    
    //Enable URLMock
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [UMKMockURLProtocol enable];
    configuration.protocolClasses = @[[UMKMockURLProtocol class]];
    
    //Fake URL to test from
    NSURL *url = [NSURL URLWithString:@"http://test.notreal/image"];
    
    //Get the Octocat from bundle and add URLMock handler
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Octocat" ofType:@"png"];
    __block NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
    UMKMockHTTPResponder *responder = [UMKMockHTTPResponder mockHTTPResponderWithStatusCode:200 body:imageData];
    UMKMockHTTPRequest *request = [UMKMockHTTPRequest mockHTTPGetRequestWithURL:url];
    request.responder = responder;
    
    [UMKMockURLProtocol expectMockRequest:request];
    
    //Setup media fetcher
    SCRMediaFetcher *mediaFetcher = [[SCRMediaFetcher alloc] initWithSessionConfiguration:configuration
                                                                                  storage:self.fileManager.ioCipher];
    mediaFetcher.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //Create media item
    __block SCRMediaItem *mediaItem = [[SCRMediaItem alloc] init];
    mediaItem.itemYapKey = @"itemKey";
    mediaItem.remoteURL = url;
    
    //Download media item
    [mediaFetcher downloadMediaItem:mediaItem completionBlock:^(NSError *error) {
        XCTAssertNil(error, @"Error retrieving file from url");
        
        NSDictionary *attributes = [self.fileManager.ioCipher fileAttributesAtPath:[mediaItem localPath] error:&error];
        XCTAssertNotNil(attributes,@"No attributes found");
        XCTAssertNil(error, @"Error retrieving attributes from IOCipher");
        
        [self.fileManager dataForPath:[mediaItem localPath] completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSData *data, NSError *error) {
            XCTAssertNil(error,@"Error retrieving data from IOCipher");
            XCTAssertNotNil(data, @"No data found in IOCipher");
            XCTAssertTrue([data isEqualToData:imageData],@"Data is not Equal to IOCipher");
            [expectation fulfill];
        }];
        
        
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        NSLog(@"Timeout Error");
    }];
}

@end
