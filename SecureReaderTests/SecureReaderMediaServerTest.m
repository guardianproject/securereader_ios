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
#import "SCRMediaServer+Video.h"

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
    //We don't have a callback or delegate to check if the server is actually running
    //So to hack around this we just wait for 5 seconds until it's probably running :)
    //Normally we start the server when the app starts so this isn't an issue
    [NSThread sleepForTimeInterval:5];
    XCTAssertNil(error,@"Error starting media server");
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [self.mediaServer stop];
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

- (void)testVideoThumbnail
{
    NSData *testData = [[NSFileManager defaultManager] contentsAtPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"short" ofType:@"mp4"]];
    SCRMediaItem *videoItem = [[SCRMediaItem alloc] initWithURL:[NSURL URLWithString:@"http://fake.com/short.mp4"]];
    
    [self.fileManager.ioCipher createFileAtPath:[videoItem localPath] error:nil];
    [self.fileManager.ioCipher writeDataToFileAtPath:[videoItem localPath] data:testData offset:0 error:nil];
    
    UIImage *image = [self.mediaServer videoThumbnail:videoItem];
    
    XCTAssertNotNil(image,@"Unable to create thumbnail");
}

@end
