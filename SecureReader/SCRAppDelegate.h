//
//  AppDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (SCRAppDelegate*) sharedAppDelegate;

- (BOOL)hasCreatedPassphrase;
- (BOOL)isLoggedIn;
- (BOOL)loginWithPassphrase:(NSString *)passphrase;

@end

