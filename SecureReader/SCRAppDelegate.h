//
//  AppDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRFileManager.h"
#import "SCRMediaFetcher.h"

@interface SCRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SCRFileManager *fileManager;
@property (strong, nonatomic) SCRMediaFetcher *mediaFetcher;

+ (SCRAppDelegate*) sharedAppDelegate;

- (BOOL)hasCreatedPassphrase;
- (BOOL)isLoggedIn;
- (BOOL)loginWithPassphrase:(NSString *)passphrase;

@end

