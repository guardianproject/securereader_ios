//
//  SCRTouchLock.m
//  SecureReader
//
//  Created by Christopher Ballinger on 6/3/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRTouchLock.h"
#import "IASKSettingsReader.h"
#import "SCRSettings.h"
#import "SCRAppDelegate.h"

@implementation SCRTouchLock

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// We handle this logic elsewhere in SCRAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
}
- (void)applicationDidEnterBackground:(NSNotification *)notification
{
}
- (void)applicationWillEnterForeground:(NSNotification *)notification
{
}

- (instancetype) init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appSettingChanged:) name:kIASKAppSettingChanged object:nil];
    }
    return self;
}

- (void) appSettingChanged:(NSNotification*)notif {
    NSNumber *passcodeSetting = notif.userInfo[kSCRPasscodeEnabledKey];
    if (passcodeSetting) {
        if (passcodeSetting.boolValue) {
            VENTouchLockCreatePasscodeViewController *createPasscodeVC = [[VENTouchLockCreatePasscodeViewController alloc] init];
            [[SCRAppDelegate sharedAppDelegate].window.rootViewController presentViewController:[createPasscodeVC embeddedInNavigationController] animated:YES completion:nil];
        } else {
            [[SCRTouchLock sharedInstance] deletePasscode];
        }
    }
    NSNumber *touchIDSetting = notif.userInfo[kSCRUseTouchIDKey];
    if (touchIDSetting) {
        [SCRTouchLock setShouldUseTouchID:touchIDSetting.boolValue];
    }
}

@end
