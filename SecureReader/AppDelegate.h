//
//  AppDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (AppDelegate*) sharedAppDelegate;

- (BOOL)hasCreatedPassphrase;
- (BOOL)isLoggedIn;
- (BOOL)loginWithPassphrase:(NSString *)passphrase;

@end

