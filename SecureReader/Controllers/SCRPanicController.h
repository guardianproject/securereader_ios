//
//  SCRPanicController.h
//  SecureReader
//
//  Created by David Chiles on 5/11/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Clear iOS keychain (database passphrase, PIN)
 * Remove Library folder (contains Application Support, IOCipher, YapDatabase, caches, preferences)
 * Remove Documents folder
 * Remove tmp folder
 * Stop network activity
 * After complete, force quit the app by calling exit()
 */
@interface SCRPanicController : NSObject

/**
 * Shows alert view to confirm panic. If confirmed, this method
 * will call the panic method.
 */
+ (void) showPanicConfirmationDialogInViewController:(UIViewController*)viewController;

/**
 Immediately clears all app data and exits the app.
 @warn You should warn the user with an alert first.
 @see showPanicConfirmationDialogInViewController:
 */
+ (void) panic;

@end
