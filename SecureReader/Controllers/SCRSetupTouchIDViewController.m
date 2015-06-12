//
//  SCRSetupTouchIDViewController.m
//  SecureReader
//
//  Created by Christopher Ballinger on 6/3/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRSetupTouchIDViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "SCRPassphraseManager.h"
#import "SCRAppDelegate.h"
#import "SCRTouchLock.h"

@interface SCRSetupTouchIDViewController ()

@end

@implementation SCRSetupTouchIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (![SCRTouchLock canUseTouchID]) {
        self.subtitleLabel.text = NSLocalizedString(@"Protect your data with a PIN.", @"label for PIN setup");
        [self.touchIDButton setImage:nil forState:UIControlStateNormal];
        [self.touchIDButton setTitle:NSLocalizedString(@"Setup PIN", @"Button for setting up PIN") forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) attemptAppSetup {
    BOOL success = [[SCRAppDelegate sharedAppDelegate] setupDatabase];
    if (!success) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CreatePassphrase.DBError.Title", @"Title for create passphrase, db failure") message:NSLocalizedString(@"CreatePassphrase.DBError.Message", @"Message for create passphrase, db failure") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return NO;
    } else {
        return YES;
    }
}

- (IBAction)touchIDButtonPressed:(id)sender {
    // show PIN setup
    VENTouchLockCreatePasscodeViewController *createPasscodeVC = [[VENTouchLockCreatePasscodeViewController alloc] init];
    [self presentViewController:[createPasscodeVC embeddedInNavigationController] animated:YES completion:nil];
}
@end
