//
//  SCRWordpressClient.m
//  SecureReader
//
//  Created by Christopher Ballinger on 6/24/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRWordpressClient.h"
#import "WPXMLRPC.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SCRAppDelegate.h"
#import "SCRConstants.h"

static NSString* SCRGetMimeTypeForExtension(NSString* extension) {
    NSCParameterAssert(extension.length > 0);
    NSString* mimeType = nil;
    extension = [extension lowercaseString];
    if (extension.length) {
        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
        if (uti) {
            mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType));
            CFRelease(uti);
        }
    }
    return mimeType ? mimeType : @"application/octet-stream";
}

@interface SCRWordpressClient() <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@end

@implementation SCRWordpressClient

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
                                 rpcEndpoint:(NSURL*)rpcEndpoint
 {
    if (self = [super initWithSessionConfiguration:sessionConfiguration]) {
        _rpcEndpoint = [rpcEndpoint copy];
        self.networkOperationQueue.maxConcurrentOperationCount = 1;
        self.delegateQueue = [[NSOperationQueue alloc] init];
        self.urlSession = [NSURLSession sessionWithConfiguration:self.urlSessionConfiguration delegate:self delegateQueue:self.delegateQueue];
        
    }
    return self;
}

+ (instancetype) defaultClient {
    NSURL *url = [NSURL URLWithString:kSCRWordpressEndpoint];
    SCRWordpressClient *wpClient = [[SCRWordpressClient alloc] initWithSessionConfiguration:[SCRAppDelegate sharedAppDelegate].torManager.currentConfiguration rpcEndpoint:url];
    return wpClient;
}

- (void)setUrlSessionConfiguration:(NSURLSessionConfiguration *)urlSessionConfiguration
{
    if (![self.urlSession.configuration isEqual:urlSessionConfiguration]) {
        [self invalidate];
        self.urlSession = [NSURLSession sessionWithConfiguration:urlSessionConfiguration delegate:self delegateQueue:self.delegateQueue];
    }
}

- (void) invalidate {
    [self.urlSession invalidateAndCancel];
    _urlSession = nil;
}

- (void) setUsername:(NSString *)username password:(NSString *)password {
    self.username = username;
    self.password = password;
}

/** Taken from WordpressApi
 https://github.com/wordpress-mobile/WordPress-API-iOS/blob/master/WordPressApi/WordPressXMLRPCApi.m#L392
 */
- (NSArray *)buildParametersWithExtra:(id)extra {
    NSParameterAssert(self.username);
    NSParameterAssert(self.password);
    NSMutableArray *result = [NSMutableArray array];
    [result addObject:@"1"];
    [result addObject:self.username];
    [result addObject:self.password];
    if ([extra isKindOfClass:[NSArray class]]) {
        [result addObjectsFromArray:extra];
    } else if ([extra isKindOfClass:[NSDictionary class]]) {
        [result addObject:extra];
    }
    
    return [NSArray arrayWithArray:result];
}

/** Requests new account and stores it in the keychain */
- (void) requestNewAccountWithNickname:(NSString*)nickname
                       completionBlock:(void (^)(NSString *username, NSString *password, NSError *error))completionBlock {
    NSParameterAssert(nickname != nil);
    NSParameterAssert(completionBlock != nil);
    if (!completionBlock || !nickname) {
        return;
    }
    [self.networkOperationQueue addOperationWithBlock:^{
        WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"acxu.createUser" andParameters:@[nickname]];
        NSError *error = nil;
        NSData *data = [encoder dataEncodedWithError:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, nil, error);
            });
            return;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.rpcEndpoint];
        [request setHTTPMethod:@"POST"];
        [request setAllHTTPHeaderFields:@{@"Content-Type": @"text/xml"}];
        NSURLSessionUploadTask *uploadTask = [self.urlSession uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, nil, error);
                });
                return;
            }
            WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:data];
            if ([decoder isFault] || [decoder object] == nil) {
                error = [decoder error];
            }
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, nil, error);
                });
                return;
            }
            NSString *username = nil;
            NSString *password = nil;
            id object = decoder.object;
            if ([object isKindOfClass:[NSString class]]) {
                NSString *responseString = object;
                NSArray *components = [responseString componentsSeparatedByString:@" "];
                username = [components firstObject];
                password = [components lastObject];
            }
            
            if (username && password) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(username, password, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, nil, [NSError errorWithDomain:@"info.gp" code:1234 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't parse username/password"}]);
                });
            }
            
        }];
        [uploadTask resume];
    }];
}



