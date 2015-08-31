//
//  ReadabilityScoreTest.m
//  SecureReader
//
//  Created by David Chiles on 8/31/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SCRReadabilityScoreFetcher.h"

@interface ReadabilityScoreTest : XCTestCase

@end

@implementation ReadabilityScoreTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testScore {
    SCRReadabilityScoreFetcher *scoreFetcher = [[SCRReadabilityScoreFetcher alloc] init];
    NSURL *nyTimesURL = [NSURL URLWithString:@"http://boingboing.net/feed"];
    
    XCTestExpectation *expecation = [self expectationWithDescription:@"readabilityScoreTest"];
    [scoreFetcher fetchScoreForURL:nyTimesURL language:nil completionQueue:nil completionBlock:^(NSNumber *score, NSError *error) {
        XCTAssert([score integerValue] > 0);
        XCTAssertNil(error);
        [expecation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Error %@",error);
        }
    }];
}

@end
