//
//  SCRTorManager.m
//  SecureReader
//
//  Created by David Chiles on 4/2/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRTorManager.h"

#import "IASKSettingsReader.h"
#import "NSUserDefaults+SecureReader.h"

NSString *const kSCRUseTorKey = @"useTor";
NSString *const kSCRTorManagerTorStatusNotification = @"kSCRTorManagerTorStatusNotification";

@interface SCRTorManager ()

@property (nonatomic, strong) id settingsNotificationToken;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation SCRTorManager

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_settingsNotificationToken];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        
        NSURL *cpaProxyBundleURL = [[NSBundle mainBundle] URLForResource:@"CPAProxy" withExtension:@"bundle"];
        NSBundle *cpaProxyBundle = [NSBundle bundleWithURL:cpaProxyBundleURL];
        NSString *torrcPath = [cpaProxyBundle pathForResource:@"torrc" ofType:nil];
        NSString *geoipPath = [cpaProxyBundle pathForResource:@"geoip" ofType:nil];
        NSString *dataDirectory = [[[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"com.SecureReader.Tor"] path];
        
        
        CPAConfiguration *configuration = [[CPAConfiguration alloc] initWithTorrcPath:torrcPath
                                                                            geoipPath:geoipPath
                                                                 torDataDirectoryPath:dataDirectory];
        
        _proxyManager = [[CPAProxyManager alloc] initWithConfiguration:configuration];
        
        if ([[NSUserDefaults standardUserDefaults] scr_useTor]) {
            [self.proxyManager setupWithCompletion:NULL progress:NULL];
        }
        
        self.settingsNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:kIASKAppSettingChanged object:nil queue:self.operationQueue usingBlock:^(NSNotification *note) {
            if ([note.object isKindOfClass:[NSString class]]) {
                if ([((NSString *)note.object) isEqualToString:kSCRUseTorKey]) {
                    [self updatedTorSettings:note];
                }
            }
        }];
    }
    return self;
}

- (void)updatedTorSettings:(NSNotification *)notification
{
    BOOL useTor = [notification.userInfo[kSCRUseTorKey] boolValue];
    
    if (useTor && self.proxyManager.status == CPAStatusClosed) {
        [self.proxyManager setupWithCompletion:NULL progress:NULL];
    }
}

- (NSURLSessionConfiguration *)currentConfiguration
{
    BOOL useTor = [[NSUserDefaults standardUserDefaults] scr_useTor];
    if (useTor) {
        
        NSString *host = self.proxyManager.SOCKSHost;
        NSNumber *port = @(self.proxyManager.SOCKSPort);
        
        NSURLSessionConfiguration *configuration = nil;
        if ([host length]) {
            configuration = [[NSURLSessionConfiguration alloc] init];
            configuration.connectionProxyDictionary = @{(__bridge NSString *)kCFProxyHostNameKey:host,
                                                        (__bridge NSString *)kCFProxyPortNumberKey:port}
            ;
        }
        return configuration;
    }
    
    return [NSURLSessionConfiguration defaultSessionConfiguration];
}

@end