- (void) createPostWithTitle:(NSString*)title
                     content:(NSString*)content
             completionBlock:(void (^)(NSString *postId, NSError *error))completionBlock {
    [self createPostWithTitle:title content:content enclosureURL:nil enclosureLength:0 completionBlock:completionBlock];
}

/** Creates new post with title, content and optional image. You must call setUsername:password: first! */
- (void) createPostWithTitle:(NSString*)title
                     content:(NSString*)content
                enclosureURL:(NSURL*)enclosureURL
             enclosureLength:(NSUInteger)enclosureLength
             completionBlock:(void (^)(NSString *postId, NSError *error))completionBlock {
    NSParameterAssert(title);
    NSParameterAssert(content);
    NSParameterAssert(completionBlock);
    if (!title || !content || !completionBlock) {
        return;
    }
    NSParameterAssert(self.username);
    NSParameterAssert(self.password);
    if (!self.username || !self.password) {
        return;
    }
    [self.networkOperationQueue addOperationWithBlock:^{
        NSMutableDictionary *postParameters = [NSMutableDictionary dictionaryWithDictionary:@{@"post_title": title,
                                         @"post_content": content,
                                         @"post_status": @"publish"}];
        NSMutableArray *parameters = [NSMutableArray arrayWithArray:[self buildParametersWithExtra:postParameters]];

        if (enclosureURL) {
            NSString *mimeType = SCRGetMimeTypeForExtension(enclosureURL.absoluteString.pathExtension);
            NSDictionary *enclosure = @{@"url": enclosureURL.absoluteString,
                                        @"length": @(enclosureLength),
                                        @"type": mimeType};
            [parameters addObject:enclosure];
        }
        WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"wp.newPost" andParameters:parameters];
        NSError *error = nil;
        NSData *data = [encoder dataEncodedWithError:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, error);
            });
            return;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.rpcEndpoint];
        [request setHTTPMethod:@"POST"];
        [request setAllHTTPHeaderFields:@{@"Content-Type": @"text/xml"}];
        NSURLSessionUploadTask *uploadTask = [self.urlSession uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
                return;
            }
            WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:data];
            if ([decoder isFault] || [decoder object] == nil) {
                error = [decoder error];
            }
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
                return;
            }
            id object = decoder.object;
            NSString *postId = nil;
            if ([object isKindOfClass:[NSString class]]) {
                postId = object;
            }
            if (postId) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(postId, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, [NSError errorWithDomain:@"info.gp" code:1235 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't parse response"}]);
                });
            }
        }];
        [uploadTask resume];
    }];
}

/*
 int blog_id
 string username
 string password
 int post_id
 struct comment
 int comment_parent
 string content
 string author
 string author_url
 string author_email
 */
- (void) postNewCommentForPostId:(NSString*)postId
                 parentCommentId:(NSString*)parentCommentId
                            body:(NSString*)body
                          author:(NSString*)author
                       authorURL:(NSURL*)authorURL
                     authorEmail:(NSString*)authorEmail
                 completionBlock:(void (^)(NSString *commentId, NSError *error))completionBlock {
    NSParameterAssert(postId);
    NSParameterAssert(body);
    NSParameterAssert(completionBlock);
    if (!postId || !body || !completionBlock) {
        return;
    }
    NSParameterAssert(self.username);
    NSParameterAssert(self.password);
    if (!self.username || !self.password) {
        return;
    }
    [self.networkOperationQueue addOperationWithBlock:^{
        NSMutableDictionary *commentParams = [NSMutableDictionary dictionary];
        if (parentCommentId) {
            [commentParams setObject:parentCommentId forKey:@"comment_parent"];
        }
        [commentParams setObject:body forKey:@"content"];
        if (author) {
            [commentParams setObject:author forKey:@"author"];
        }
        if (authorURL) {
            [commentParams setObject:authorURL.absoluteString forKey:@"author_url"];
        }
        if (authorEmail) {
            [commentParams setObject:authorEmail forKey:@"author_email"];
        }
        NSMutableArray *parameters = [NSMutableArray arrayWithArray:[self buildParametersWithExtra:@[postId]]];
        [parameters addObject:commentParams];
        WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"wp.newComment" andParameters:parameters];
        NSError *error = nil;
        NSData *data = [encoder dataEncodedWithError:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, error);
            });
            return;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.rpcEndpoint];
        [request setHTTPMethod:@"POST"];
        [request setAllHTTPHeaderFields:@{@"Content-Type": @"text/xml"}];
        NSURLSessionUploadTask *uploadTask = [self.urlSession uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
                return;
            }
            WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:data];
            if ([decoder isFault] || [decoder object] == nil) {
                error = [decoder error];
            }
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, error);
                });
                return;
            }
            id object = decoder.object;
            NSString *commentId = nil;
            if ([object isKindOfClass:[NSString class]]) {
                commentId = object;
            } else if ([object isKindOfClass:[NSNumber class]]) {
                NSNumber *commentNumber = object;
                commentId = commentNumber.stringValue;
            }
            if (commentId) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(commentId, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, [NSError errorWithDomain:@"info.gp" code:1235 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't parse response"}]);
                });
            }
        }];
        [uploadTask resume];
    }];
}


