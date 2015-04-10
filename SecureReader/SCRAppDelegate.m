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
#import "NSUserDefaults+SecureReader.h"

@interface SCRAppDelegate() <BITHockeyManagerDelegate>
@end

@implementation SCRAppDelegate
{
    BOOL mLoggedIn;
}

+ (SCRAppDelegate*) sharedAppDelegate
{
    return (SCRAppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"075cafe8595cb96f0c502f380e104a54"
                                                           delegate:self];
    [[BITHockeyManager sharedHockeyManager].authenticator setIdentificationType:BITAuthenticatorIdentificationTypeDevice];
    [[BITHockeyManager sharedHockeyManager] startManager];
#ifndef DEBUG
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
#endif
    
    _torManager = [[SCRTorManager alloc] init];
    [self loginWithPassphrase:@"password"];
    
    [NSBundle setLanguage:[SCRSettings getUiLanguage]];
    [SCRTheme initialize];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:kApplicationDidTimeoutNotification object:nil];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    UIViewController *mainViewController = nil;
    if (![self hasCreatedPassphrase])
    {
        mainViewController = [storyboard instantiateViewControllerWithIdentifier:@"welcome"];
        self.window.rootViewController = mainViewController;
    }
    return YES;
}

-(void)applicationDidTimeout:(NSNotification *) notif
{
    NSLog (@"time exceeded!!");
    SCRNavigationController *navController = (SCRNavigationController *)self.window.rootViewController;
    UIViewController *vcCurrent = [navController visibleViewController];
    if ([vcCurrent class] != [SCRSelectLanguageViewController class] &&
        [vcCurrent class] != [SCRCreatePassphraseViewController class] &&
        [vcCurrent class] != [SCRLoginViewController class])
    {
        SCRLoginViewController *vcLogin = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"login"];
        vcLogin.modalPresentationStyle = UIModalPresentationFullScreen;
        dispatch_async(dispatch_get_main_queue(), ^{
            [(SCRNavigationController *)self.window.rootViewController presentViewController:vcLogin animated:YES completion:nil];
        });
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[SCRApplication sharedApplication] lockApplicationDelayed];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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

- (BOOL)hasCreatedPassphrase
{
    //return NO;
    return [SCRSettings getPassphrase] != nil && [SCRSettings getPassphrase].length > 0;
}

- (BOOL)isLoggedIn
{
    return mLoggedIn;
}

- (BOOL)loginWithPassphrase:(NSString *)passphrase
{
    if ([passphrase isEqualToString:[SCRSettings getPassphrase]])
    {
        mLoggedIn = YES;
        
        ////// Setup File Storage //////
        
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"media.sqlite"];
        _fileManager = [[SCRFileManager alloc] init];
        [self.fileManager setupWithPath:path password:@"password"]; //TODO real password here!
        
        ////// Setup Media Fetcher //////
        
        _mediaFetcher = [[SCRMediaFetcher alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                                      storage:self.fileManager.ioCipher];
        self.mediaFetcher.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        ////// Setup Feed Fetcher //////
        
        YapDatabaseConnection *databaseConnection = [SCRDatabaseManager sharedInstance].readWriteConnection;
        _feedFetcher = [[SCRFeedFetcher alloc] initWithReadWriteYapConnection:databaseConnection sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        if ([[NSUserDefaults standardUserDefaults] scr_useTor] && self.torManager.proxyManager.status != CPAStatusOpen) {
            self.feedFetcher.networkOperationQueue.suspended = YES;
            self.mediaFetcher.networkOperationQueue.suspended = YES;
        }
        
        ////// Download Some Feeds //////
        NSArray *feedURLs = @[@"http://www.voanews.com/api/epiqq",
                              @"http://www.theguardian.com/world/rss",
                              @"http://feeds.washingtonpost.com/rss/world",
                              @"http://www.nytimes.com/services/xml/rss/nyt/InternationalHome.xml",
                              @"http://rss.cnn.com/rss/cnn_topstories.rss",
                              @"http://rss.cnn.com/rss/cnn_world.rss"];
        [feedURLs enumerateObjectsUsingBlock:^(NSString *feedURLString, NSUInteger idx, BOOL *stop) {
            [self.feedFetcher fetchFeedDataFromURL:[NSURL URLWithString:feedURLString] completionQueue:nil completion:nil];
        }];
        
    }
    return mLoggedIn;
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
