//
//  SCRWordpressClient.m
//  SecureReader
//
//  Created by Christopher Ballinger on 6/24/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRWordpressClient.h"
#import "WPXMLRPC.h"

static NSString * const kWordpressEndpoint = @"https://securereader.guardianproject.info/wordpress/xmlrpc.php";
static NSString * const kWordpressKeychainService = @"wpkeychain";


@interface SCRWordpressClient() <NSURLSessionDelegate>
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSOperationQueue *delegateQueue;
@property (nonatomic, strong) NSURL *rpcURL;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@end

@implementation SCRWordpressClient

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration {
    if (self = [super initWithSessionConfiguration:sessionConfiguration]) {
        self.rpcURL = [NSURL URLWithString:kWordpressEndpoint];
        self.networkOperationQueue.maxConcurrentOperationCount = 1;
        self.delegateQueue = [[NSOperationQueue alloc] init];
        self.urlSession = [NSURLSession sessionWithConfiguration:self.urlSessionConfiguration delegate:self delegateQueue:self.delegateQueue];
        
    }
    return self;
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
            NSLog(@"error creating xmlrpc: %@", error);
            return;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.rpcURL];
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
        NSDictionary *postParameters = @{@"post_title": title,
                                         @"post_content": content,
                                         @"post_status": @"publish"};
        NSArray *parameters = [self buildParametersWithExtra:postParameters];
        WPXMLRPCEncoder *encoder = [[WPXMLRPCEncoder alloc] initWithMethod:@"wp.newPost" andParameters:parameters];
        NSError *error = nil;
        NSData *data = [encoder dataEncodedWithError:&error];
        if (error) {
            NSLog(@"error creating xmlrpc: %@", error);
            return;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.rpcURL];
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

@end
