//
//  SCRPanicController.m
//  SecureReader
//
//  Created by David Chiles on 5/11/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPanicController.h"
#import "SCRPassphraseManager.h"
#import "PSTAlertController.h"
#import "SCRApplication.h"
#import "SCRAppDelegate.h"

@implementation SCRPanicController

/**
 * Shows alert view to confirm panic. If confirmed, this method
 * will call the panic method.
 */
+ (void) showPanicConfirmationDialogInViewController:(UIViewController*)viewController {
    PSTAlertController *alert = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Clear Data", @"Title for panic alert") message:NSLocalizedString(@"This will permanently clear all app data and close the app. This operation is irreversible!", @"Message for panic alert") preferredStyle:PSTAlertControllerStyleAlert];
    PSTAlertAction *deleteAction = [PSTAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"panic delete button") style:PSTAlertActionStyleDestructive handler:^(PSTAlertAction *action) {
        [self panic];
    }];
    PSTAlertAction *cancelAction = [PSTAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:PSTAlertActionStyleCancel handler:nil];
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    [alert showWithSender:self controller:viewController animated:YES completion:nil];
}

/**
 Immediately clears all app data and exits the app.
 @warn You should warn the user with an alert first.
 */
+ (void) panic {
    [[NSNotificationCenter defaultCenter] postNotificationName:kPanicStartNotification object:nil];
    
    // Shut down network requests
    SCRAppDelegate *appDelegate = [SCRAppDelegate sharedAppDelegate];
    [appDelegate.mediaFetcher invalidate];
    // TODO: [appDelegate.feedFetcher invalidate];
    // TODO: [appDelegate.torManager stop];

    NSMutableArray *directoriesArray = [[NSMutableArray alloc] init];
    
    ////// Documents Path //////
    NSString *documentsPath = [self directoryForSearchPath:NSDocumentDirectory];
    if (documentsPath) {
        [directoriesArray addObject:documentsPath];
    }
    
    ////// Application Support //////
    NSString *applicationSupportDirectory = [self directoryForSearchPath:NSApplicationSupportDirectory];
    if (applicationSupportDirectory) {
        [directoriesArray addObject:applicationSupportDirectory];
    }
    
    ////// Caches //////
    NSString *cachesDirectory = [self directoryForSearchPath:NSCachesDirectory];
    if (cachesDirectory) {
        [directoriesArray addObject:cachesDirectory];
    }
    
    ////// Temporary //////
    NSString *tempDirectory = NSTemporaryDirectory();
    if (tempDirectory) {
        [directoriesArray addObject:tempDirectory];
    }
    
    [directoriesArray enumerateObjectsUsingBlock:^(NSString *directory, NSUInteger idx, BOOL *stop) {
        NSError *error = nil;
        [self clearConentsOfDirectory:directory error:&error];
        if (error) {
            NSAssert(error == nil, @"Error deleting item at path %@", directory);
        }
    }];
    
    ////// NSUserDefaults //////
    //http://stackoverflow.com/questions/545091/clearing-nsuserdefaults
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    ////// Keychain //////
    [[SCRPassphraseManager sharedInstance] clearDatabasePassphrase];
    [[SCRPassphraseManager sharedInstance] setPIN:nil];
    
    // force exit
    exit(0);
}

+ (NSString *)directoryForSearchPath:(NSSearchPathDirectory)searchPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(searchPath, NSUserDomainMask, YES);
    return [paths firstObject];
}

+ (void)clearConentsOfDirectory:(NSString *)directory error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directory];
    
    NSString *file = [enumerator nextObject];
    while (file && !*error) {
        [fileManager removeItemAtPath:[directory stringByAppendingPathComponent:file] error:error];
        file = [enumerator nextObject];
    }
}

@end
