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

@interface SCRLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *editPassphrase;
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
    NSString *passphrase = _editPassphrase.text;
    [[SCRPassphraseManager sharedInstance] setDatabasePassphrase:passphrase storeInKeychain:NO];
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
        [[[UIAlertView alloc] initWithTitle:@"Incorrect Passphrase" message:@"Ok." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //[self checkTouchID];
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

- (void) checkTouchID {
    if (![LAContext class]) {
        return;
    }
    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    NSString *myLocalizedReasonString = NSLocalizedString(@"Unlock app with TouchID", @"prompt for TouchID");
    
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:myLocalizedReasonString
                            reply:^(BOOL success, NSError *error) {
                                if (success) {
                                    // User authenticated successfully, take appropriate action
                                } else {
                                    if (error.code == LAErrorUserFallback) {
                                        
                                    }
                                    // User did not authenticate successfully, look at error and take appropriate action
                                }
                            }];
    } else {
        // Could not evaluate policy; look at authError and present an appropriate message to user
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
