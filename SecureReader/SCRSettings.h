//
//  Settings.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCRSettings : NSObject

+ (NSString *)getUiLanguage;
+ (void) setUiLanguage:(NSString *)languageCode;

// TEMP implement passwords!
+ (NSString *)getPassphrase;
+ (void) setPassphrase:(NSString *)passphrase;

+ (NSInteger) lockTimeout;

@end
