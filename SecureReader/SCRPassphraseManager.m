//
//  SCRPassphraseManager.m
//  SecureReader
//
//  Created by Christopher Ballinger on 4/9/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPassphraseManager.h"
#import "SSKeychain.h"

static NSString * const SCRDatabasePassphraseKey    = @"SCRDatabasePassphraseKey";
static NSString * const SCRPINKey    = @"SCRPINKey";
static NSString * const SCRPassphraseService    = @"info.guardianproject.SecureReader";

@interface SCRPassphraseManager()
@property (nonatomic, strong) NSString *inMemoryPassphrase;
@end

@implementation SCRPassphraseManager

+ (instancetype) sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init {
    if (self = [super init]) {
        [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly];
    }
    return self;
}

/** May return nil if password is only stored in memory */
- (NSString*) databasePassphrase {
    NSString *passphrase = nil;
    if (self.inMemoryPassphrase) {
        passphrase = self.inMemoryPassphrase;
    } else {
        passphrase = [SSKeychain passwordForService:SCRPassphraseService account:SCRDatabasePassphraseKey];
    }
    return passphrase;
}

/** if storeInKeychain is NO, the passphrase will only persist in memory */
- (void) setDatabasePassphrase:(NSString*)databasePassphrase
               storeInKeychain:(BOOL)storeInKeychain {
    NSAssert(databasePassphrase.length > 0, @"Passphrase must have non-zero length!");
    if (storeInKeychain) {
        [SSKeychain setPassword:databasePassphrase forService:SCRPassphraseService account:SCRDatabasePassphraseKey];
    } else {
        self.inMemoryPassphrase = databasePassphrase;
    }
}


- (void) clearDatabasePassphraseFromMemory {
    if (self.inMemoryPassphrase) {
        self.inMemoryPassphrase = nil;
    }
}
- (void) clearDatabasePassphraseFromKeychain {
    [SSKeychain deletePasswordForService:SCRPassphraseService account:SCRDatabasePassphraseKey];
}

/** Removes passphrase from memory and/or keychain */
- (void) clearDatabasePassphrase {
    
    //This is just around for finding when the passphrase is cleared unintentionaly
    @throw [NSException exceptionWithName:@"SCRPassPhraseCleared" reason:@"The passphrase was attempted to be cleared from memory and keychainn" userInfo:nil];
    [self clearDatabasePassphraseFromMemory];
    [self clearDatabasePassphraseFromKeychain];
}

/** Returns a new complex passphrase (to be stored in the keychain) */
- (NSString*) generateNewPassphrase {
    int passphraseBytes = 30;
    NSMutableData* passphraseData = [NSMutableData dataWithLength:passphraseBytes];
    SecRandomCopyBytes(kSecRandomDefault, passphraseBytes, [passphraseData mutableBytes]);
    NSString *passphrase = [passphraseData base64EncodedStringWithOptions:0];
    return passphrase;
}

@end
