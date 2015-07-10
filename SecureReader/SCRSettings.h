//
//  Settings.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCRSettings : NSObject

extern NSString * const kFontSizeAdjustmentSettingsKey;
extern NSString * const kSCRSyncFrequencyKey;
extern NSString * const kSCRSyncDataOverCellularKey;
extern NSString * const kSCRUseTorKey;
extern NSString * const kSCRUserNicknameKey;
extern NSString * const kSCRHasGivenPostPermissionKey;
extern NSString * const kSCRWordpressUsernameKey;
extern NSString * const kSCRWordpressPasswordKey;

+ (NSString *)getUiLanguage;
+ (void) setUiLanguage:(NSString *)languageCode;

+ (BOOL)downloadMedia;
+ (void)setDownloadMedia:(BOOL)downloadMedia;

+ (NSInteger) lockTimeout;

/**
 @return a timeInterval in seconds after an article should expire
 */
+ (NSTimeInterval) articleExpiration;

+ (float)fontSizeAdjustment;
+ (void)setFontSizeAdjustment:(float)fontSizeAdjustment;

+ (BOOL) backgroundSyncEnabled;
+ (BOOL) syncDataOverCellular;
+ (BOOL) useTor;

+ (BOOL) hasShownInitialSettingsHelp;
+ (void) setHasShownInitialSettingsHelp:(BOOL)hasShownInitialSettingsHelp;

// wordpress
+ (NSString *)userNickname;
+ (void) setUserNickname:(NSString *)userNickname;
+ (NSString*)wordpressUsername;
+ (void) setWordpressUsername:(NSString*)wordpressUsername;
+ (NSString*)wordpressPassword;
+ (void) setWordpressPassword:(NSString*)wordpressPassword;

+ (BOOL) hasGivenPostPermission;
+ (void) setHasGivenPostPermission:(BOOL)hasGivenPostPermission;

+ (void) loadDefaultsFromSettingsDictionary:(NSDictionary*)settingsDictionary;

@end
