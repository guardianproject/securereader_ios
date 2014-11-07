//
//  Settings.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRSettings.h"

@implementation SCRSettings

+ (NSString *)getUiLanguage
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *ret = [userDefaults stringForKey:@"uiLanguage"];
    if (ret == nil)
        ret = @"en";
    return ret;
}

+ (void)setUiLanguage:(NSString *)languageCode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:languageCode forKey:@"uiLanguage"];
    [userDefaults synchronize];
}

+ (NSString *)getPassphrase
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *ret = [userDefaults stringForKey:@"passphrase"];
    return ret;
}

+ (void) setPassphrase:(NSString *)passphrase
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:passphrase forKey:@"passphrase"];
    [userDefaults synchronize];
}

+ (NSInteger) lockTimeout
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"lockTimeout"] == nil)
        return 60 * 60 * 24;
    return [userDefaults integerForKey:@"lockTimeout"];
}

@end
