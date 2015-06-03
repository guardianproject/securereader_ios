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

@interface SCRSetupTouchIDViewController ()

@end

@implementation SCRSetupTouchIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (![self supportsTouchID]) {
        self.subtitleLabel.text = NSLocalizedString(@"Protect your data with a PIN.", @"label for PIN setup");
        [self.touchIDButton setImage:nil forState:UIControlStateNormal];
        [self.touchIDButton setTitle:NSLocalizedString(@"Setup PIN", @"Button for setting up PIN") forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) supportsTouchID {
    if ([LAContext class]) {
        return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                                                     error:nil];
    }
    return NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"segueToMain"]) {
        // skip PIN setup
        NSString *passphrase = [[SCRPassphraseManager sharedInstance] generateNewPassphrase];
        [[SCRPassphraseManager sharedInstance] setDatabasePassphrase:passphrase storeInKeychain:YES];
        BOOL success = [[SCRAppDelegate sharedAppDelegate] setupDatabase];
        if (!success) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CreatePassphrase.DBError.Title", @"Title for create passphrase, db failure") message:NSLocalizedString(@"CreatePassphrase.DBError.Message", @"Message for create passphrase, db failure") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
            return NO;
        } else {
            return YES;
        }
    } else if ([identifier isEqualToString:@"createPassphraseSegue"]) {
        [[SCRPassphraseManager sharedInstance] setPIN:nil];
        return YES;
    }
    return YES;
}

- (IBAction)touchIDButtonPressed:(id)sender {
    // show PIN setup
}
@end
