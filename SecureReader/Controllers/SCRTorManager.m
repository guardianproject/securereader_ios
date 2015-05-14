//
//  SCRTorManager.m
//  SecureReader
//
//  Created by David Chiles on 4/2/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRTorManager.h"

#import "IASKSettingsReader.h"
#import "SCRSettings.h"

NSString *const kSCRTorManagerNetworkStatusNotification = @"kSCRTorManagerNetworkStatusNotification";

NSString *const kSCRTorManagerNetworkPauseKey = @"kSCRTorManagerNetworkPauseKey";
NSString *const KSCRTorManagerURLSessionConfigurationKey = @"KSCRTorManagerURLSessionConfigurationKey";

@interface SCRTorManager ()

@property (nonatomic, strong) id settingsNotificationToken;
@property (nonatomic, strong) id torDidFinishNotificationToken;
@property (nonatomic, strong) id torDidStartNotificationToken;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation SCRTorManager

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_settingsNotificationToken];
    [[NSNotificationCenter defaultCenter] removeObserver:_torDidFinishNotificationToken];
    [[NSNotificationCenter defaultCenter] removeObserver:_torDidStartNotificationToken];
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
        
        if ([SCRSettings useTor]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.proxyManager setupWithCompletion:NULL progress:NULL];
            });
            
        }
        
        
        ////// Subscribe to notifications //////
        self.settingsNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:kIASKAppSettingChanged object:nil queue:self.operationQueue usingBlock:^(NSNotification *note) {
            if ([note.object isKindOfClass:[NSString class]]) {
                if ([((NSString *)note.object) isEqualToString:kSCRUseTorKey]) {
                    [self updatedTorSettings:note];
                }
            }
        }];
        
        self.torDidStartNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:CPAProxyDidStartSetupNotification object:nil queue:self.operationQueue usingBlock:^(NSNotification *note) {
            [self torStarted:note];
        }];
        
        self.torDidFinishNotificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:CPAProxyDidFinishSetupNotification object:nil queue:self.operationQueue usingBlock:^(NSNotification *note) {
            [self torReady:note];
        }];
    }
    return self;
}

- (NSURLSessionConfiguration *)currentConfiguration
{
    BOOL useTor = [SCRSettings useTor];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    if ([SCRSettings syncDataOverCellular]) {
        configuration.allowsCellularAccess = YES;
    } else {
        configuration.allowsCellularAccess = NO;
    }
    if (useTor) {
        NSString *host = self.proxyManager.SOCKSHost;
        NSNumber *port = @(self.proxyManager.SOCKSPort);
        if ([host length]) {
            configuration.connectionProxyDictionary = @{(__bridge NSString *)kCFStreamPropertySOCKSProxyHost:host,
                                                        (__bridge NSString *)kCFStreamPropertySOCKSProxyPort:port};
        }
    }
    return configuration;
}

- (void)sendConfigurationChangedNotification
{
    NSURLSessionConfiguration *configuration = [self currentConfiguration];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSCRTorManagerNetworkStatusNotification
                                                            object:self
                                                          userInfo:@{kSCRTorManagerNetworkPauseKey:@(NO),
                                                                     KSCRTorManagerURLSessionConfigurationKey:configuration}];
    });
}

 #pragma - mark Notifications

- (void)updatedTorSettings:(NSNotification *)notification
{
    BOOL useTor = [notification.userInfo[kSCRUseTorKey] boolValue];
    
    if (useTor && self.proxyManager.status == CPAStatusClosed) {
        [self.proxyManager setupWithCompletion:NULL progress:NULL];
    } else {
        [self sendConfigurationChangedNotification];
    }
}

- (void)torStarted:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSCRTorManagerNetworkStatusNotification
                                                            object:self
                                                          userInfo:@{kSCRTorManagerNetworkPauseKey:@(YES)}];
    });
}

- (void)torReady:(NSNotification *)notification
{
    [self sendConfigurationChangedNotification];
}

@end
