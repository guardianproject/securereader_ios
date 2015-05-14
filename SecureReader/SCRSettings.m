//
//  Settings.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRSettings.h"
#import "SCRApplication.h"

@implementation SCRSettings

NSString * const kDownloadMediaSettingsKey = @"downloadMedia";
NSString * const kFontSizeAdjustmentSettingsKey = @"fontSizeAdjustment";
NSString * const kSCRSyncFrequencyKey = @"syncFrequency";
NSString * const kSCRSyncDataOverCellularKey = @"syncNetwork";
NSString * const kSCRUseTorKey = @"useTor";


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
