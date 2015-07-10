//
//  SCRWordpressTests.m
//  SecureReader
//
//  Created by Christopher Ballinger on 6/24/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SCRWordpressClient.h"
#import "SCRConstants.h"

@interface SCRWordpressTests : XCTestCase
@property (nonatomic, strong) SCRWordpressClient *wpClient;
@property (nonatomic, strong) XCTestExpectation *expectation;
@end

@implementation SCRWordpressTests

- (void)setUp {
    [super setUp];
    self.wpClient = [[SCRWordpressClient alloc] initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] rpcEndpoint:[NSURL URLWithString:kSCRWordpressEndpoint]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.wpClient = nil;
}

- (void)testAccountCreation {
    [self.wpClient requestNewAccountWithNickname:@"test" completionBlock:^(NSString *username, NSString *password, NSError *error) {
        if (error) {
            XCTFail(@"%@", error);
            return;
        }
        [self.expectation fulfill];
    }];
    self.expectation = [self expectationWithDescription:@"account creation"];
    [self waitForExpectationsWithTimeout:20 handler:^(NSError *error) {
        if (error) {
            NSLog(@"%@",error);
        }
    }];
}

- (void) testPost {
    [self.wpClient requestNewAccountWithNickname:@"test" completionBlock:^(NSString *username, NSString *password, NSError *error) {
        if (error) {
            XCTFail(@"%@", error);
            return;
        }
        [self.wpClient setUsername:username password:password];
        [self.wpClient createPostWithTitle:@"test_title" content:@"test_content" completionBlock:^(NSString *postId, NSError *error) {
            if (error) {
                XCTFail(@"%@", error);
                return;
            }
            XCTAssertNotNil(postId);
            NSLog(@"New post with Id: %@", postId);
            [self.expectation fulfill];
        }];
    }];
    self.expectation = [self expectationWithDescription:@"post creation"];
    [self waitForExpectationsWithTimeout:20 handler:^(NSError *error) {
        if (error) {
            NSLog(@"%@",error);
        }
    }];
}

- (void) testUploadImageData {
    [self.wpClient requestNewAccountWithNickname:@"test" completionBlock:^(NSString *username, NSString *password, NSError *error) {
        if (error) {
            XCTFail(@"%@", error);
            return;
        }
        [self.wpClient setUsername:username password:password];
        
        NSData *testJPG = [self generateTestJPEG];
        
        [self.wpClient uploadFileWithData:testJPG fileName:@"test.jpg" completionBlock:^(NSURL *url, NSString *fileId, NSError *error) {
            NSLog(@"Uploaded image at URL: %@", url);
            XCTAssertNotNil(url);
            XCTAssertNotNil(fileId);
            XCTAssertNil(error);
            [self.expectation fulfill];
        }];
    }];
    self.expectation = [self expectationWithDescription:@"post image data"];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * __nullable error) {
        if (error) {
            NSLog(@"%@",error);
        }
    }];
}

- (void) testUploadImageFile {
    [self.wpClient requestNewAccountWithNickname:@"test" completionBlock:^(NSString *username, NSString *password, NSError *error) {
        if (error) {
            XCTFail(@"%@", error);
            return;
        }
        [self.wpClient setUsername:username password:password];
        
        NSData *testJPG = [self generateTestJPEG];
        NSString *tmpFilePath = [[self tmpFilePath] stringByAppendingPathExtension:@"jpg"];
        BOOL success = [testJPG writeToFile:tmpFilePath atomically:YES];
        XCTAssertTrue(success, @"error writing file");
        NSURL *fileURL = [NSURL fileURLWithPath:tmpFilePath];
        [self.wpClient uploadFileAtURL:fileURL completionBlock:^(NSURL *url, NSString *fileId, NSError *error) {
            NSLog(@"Uploaded image at URL: %@", url);
            XCTAssertNotNil(url);
            XCTAssertNotNil(fileId);
            XCTAssertNil(error);
            [self.expectation fulfill];
        }];
    }];
    self.expectation = [self expectationWithDescription:@"post image file"];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * __nullable error) {
        if (error) {
            NSLog(@"%@",error);
        }
    }];
}

- (void) testUploadImageFromRemoteURL {
    [self.wpClient requestNewAccountWithNickname:@"test" completionBlock:^(NSString *username, NSString *password, NSError *error) {
        if (error) {
            XCTFail(@"%@", error);
            return;
        }
        [self.wpClient setUsername:username password:password];
        
        NSURL *fileURL = [NSURL URLWithString:@"https://guardianproject.info/wp-content/uploads/2014/05/feature.jpg"];
        [self.wpClient uploadFileAtURL:fileURL completionBlock:^(NSURL *url, NSString *fileId, NSError *error) {
            NSLog(@"Uploaded image at URL: %@", url);
            XCTAssertNotNil(url);
            XCTAssertNotNil(fileId);
            XCTAssertNil(error);
            [self.expectation fulfill];
        }];
    }];
    self.expectation = [self expectationWithDescription:@"post image file"];
    [self waitForExpectationsWithTimeout:60 handler:^(NSError * __nullable error) {
        if (error) {
            NSLog(@"%@",error);
        }
    }];
}


#pragma mark Utility

- (NSData*) generateTestJPEG {
    CGSize size = CGSizeMake(100, 100);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [[UIColor redColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *jpgData = UIImageJPEGRepresentation(image, 0.5);
    return jpgData;
}

- (NSString *)tmpFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString * tmpPath = [directory stringByAppendingPathComponent:guid];
    return tmpPath;
}

@end
