//
//  SCRPanicController.m
//  SecureReader
//
//  Created by David Chiles on 5/11/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPanicController.h"
#import "SCRPassphraseManager.h"

@implementation SCRPanicController

+ (void)clearAllDataCompletionQueue:(dispatch_queue_t)completionQueue completion:(void (^)(NSError *))completionBlock
{
    if (!completionQueue) {
        completionQueue = dispatch_get_main_queue();
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __block NSError *error = nil;
        
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
            [self clearConentsOfDirectory:directory error:&error];
            if (error) {
                *stop = YES;
            }
        }];
        
        ////// NSUserDefaults //////
        //http://stackoverflow.com/questions/545091/clearing-nsuserdefaults
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        
        ////// Keychain //////
        [[SCRPassphraseManager sharedInstance] clearDatabasePassphrase];
        
        dispatch_async(completionQueue, ^{
            if (completionBlock) {
                completionBlock(error);
            }
        });
    });
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
