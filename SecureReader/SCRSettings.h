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
extern NSString *const kSCRUseTorKey;


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

+ (void) loadDefaultsFromSettingsDictionary:(NSDictionary*)settingsDictionary;

@end
