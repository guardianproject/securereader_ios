//
//  AppDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRAppDelegate.h"
#import "SCRApplication.h"
#import "SCRSettings.h"
#import "NSBundle+Language.h"
#import "SCRApplication.h"
#import "SCRLoginViewController.h"
#import "SCRSelectLanguageViewController.h"
#import "SCRCreatePassphraseViewController.h"
#import "SCRNavigationController.h"
#import "SCRTheme.h"
#import "HockeySDK.h"
#import "SCRDatabaseManager.h"
#import "SCRFeedFetcher.h"
#import "SCRFileManager.h"
#import "SCRPassphraseManager.h"
#import "YapDatabaseViewTransaction.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "IASKSettingsReader.h"
#import <SVGgh/SVGgh.h>
#import "NSString+SecureReader.h"
#import "SCRTouchLock.h"
#import "sqlite3.h"
#import "IOCipher.h"

@interface SCRAppDelegate() <BITHockeyManagerDelegate>
@end

@implementation SCRAppDelegate

+ (SCRAppDelegate*) sharedAppDelegate
{
    return (SCRAppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"075cafe8595cb96f0c502f380e104a54"
                                                           delegate:self];
    [[BITHockeyManager sharedHockeyManager].authenticator setIdentificationType:BITAuthenticatorIdentificationTypeDevice];
    [[BITHockeyManager sharedHockeyManager] startManager];
#ifndef DEBUG
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#endif
    
    _torManager = [[SCRTorManager alloc] init];
    
    [[SCRTouchLock sharedInstance] setKeychainService:@"info.guardianproject.SecureReader" keychainAccount:@"TouchLock" touchIDReason:NSLocalizedString(@"Use TouchID to unlock the app.", @"touchID prompt") passcodeAttemptLimit:5 splashViewControllerClass:nil];
    
    [NSBundle setLanguage:[SCRSettings getUiLanguage]];
    [SCRTheme initialize];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:kApplicationDidTimeoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsUpdated:) name:kIASKAppSettingChanged object:nil];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Load default settings
    IASKSettingsReader *settingsReader = [[IASKSettingsReader alloc] initWithSettingsFileNamed:@"Root" applicationBundle:[NSBundle mainBundle]];
    NSDictionary *settingsDictionary = [settingsReader settingsDictionary];
    [SCRSettings loadDefaultsFromSettingsDictionary:settingsDictionary];

    MakeSureSVGghLinks(); // classes only used in Storyboards might not link otherwise
    [GHControlFactory setDefaultScheme:kColorSchemeEmpty];
    [GHControlFactory setDefaultTextColor:[UIColor greenColor]];
    
    UIViewController *mainViewController = nil;
    if (![SCRDatabaseManager databaseExists])
    {
        // Show welcome screen on first launch
        mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"welcome"];
        self.window.rootViewController = mainViewController;
    } else {
        // Show login view if passphrase is not in keychain or a PIN has been set
        BOOL success = [SCRPassphraseManager sharedInstance].databasePassphrase.length > 0;
        if (success) {
            success = [self setupDatabase];
        }
        BOOL hasPIN = [[SCRTouchLock sharedInstance] isPasscodeSet];
        if (!success || hasPIN) {
            mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"login"];
            self.window.rootViewController = mainViewController;
        }
    }
    
    [self configureBackgroundSync];
    
    return YES;
}

- (void) settingsUpdated:(NSNotification*)notification {
    if ([notification.object isKindOfClass:[NSString class]]) {
        if ([((NSString *)notification.object) isEqualToString:kSCRSyncFrequencyKey]) {
            [self configureBackgroundSync];
        }
    }
}

