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

@end
