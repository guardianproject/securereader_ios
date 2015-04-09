//
//  SCRPassphraseManager.h
//  SecureReader
//
//  Created by Christopher Ballinger on 4/9/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCRPassphraseManager : NSObject

/** May return nil if password is only stored in memory */
- (NSString*) databasePassphrase;

/** if storeInKeychain is NO, the passphrase will only persist in memory */
- (void) setDatabasePassphrase:(NSString*)databasePassphrase
               storeInKeychain:(BOOL)storeInKeychain;

/** Removes passphrase from memory and/or keychain */
- (void) clearDatabasePassphrase;

/** Returns a new complex passphrase (to be stored in the keychain) */
- (NSString*) generateNewPassphrase;

/** Short PIN for restricting app UI to be stored in keychain (can be used when passphrase is stored in keychain) */
- (void) setPIN:(NSString*)PIN;
/** Short PIN for restricting app UI stored in keychain */
- (NSString*) PIN;

+ (instancetype) sharedInstance;

@end