-(void)applicationDidTimeout:(NSNotification *) notif
{
    NSLog (@"time exceeded!!");
    
    _feedFetcher = nil;
    [self.mediaFetcher invalidate];
    _mediaFetcher = nil;
    
    NSString *databasePath = [SCRDatabaseManager sharedInstance].database.databasePath;

    [[SCRDatabaseManager sharedInstance] teardownDatabase];
    
    // Changing to complex DB passphrase
    NSString *newPassphrase = notif.userInfo[kNewPasswordUserInfoKey];
    if (newPassphrase.length > 0) {
        NSString *oldPassphrase = [SCRPassphraseManager sharedInstance].databasePassphrase;
        [self.fileManager.ioCipher changePassword:newPassphrase oldPassword:oldPassphrase];
        sqlite3 *db = NULL;
        int err = sqlite3_open([databasePath UTF8String], &db);
        if (db && err == SQLITE_OK) {
            err = sqlite3_key(db, [oldPassphrase UTF8String], (int)[oldPassphrase lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
            if (err == SQLITE_OK) {
                err = sqlite3_rekey(db, [newPassphrase UTF8String], (int)[newPassphrase lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
            }
            err = sqlite3_close_v2(db);
        }
        if (err != SQLITE_OK) {
            const char *error_str = sqlite3_errstr(err);
            NSString *errorString = [NSString stringWithUTF8String:error_str];
            NSLog(@"Error changing database key: %@", errorString);
        }
    }
    
    _fileManager = nil;
    [[SCRPassphraseManager sharedInstance] clearDatabasePassphraseFromMemory];
    
    

    UIViewController *rootVC = self.window.rootViewController;
    UIViewController *vcCurrent = rootVC;
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        vcCurrent = ((UINavigationController*)rootVC).visibleViewController;
    }
    
    if ([vcCurrent class] != [SCRLoginViewController class])
    {
        SCRLoginViewController *vcLogin = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"login"];
        self.window.rootViewController = vcLogin;
    }
}

- (void) configureBackgroundSync {
    BOOL backgroundSyncEnabled = [SCRSettings backgroundSyncEnabled];
    if (backgroundSyncEnabled) {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    } else {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
    
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Don't fetch in the background w/ Tor or if user uses complex password
    if (![SCRSettings useTor] &&
        !self.torManager.proxyManager.isConnected &&
        [SCRPassphraseManager sharedInstance].databasePassphrase.length > 0) {
        [self.feedFetcher refreshSubscribedFeedsWithCompletionQueue:dispatch_get_main_queue() completion:^{
            completionHandler(UIBackgroundFetchResultNewData);
        }];
    } else {
        completionHandler(UIBackgroundFetchResultFailed);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[SCRApplication sharedApplication] lockApplicationDelayed];
    self.window.hidden = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    self.window.hidden = NO;
    [(SCRApplication *)[UIApplication sharedApplication] startLockTimer];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)startAsyncFetchingFeedsWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection completionQueue:(dispatch_queue_t)completionQueue completions:(dispatch_block_t)completion
{
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    ////// Setup Feed Fetcher //////
    _feedFetcher = [[SCRFeedFetcher alloc] initWithReadWriteYapConnection:databaseConnection sessionConfiguration:[self.torManager currentConfiguration]];
    if ([SCRSettings useTor] && self.torManager.proxyManager.status != CPAStatusOpen) {
        self.feedFetcher.networkOperationQueue.suspended = YES;
    }
    
    ////// Setup Media Fetcher //////
    _mediaFetcher = [[SCRMediaFetcher alloc] initWithSessionConfiguration:[self.torManager currentConfiguration]
                                                                  storage:self.fileManager.ioCipher];
    self.mediaFetcher.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.mediaFetcher.networkOperationQueue.suspended = self.feedFetcher.networkOperationQueue.suspended;
    _mediaFetcherWatcher = [[SCRMediaFetcherWatcher alloc] initWithMediaFetcher:_mediaFetcher];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    __block BOOL existsFeeds = NO;
    [databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
        existsFeeds = ![[transaction ext:kSCRAllFeedsViewName] isEmpty];
    } completionQueue:queue completionBlock:^{
        if (!existsFeeds) {
            
            // Check if we have a file pre-processed by onboarding
            //
            NSArray *filteredFeeds = nil;
            
            NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
            NSURL *processedFileURL = [[tmpDirURL URLByAppendingPathComponent:@"filtered"] URLByAppendingPathExtension:@"opml"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[processedFileURL path]])
            {
                NSError *err = nil;
                NSData *propertyListData = [NSData dataWithContentsOfURL:processedFileURL];
                if (propertyListData != nil)
                    filteredFeeds = [NSPropertyListSerialization propertyListWithData:propertyListData options:NSPropertyListImmutable format:NULL error:&err];
            }
            
            NSString *defaultOPMLPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"opml"];
            NSURL *fileURL = [NSURL fileURLWithPath:defaultOPMLPath];
            
            [self.feedFetcher fetchFeedsFromOPMLURL:fileURL completionBlock:^(NSArray *feeds, NSError *error) {
                
                dispatch_group_t group = dispatch_group_create();
                for (int i = 0; i < feeds.count; i++)
                {
                    SCRFeed *feed = [feeds objectAtIndex:i];
                    dispatch_group_enter(group);
                    if (filteredFeeds == nil || [filteredFeeds containsObject:[[feed.xmlURL absoluteString] scr_md5]])
                    {
                        [self.feedFetcher fetchFeedDataFromURL:feed.xmlURL completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSError *error) {
                        
                            dispatch_group_leave(group);
                        }];
                    }
                    else
                    {
                        [databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                            // Temporarily set userAdded to YES here. Kind of ugly, but easiest way to tell which should
                            // be subscribed and which should not in the code below.
                            feed.userAdded = YES;
                            feed.subscribed = NO;
                            [feed saveWithTransaction:transaction];
                        } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completionBlock:^{
                            dispatch_group_leave(group);
                        }];
                    }
                }
                
                dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                        NSArray *feedKeys = [transaction allKeysInCollection:[SCRFeed yapCollection]];
                        for (NSString *key in feedKeys) {
                            SCRFeed *feed = [transaction objectForKey:key inCollection:[SCRFeed yapCollection]];
                            if (feed.userAdded != YES)
                                feed.subscribed = YES;
                            feed.userAdded = NO;
                            [feed saveWithTransaction:transaction];
                        }
                    } completionQueue:completionQueue completionBlock:completion];
                });
                
                
                
            } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
            
            
        } else {
            [self.feedFetcher refreshSubscribedFeedsWithCompletionQueue:completionQueue completion:completion];
        }
    }];
    /*
     * Test Feeds
         NSArray *feedURLs = @[@"http://www.voanews.com/api/epiqq",
         @"http://www.theguardian.com/world/rss",
         @"http://feeds.washingtonpost.com/rss/world",
         @"http://www.nytimes.com/services/xml/rss/nyt/InternationalHome.xml",
         @"http://rss.cnn.com/rss/cnn_topstories.rss",
         @"http://rss.cnn.com/rss/cnn_world.rss"];
         //Onion address to check tor settings
         //NSArray *feedURLs = @[@"http://7rmath4ro2of2a42.onion/index.atom"];
     */
}

