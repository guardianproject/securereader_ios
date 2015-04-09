//
//  AppDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRFeedFetcher.h"
#import "SCRFileManager.h"
#import "SCRMediaFetcher.h"
#import "SCRFeed.h"
#import "SCRItem.h"

@interface SCRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) SCRFeedFetcher *feedFetcher;
@property (strong, nonatomic, readonly) SCRFileManager *fileManager;
@property (strong, nonatomic, readonly) SCRMediaFetcher *mediaFetcher;

+ (SCRAppDelegate*) sharedAppDelegate;

/** Set up database. Will return NO if db passphrase is incorrect */
- (BOOL) setupDatabase;

//-(void) addFeed:(SCRFeed *)feed;
-(void) removeFeed:(SCRFeed *)feed;
-(void) setFeed:(SCRFeed *)feed subscribed:(BOOL)subscribed;
-(void) markItem:(SCRItem *)item asFavorite:(BOOL)favorite;

@end