// https://codex.wordpress.org/XML-RPC_WordPress_API/Media#wp.uploadFile
/*
 wp.uploadFile
 Upload a media file.
 
 Parameters
 int blogid
 string username
 string password
 struct data
 string name: Filename.
 string type: File MIME type.
 string bits: binary data. Shouldn't be base64-encoded.
 bool overwrite: Optional. Overwrite an existing attachment of the same name. (Added in WordPress 2.2)
 int post_id: Optional. Allows an attachment to be assigned to a post. (User must have permission to edit the assigned post)
 
 Return Values
 struct
 string id (Added in WordPress 3.4)
 string file: Filename.
 string url
 string type
 
 Errors
 401
 If the user does not have the upload_files cap.
 500
 File upload failure.
 */
- (void) uploadFileWithData:(NSData*)fileData
                   fileName:(NSString*)fileName
                     postId:(NSString*)postId
            completionBlock:(void (^)(NSURL *url, NSString *fileId, NSError *error))completionBlock {
    NSParameterAssert(self.username);
    NSParameterAssert(self.password);
    NSParameterAssert(fileData.length > 0);
    NSParameterAssert(fileName.length > 0);
    NSString *extension = [fileName pathExtension];
    NSString *tmpFilePath = [[self tmpFilePathForCache] stringByAppendingPathExtension:extension];
    NSError *error = nil;
    BOOL success = [fileData writeToFile:tmpFilePath options:0 error:&error];
    if (!success) {
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, nil, error);
            });
        }
        return;
    }
    NSURL *fileURL = [NSURL fileURLWithPath:tmpFilePath];
    [self uploadFileAtURL:fileURL postId:postId completionBlock:^(NSURL *url, NSString *fileId, NSError *error) {
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        completionBlock(url, fileId, error);
    }];
}

/** Get comment stats for a specific post */
- (void) getCommentCountsForPostId:(NSString*)postId
                   completionBlock:(void (^)(NSUInteger approvedCount,
                                             NSUInteger awaitingModerationCount,
                                             NSUInteger spamCount,
                                             NSUInteger totalCommentCount,
                                             NSError *error))completionBlock {
    NSParameterAssert(self.username);
    NSParameterAssert(self.password);
    NSParameterAssert(postId);
    NSParameterAssert(completionBlock);
    if (!completionBlock || !postId) {
        return;
    }
    [self.networkOperationQueue addOperationWithBlock:^{
        NSArray *parameters = [self buildParametersWithExtra:@[postId]];
        WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"wp.getCommentCount" andParameters:parameters];
        NSError *error = nil;
        NSData *data = [encoder dataEncodedWithError:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(0, 0, 0, 0, error);
            });
            return;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.rpcEndpoint];
        [request setHTTPMethod:@"POST"];
        [request setAllHTTPHeaderFields:@{@"Content-Type": @"text/xml"}];
        NSURLSessionUploadTask *uploadTask = [self.urlSession uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(0, 0, 0, 0, error);
                });
                return;
            }
            WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:data];
            if ([decoder isFault] || [decoder object] == nil) {
                error = [decoder error];
            }
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(0, 0, 0, 0, error);
                });
                return;
            }
            if ([decoder.object isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = decoder.object;
                NSString *approved = dict[@"approved"]; // why is this a string?
                NSNumber *awaiting = dict[@"awaiting_moderation"];
                NSNumber *total = dict[@"total_comments"];
                NSNumber *spam = dict[@"spam"];
                NSParameterAssert(approved);
                NSParameterAssert(awaiting);
                NSParameterAssert(total);
                NSParameterAssert(spam);
                if (approved && awaiting && total && spam) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(approved.integerValue,
                                        awaiting.integerValue,
                                        spam.integerValue,
                                        total.integerValue,
                                        nil);
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(0, 0, 0, 0, [NSError errorWithDomain:@"info.gp" code:1235 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't parse response"}]);
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(0, 0, 0, 0, [NSError errorWithDomain:@"info.gp" code:1235 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't parse response"}]);
                });
            }
        }];
        [uploadTask resume];
    }];
    
}

