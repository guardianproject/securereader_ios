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

/** wordpress xml-rpc endpoint */
@property (nonatomic, strong, readonly) NSURL *rpcEndpoint;

/**
 @param sessionConfiguration The configuration to be used for all subsequent downloads. Make sure to use a configuration policy that includes NSURLCacheStorageAllowedInMemoryOnly or NSURLCacheStorageNotAllowed.
 @param rpcEndpoint wpxmlrpc endpoint
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
                                 rpcEndpoint:(NSURL*)rpcEndpoint
;

/** fully initialized client */
+ (instancetype) defaultClient;

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

/** Creates new post with title, content and enclosure (length in bytes) You must call setUsername:password: first! */
- (void) createPostWithTitle:(NSString*)title
                     content:(NSString*)content
                enclosureURL:(NSURL*)enclosureURL
             enclosureLength:(NSUInteger)enclosureLength
             completionBlock:(void (^)(NSString *postId, NSError *error))completionBlock;

/** Must be local file URL, can be large file, postId optional */
- (void) uploadFileAtURL:(NSURL*)fileURL
                  postId:(NSString*)postId
         completionBlock:(void (^)(NSURL *url, NSString *fileId, NSError *error))completionBlock;

/** fileData must fit in memory, postId optional */
- (void) uploadFileWithData:(NSData*)fileData
                   fileName:(NSString*)fileName
                     postId:(NSString*)postId
            completionBlock:(void (^)(NSURL *url, NSString *fileId, NSError *error))completionBlock;

/** Get comment stats for a specific post */
- (void) getCommentCountsForPostId:(NSString*)postId
                  completionBlock:(void (^)(NSUInteger approvedCount,
                                            NSUInteger awaitingModerationCount,
                                            NSUInteger spamCount,
                                            NSUInteger totalCommentCount,
                                            NSError *error))completionBlock;

/**
 * Post new comment
 * @param postId
 * @param parentCommentId can be nil
 * @param body non-nil
 */
- (void) postNewCommentForPostId:(NSString*)postId
                 parentCommentId:(NSString*)parentCommentId
                            body:(NSString*)body
                          author:(NSString*)author
                       authorURL:(NSURL*)authorURL
                     authorEmail:(NSString*)authorEmail
                 completionBlock:(void (^)(NSString *commentId, NSError *error))completionBlock;

@end
