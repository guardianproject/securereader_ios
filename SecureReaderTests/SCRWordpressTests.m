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

@interface SCRWordpressTests : XCTestCase
@property (nonatomic, strong) SCRWordpressClient *wpClient;
@property (nonatomic, strong) XCTestExpectation *expectation;
@end

@implementation SCRWordpressTests

- (void)setUp {
    [super setUp];
    self.wpClient = [[SCRWordpressClient alloc] initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
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
        NSLog(@"%@",error);
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
        NSLog(@"%@",error);
    }];
}

@end
