//
//  SRLoginViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRLoginViewController.h"
#import "SCRNavigationController.h"
#import "SCRAppDelegate.h"
#import "SCRSettings.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "SCRPassphraseManager.h"
#import "SCRTouchLock.h"

@interface SCRLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *editPassphrase;
@property (nonatomic) BOOL passcodeSuccess;
@end

@implementation SCRLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)loginButtonClicked:(id)sender
{
    if ([[SCRTouchLock sharedInstance] isPasscodeSet]) {
        [self showPasscodePrompt];
    } else {
        NSString *passphrase = _editPassphrase.text;
        if (passphrase.length == 0) {
            return;
        }
        [[SCRPassphraseManager sharedInstance] setDatabasePassphrase:passphrase storeInKeychain:NO];
        [self attemptAppSetup];
    }
    
}

- (void) attemptAppSetup {
    BOOL success = [[SCRAppDelegate sharedAppDelegate] setupDatabase];
    if (success) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *rootVC = [storyboard instantiateInitialViewController];
        [UIView transitionFromView:[SCRAppDelegate sharedAppDelegate].window.rootViewController.view
                            toView:rootVC.view
                          duration:0.65f
                           options:UIViewAnimationOptionTransitionFlipFromRight
                        completion:^(BOOL finished){
                            [SCRAppDelegate sharedAppDelegate].window.rootViewController = rootVC;
                        }];
    } else {
        // incorrect passphrase
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login.Incorrect.Title", @"Alert title for incorrect passphrase entered") message:NSLocalizedString(@"Login.Incorrect.Message", @"Alert message for incorrect passphrase entered") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[SCRTouchLock sharedInstance] isPasscodeSet]) {
        self.passphraseLabel.hidden = YES;
        self.editPassphrase.hidden = YES;
    } else {
        self.passphraseLabel.hidden = NO;
        self.editPassphrase.hidden = NO;
    }
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Prevent showing passcode view twice
    if (self.passcodeSuccess) {
        return;
    }
    [self showPasscodePrompt];
}

- (void) showPasscodePrompt {
    if ([[SCRTouchLock sharedInstance] isPasscodeSet]) {
        if ([SCRTouchLock canUseTouchID]) {
            [[SCRTouchLock sharedInstance] requestTouchIDWithCompletion:^(VENTouchLockTouchIDResponse response) {
                if (response == VENTouchLockTouchIDResponseUsePasscode ||
                    response == VENTouchLockTouchIDResponseCanceled) {
                    [self showEnterPasscodeViewController];
                } else if (response == VENTouchLockTouchIDResponseSuccess) {
                    self.passcodeSuccess = YES;
                    [self attemptAppSetup];
                }
            } reason:NSLocalizedString(@"Use TouchID to unlock the app.", @"touchID prompt")];
        } else {
            [self showEnterPasscodeViewController];
        }
    }
}

- (void) showEnterPasscodeViewController {
    VENTouchLockEnterPasscodeViewController *enterPasscodeVC = [[VENTouchLockEnterPasscodeViewController alloc] init];
    __weak VENTouchLockEnterPasscodeViewController *weakVC = enterPasscodeVC;
    enterPasscodeVC.willFinishWithResult = ^(BOOL success) {
        if (success) {
            self.passcodeSuccess = YES;
            [weakVC dismissViewControllerAnimated:YES completion:^{
                [self attemptAppSetup];
            }];
        }
    };
    [self presentViewController:[enterPasscodeVC embeddedInNavigationController] animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

// Hide keyboard when tapping outside edit field
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if ([_editPassphrase isFirstResponder] && [touch view] != _editPassphrase) {
        [_editPassphrase resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}


// Override the actual segue
- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return NO;
}


@end
