//
//  Settings.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRSettings.h"
#import "SCRApplication.h"
#import "SSKeychain.h"

@implementation SCRSettings

NSString * const kDownloadMediaSettingsKey = @"downloadMedia";
NSString * const kFontSizeAdjustmentSettingsKey = @"fontSizeAdjustment";
NSString * const kSCRSyncFrequencyKey = @"syncFrequency";
NSString * const kSCRSyncDataOverCellularKey = @"syncNetwork";
NSString * const kSCRUseTorKey = @"useTor";
NSString * const kSCRArticleExpirationKey = @"articleExpiration";
NSString * const kSCRHasShownInitialSettingsHelpKey = @"hasShownInitialSettingsHelp";
NSString * const kSCRUserNicknameKey = @"userNickname";
NSString * const kSCRHasGivenPostPermissionKey = @"hasGivenPostPermission";
NSString * const kSCRWordpressUsernameKey = @"kSCRWordpressUsernameKey";
NSString * const kSCRWordpressPasswordKey = @"kSCRWordpressPasswordKey";
static NSString * const kSCRWordpressKeychainService = @"info.gp.secure_reader";
NSString * const kSCRPasscodeEnabledKey = @"passcodeEnabled";
NSString * const kSCRUseTouchIDKey = @"useTouchID";
NSString * const kSCRUseComplexPassphraseKey = @"useComplexPassphrase";

+ (NSString *)getUiLanguage
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *ret = [userDefaults stringForKey:@"uiLanguage"];
    if (ret == nil)
        ret = @"Base";
    return ret;
}

+ (void)setUiLanguage:(NSString *)languageCode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:languageCode forKey:@"uiLanguage"];
    [userDefaults synchronize];
}

+ (BOOL)downloadMedia
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:kDownloadMediaSettingsKey] != nil)
        return [userDefaults boolForKey:kDownloadMediaSettingsKey];
    return NO;
}

+ (void)setDownloadMedia:(BOOL)downloadMedia
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:downloadMedia forKey:kDownloadMediaSettingsKey];
    [self onChange:kDownloadMediaSettingsKey];
}

+ (NSInteger) lockTimeout
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"lockTimeout"] == nil)
        return 60 * 60 * 24;
    return [userDefaults integerForKey:@"lockTimeout"];
}

+ (NSTimeInterval) articleExpiration
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:kSCRArticleExpirationKey] == nil)
        return 60 * 60 * 24 * 30;
    return [userDefaults doubleForKey:kSCRArticleExpirationKey];
}

+ (float)fontSizeAdjustment
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    float ret = [userDefaults floatForKey:kFontSizeAdjustmentSettingsKey];
    return ret;
}

+ (void)setFontSizeAdjustment:(float)fontSizeAdjustment
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:fontSizeAdjustment forKey:kFontSizeAdjustmentSettingsKey];
    [userDefaults synchronize];
    [self onChange:kFontSizeAdjustmentSettingsKey];
}

+ (void)onChange:(NSString*)key
{
    NSDictionary *dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:key, @"key", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSettingChangedNotification object:self userInfo:dict];
}

+ (BOOL) backgroundSyncEnabled {
    NSString *backgroundSyncValue = [[NSUserDefaults standardUserDefaults] objectForKey:kSCRSyncFrequencyKey];
    if ([backgroundSyncValue isEqualToString:@"InBackground"]) {
        return YES;
    }
    return NO;
}

+ (BOOL) syncDataOverCellular {
    NSString *syncDataOverCellularValue = [[NSUserDefaults standardUserDefaults] objectForKey:kSCRSyncDataOverCellularKey];
    if ([syncDataOverCellularValue isEqualToString:@"WifiAndMobile"]) {
        return YES;
    }
    return NO;
}

+ (BOOL) useTor {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSCRUseTorKey];
}

+ (BOOL)hasShownInitialSettingsHelp
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:kSCRHasShownInitialSettingsHelpKey] != nil)
        return [userDefaults boolForKey:kSCRHasShownInitialSettingsHelpKey];
    return NO;
}

+ (void)setHasShownInitialSettingsHelp:(BOOL)hasShownInitialSettingsHelp
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:hasShownInitialSettingsHelp forKey:kSCRHasShownInitialSettingsHelpKey];
    [self onChange:kSCRHasShownInitialSettingsHelpKey];
}

+ (NSString *)userNickname
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kSCRUserNicknameKey];
}

+ (void)setUserNickname:(NSString *)userNickname
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (userNickname.length > 0) {
        [userDefaults setValue:userNickname forKey:kSCRUserNicknameKey];
    } else {
        [userDefaults removeObjectForKey:kSCRUserNicknameKey];
    }
    [userDefaults synchronize];
}

+ (NSString*)wordpressUsername {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSCRWordpressUsernameKey];
}
+ (void) setWordpressUsername:(NSString*)wordpressUsername {
    if (wordpressUsername.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:wordpressUsername forKey:kSCRWordpressUsernameKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSCRWordpressUsernameKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)wordpressPassword {
    NSError *error = nil;
    NSString *password = [SSKeychain passwordForService:kSCRWordpressKeychainService account:kSCRWordpressPasswordKey error:&error];
    if (error) {
        NSLog(@"Error fetching wordpress password: %@", error);
    }
    return password;
}

+ (void) setWordpressPassword:(NSString*)wordpressPassword {
    NSError *error = nil;
    if (wordpressPassword.length > 0) {
        [SSKeychain setPassword:wordpressPassword forService:kSCRWordpressKeychainService account:kSCRWordpressPasswordKey error:&error];
    } else {
        [SSKeychain deletePasswordForService:kSCRWordpressKeychainService account:kSCRWordpressPasswordKey error:&error];
    }
    if (error) {
        NSLog(@"Error setting wordpress password: %@", error);
    }
}

+ (BOOL) hasGivenPostPermission
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:kSCRHasGivenPostPermissionKey] != nil)
        return [userDefaults boolForKey:kSCRHasGivenPostPermissionKey];
    return NO;
}

+ (void) setHasGivenPostPermission:(BOOL)hasGivenPostPermission
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:hasGivenPostPermission forKey:kSCRHasGivenPostPermissionKey];
    [self onChange:kSCRHasGivenPostPermissionKey];
}

+ (void) loadDefaultsFromSettingsDictionary:(NSDictionary*)settingsDictionary {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    NSArray *preferenceSpecifiers = [settingsDictionary objectForKey:@"PreferenceSpecifiers"];
    [preferenceSpecifiers enumerateObjectsUsingBlock:^(NSDictionary *preference, NSUInteger idx, BOOL *stop) {
        id defaultValue = [preference objectForKey:@"DefaultValue"];
        NSString *key = [preference objectForKey:@"Key"];
        if (defaultValue && key) {
            [defaults setObject:defaultValue forKey:key];
        }
    }];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

@end
