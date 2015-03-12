//
//  SecureReaderMediaServerTest.m
//  SecureReader
//
//  Created by David Chiles on 3/10/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SCRFileManager.h"
#import "SCRMediaServer.h"
#import "SCRMediaItem.h"

@interface SecureReaderMediaServerTest : XCTestCase

@property (nonatomic, strong) SCRFileManager *fileManager;
@property (nonatomic, strong) SCRMediaServer *mediaServer;

@end

@implementation SecureReaderMediaServerTest

- (void)setUp {
    [super setUp];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.sqlite"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    self.fileManager = [[SCRFileManager alloc] init];
    [self.fileManager setupWithPath:path password:@"password"];
    
    self.mediaServer = [[SCRMediaServer alloc] initWithIOCipher:self.fileManager.ioCipher];
    NSError *error = nil;
    [self.mediaServer startOnPort:8080 error:&error];
    XCTAssertNil(error,@"Error starting media server");
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFetchingFile
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"testFetchingFile"];
    NSData *testData = [[NSFileManager defaultManager] contentsAtPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"Octocat" ofType:@"png"]];
    SCRMediaItem *mediaItem = [[SCRMediaItem alloc] initWithURL:[NSURL URLWithString:@"http://notreal.com/image.png"]];
    NSError *err = nil;
    XCTAssertTrue([self.fileManager.ioCipher createFileAtPath:[mediaItem localPath] error:&err],@"Unable to create file");
    XCTAssertNil(err,@"Error creating file");
    
    err = nil;
    XCTAssertTrue([self.fileManager.ioCipher writeDataToFileAtPath:[mediaItem localPath] data:testData offset:0 error:&err]);
    XCTAssertNil(err,@"Error writing file");
    
    NSURL *fetchURL = [mediaItem localURLWithPort:self.mediaServer.port];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:fetchURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        XCTAssertNotNil(data,@"No data returned");
        XCTAssertTrue([data isEqualToData:testData],@"Data is not equal");
        XCTAssertNil(error, @"Error retrieving data");
        [expectation fulfill];
    }];
    [dataTask resume];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        NSLog(@"Timeout Error");
    }];
}

@end
