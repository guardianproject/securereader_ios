//
//  SCRMediaServer.m
//  SecureReader
//
//  Created by David Chiles on 2/27/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaServer.h"
#import "GCDWebServer.h"
#import "GCDWebServerRequest.h"
#import "GCDWebServerVirtualFileResponse.h"

@interface SCRMediaServer ()

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, strong) IOCipher *ioCipher;

@end

@implementation SCRMediaServer

- (instancetype)initWithIOCipher:(IOCipher *)cipher
{
    if (self = [super init]) {
        self.ioCipher = cipher;
    }
    return self;
}

- (GCDWebServer *)webServer
{
    if (!_webServer) {
        _webServer = [[GCDWebServer alloc] init];
    }
    return _webServer;
}

- (void)startOnPort:(NSUInteger)port error:(NSError *__autoreleasing *)error
{
    if (port <1) {
        port = 8080;
    }
    
    [self.webServer startWithOptions:@{GCDWebServerOption_Port: @(port),
                                       GCDWebServerOption_BindToLocalhost: @(YES),
                                       GCDWebServerOption_AutomaticallySuspendInBackground: @(NO)}
                               error:error];
    __weak typeof(self)weakSelf = self;
    [self.webServer addHandlerForMethod:@"GET"
                              pathRegex:[NSString stringWithFormat:@"/.*"]
                           requestClass:[GCDWebServerRequest class]
                      asyncProcessBlock:^(GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
                          __strong typeof(weakSelf)strongSelf = weakSelf;
                          [strongSelf handleMediaRequest:request completion:completionBlock];
                      }];
}

- (void)handleMediaRequest:(GCDWebServerRequest *)request completion:(GCDWebServerCompletionBlock)completionBlock
{
    if (completionBlock) {
        GCDWebServerVirtualFileResponse *virtualFileResponse = [GCDWebServerVirtualFileResponse responseWithFile:request.path
                                                                                                       byteRange:request.byteRange
                                                                                                    isAttachment:NO
                                                                                                        ioCipher:self.ioCipher];
        [virtualFileResponse setValue:@"bytes" forAdditionalHeader:@"Accept-Ranges"];
        completionBlock(virtualFileResponse);
    }
}


@end
