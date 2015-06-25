//
//  SCRWordpressClient.h
//  SecureReader
//
//  Created by Christopher Ballinger on 6/24/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCRNetworkFetcher.h"

@interface SCRWordpressClient : SCRNetworkFetcher

/**
 @param sessionConfiguration The configuration to be used for all subsequent downloads. Make sure to use a configuration policy that includes NSURLCacheStorageAllowedInMemoryOnly or NSURLCacheStorageNotAllowed.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration;

/** Set username and password for authenticated requests */
- (void) setUsername:(NSString*)username
            password:(NSString*)password;

/** Requests new account account credentials with given nickname */
- (void) requestNewAccountWithNickname:(NSString*)nickname
                       completionBlock:(void (^)(NSString *username, NSString *password, NSError *error))completionBlock;

/** Creates new post with title and content. You must call setUsername:password: first! */
- (void) createPostWithTitle:(NSString*)title
                     content:(NSString*)content
             completionBlock:(void (^)(NSString *postId, NSError *error))completionBlock;
@end