- (void) uploadFileAtURL:(NSURL *)fileURL
                  postId:(NSString*)postId
         completionBlock:(void (^)(NSURL *, NSString *, NSError *))completionBlock {
    NSParameterAssert(self.username);
    NSParameterAssert(self.password);
    NSParameterAssert(fileURL != nil);
    NSParameterAssert(completionBlock);
    if (!completionBlock) {
        return;
    }
    NSString *fileName = [fileURL lastPathComponent];
    NSString *extension = [fileName pathExtension];
    NSParameterAssert(extension.length > 0);
    // not local file, must download first
    if (![fileURL isFileURL]) {
        [self.networkOperationQueue addOperationWithBlock:^{
            NSURLSessionDownloadTask *downloadTask = [self.urlSession downloadTaskWithURL:fileURL completionHandler:^(NSURL * __nullable location, NSURLResponse * __nullable response, NSError * __nullable error) {
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(nil, nil, error);
                    });
                    return;
                }
                NSString *tmpFilePath = [[self tmpFilePathForCache] stringByAppendingPathExtension:extension];
                NSURL *destionationFileURL = [NSURL fileURLWithPath:tmpFilePath];
                [[NSFileManager defaultManager] copyItemAtURL:location toURL:destionationFileURL error:&error];
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionBlock(nil, nil, error);
                    });
                    return;
                }
                [self uploadFileAtURL:destionationFileURL postId:postId completionBlock:^(NSURL *url, NSString *fileId, NSError *error) {
                    [[NSFileManager defaultManager] removeItemAtURL:destionationFileURL error:nil];
                    completionBlock(url, fileId, error);
                }];
            }];
            [downloadTask resume];
        }];
        return;
    }
    
    NSString *mimeType = SCRGetMimeTypeForExtension(extension);
    NSError *error = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:fileURL error:&error];
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(nil, nil, error);
        });
        return;
    }
    [self.networkOperationQueue addOperationWithBlock:^{
        NSMutableDictionary *dataStruct = @{@"name": fileName,
                                     @"type": mimeType,
                                     @"bits": fileHandle}.mutableCopy;
        if (postId) {
            [dataStruct setObject:postId forKey:@"post_id"];
        }
        NSArray *parameters = [self buildParametersWithExtra:dataStruct];
        WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"wp.uploadFile" andParameters:parameters];
        
        NSError *error = nil;
        NSString *tmpFilePath = [self tmpFilePathForCache];
        BOOL success = [encoder encodeToFile:tmpFilePath error:&error];
        [fileHandle closeFile];
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(nil, nil, error);
            });
            return;
        }
        
        NSURL *tmpFileURL = [NSURL fileURLWithPath:tmpFilePath];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.rpcEndpoint];
        [request setHTTPMethod:@"POST"];
        [request setAllHTTPHeaderFields:@{@"Content-Type": @"text/xml"}];
        NSURLSessionUploadTask *uploadTask = [self.urlSession uploadTaskWithRequest:request fromFile:tmpFileURL completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error) {
            [[NSFileManager defaultManager] removeItemAtURL:tmpFileURL error:nil];
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, nil, error);
                });
                return;
            }
            WPXMLRPCDecoder *decoder = [[WPXMLRPCDecoder alloc] initWithData:data];
            if ([decoder isFault] || [decoder object] == nil) {
                error = [decoder error];
            }
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, nil, error);
                });
                return;
            }
            id object = decoder.object;
            NSString *fileId = nil;
            NSURL *url = nil;
            if ([object isKindOfClass:[NSDictionary class]]) {
                NSDictionary *responseDict = object;
                NSString *urlString = responseDict[@"url"];
                if (urlString) {
                    url = [NSURL URLWithString:urlString];
                }
                fileId = responseDict[@"id"];
            }
            if (fileId && url) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(url, fileId, nil);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionBlock(nil, nil, [NSError errorWithDomain:@"info.gp" code:1235 userInfo:@{NSLocalizedDescriptionKey: @"Couldn't parse response"}]);
                });
            }
        }];
        [uploadTask resume];
    }];
}

#pragma mark Utility

- (NSString *)tmpFilePathForCache {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString * tmpPath = [directory stringByAppendingPathComponent:guid];
    return tmpPath;
}

@end