/** Set up database. Will return NO if db passphrase is incorrect */
- (BOOL)setupDatabase
{
    SCRDatabaseManager *dbManager = [SCRDatabaseManager sharedInstance];
    if (!dbManager.database) {
        // db passphrase is incorrect
        return NO;
    }
    NSString *path = [SCRFileManager defaultDatabasePath];
    NSString *passphrase = [[SCRPassphraseManager sharedInstance] databasePassphrase];
    _fileManager = [[SCRFileManager alloc] init];
    BOOL success = [self.fileManager setupWithPath:path password:passphrase];
    if (!success) {
        return NO;
    }
    
    YapDatabaseConnection *databaseConnection = [SCRDatabaseManager sharedInstance].readWriteConnection;
    
    [self startAsyncFetchingFeedsWithDatabaseConnection:databaseConnection completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completions:^{
        [databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSTimeInterval timeAgo = [SCRSettings articleExpiration];
            NSDate *expiredDate = [NSDate dateWithTimeInterval:-1*timeAgo sinceDate:[NSDate date]];
            [SCRItem removeItemsOlderThan:expiredDate includeFavorites:NO withReadWriteTransaction:transaction storage:self.fileManager.ioCipher];
        }];
    }];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if( [[BITHockeyManager sharedHockeyManager].authenticator handleOpenURL:url
                                                          sourceApplication:sourceApplication
                                                                 annotation:annotation]) {
        return YES;
    }
    return NO;
}

-(void) removeFeed:(SCRFeed *)feed
{
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:feed.yapKey inCollection:[[feed class] yapCollection]];
    }];
}

-(void) setFeed:(SCRFeed *)feed subscribed:(BOOL)subscribed
{
    [feed setSubscribed:subscribed];
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [feed saveWithTransaction:transaction];
        
        // TODO - When subscribing, we need to download the feed!
        if (subscribed)
        {
            if (feed.xmlURL != nil)
                [self.feedFetcher fetchFeedDataFromURL:[feed xmlURL] completionQueue:nil completion:nil];
            else
                [self.feedFetcher fetchFeedDataFromURL:[feed htmlURL] completionQueue:nil completion:nil];
        }
    }];
}

-(void) markItem:(SCRItem *)item asFavorite:(BOOL)favorite
{
    [item setIsFavorite:favorite];
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [item saveWithTransaction:transaction];
    }];
}

@end
