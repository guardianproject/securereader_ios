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
#import "SCRTheme.h"
#import "CPAProxyResponseParser.h"

NSString *const kSCRTorManagerNetworkStatusNotification = @"kSCRTorManagerNetworkStatusNotification";
NSString *const kSCRTorManagerBootstrapProgressNotification = @"kSCRTorManagerBootstrapProgressNotification";

NSString *const kSCRTorManagerBootstrapProgressKey = @"kSCRTorManagerBootstrapProgressKey";
NSString *const kSCRTorManagerBootstrapProgressSummaryKey = @"kSCRTorManagerBootstrapProgresSummaryKey";
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
                [self setupTor];
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

- (void)setupTor {
    [self sendBootstrapProgress:0 summary:NSLocalizedString(@"Tor starting", @"Label for alert for when tor is starting")];
    __weak typeof(self)weakSelf = self;
    [self.proxyManager setupWithCompletion:NULL progress:^(NSInteger progress, NSString *summaryString) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        [strongSelf sendBootstrapProgress:progress summary:summaryString];
        
    } callbackQueue:dispatch_get_main_queue()];
}

- (void)sendBootstrapProgress:(NSInteger)progress summary:(NSString *)summary
{
    NSMutableDictionary *userInfo = [@{kSCRTorManagerBootstrapProgressKey:@(progress)} mutableCopy];
    if ([summary length]) {
        userInfo[kSCRTorManagerBootstrapProgressSummaryKey] = summary;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSCRTorManagerBootstrapProgressNotification
                                                            object:self
                                                          userInfo:userInfo];
    });
}

- (void)currentBootstrapProgress:(void (^)(NSInteger progress, NSString *summary))resultblock queue:(dispatch_queue_t)queue
{
    if (!resultblock) {
        return;
    }
    
    if (!queue) {
        queue = dispatch_get_main_queue();
    }
    
    [self.proxyManager cpa_sendGetBootstrapInfoWithCompletion:^(NSString *responseString, NSError *error) {
        NSInteger progress = [CPAProxyResponseParser bootstrapProgressForResponse:responseString];
        NSString *summary = [CPAProxyResponseParser bootstrapSummaryForResponse:responseString];
        
        dispatch_async(queue, ^{
            resultblock(progress,summary);
        });
        
        
    } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
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
    
    // clear wordpress account when changing Tor settings
    [SCRSettings setWordpressPassword:nil];
    [SCRSettings setWordpressUsername:nil];
    [SCRSettings setUserNickname:nil];
    
    if (useTor && self.proxyManager.status == CPAStatusClosed) {
        [self setupTor];
    } else {
        [self sendConfigurationChangedNotification];
    }
    [self updateTorIndicator];
}

- (void)torStarted:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSCRTorManagerNetworkStatusNotification
                                                            object:self
                                                          userInfo:@{kSCRTorManagerNetworkPauseKey:@(YES)}];
    });
}

- (void) updateTorIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL usingTor = [SCRSettings useTor] && self.proxyManager.status == CPAStatusOpen;
        UIColor *color = nil;
        if (usingTor) {
            color = [SCRTheme torColor];
        } else {
            color = [SCRTheme defaultNavbarColor];
        }
        if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
            [[UINavigationBar appearance] setBarTintColor:color];
        }
        // janky hack to force UIAppearance update
        NSArray *windows = [UIApplication sharedApplication].windows;
        for (UIWindow *window in windows) {
            for (UIView *view in window.subviews) {
                [view removeFromSuperview];
                [window addSubview:view];
            }
        }
    });
}

- (void)torReady:(NSNotification *)notification
{
    [self updateTorIndicator];
    [self sendConfigurationChangedNotification];
}

@end
