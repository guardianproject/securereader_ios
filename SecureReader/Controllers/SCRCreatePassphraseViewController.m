//
//  SRCreatePassphraseViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRCreatePassphraseViewController.h"
#import "SCRSettings.h"
#import "SCRAppDelegate.h"
#import "SCRPassphraseManager.h"

@interface SCRCreatePassphraseViewController ()
@property (weak, nonatomic) IBOutlet UITextField *editPassphrase;
@property (weak, nonatomic) IBOutlet UITextField *editPassphraseVerify;
@end

@implementation SCRCreatePassphraseViewController

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES];
}

- (IBAction)openAppButtonClicked:(id)sender
{
    if ([_editPassphrase.text length] == 0 && [_editPassphraseVerify.text length] == 0)
        return;

    if (![_editPassphrase.text isEqualToString:_editPassphraseVerify.text])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CreatePassphrase.Mismatched.Title", @"Title for create passphrase, mismatched passwords") message:NSLocalizedString(@"CreatePassphrase.Mismatched.Message", @"Message for create passphrase, mismatched passwords") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    NSString *passphrase = _editPassphrase.text;
    [[SCRPassphraseManager sharedInstance] setDatabasePassphrase:passphrase storeInKeychain:NO];
    
    [self attemptAppSetup];
}

- (void) attemptAppSetup {
    BOOL success = [[SCRAppDelegate sharedAppDelegate] setupDatabase];
    if (!success) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CreatePassphrase.DBError.Title", @"Title for create passphrase, db failure") message:NSLocalizedString(@"CreatePassphrase.DBError.Message", @"Message for create passphrase, db failure") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
    } else {
        [self performSegueWithIdentifier:@"segueToMain" sender:self];
        [self removeFromParentViewController];
    }
}

- (IBAction)skipButtonPressed:(id)sender {
    NSString *passphrase = [[SCRPassphraseManager sharedInstance] generateNewPassphrase];
    [[SCRPassphraseManager sharedInstance] setDatabasePassphrase:passphrase storeInKeychain:YES];
    [self attemptAppSetup];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _editPassphrase) {
        [_editPassphraseVerify becomeFirstResponder];
    }
    else if (textField == _editPassphraseVerify)
    {
        //[self openAppButtonClicked:nil];
    }
    [textField resignFirstResponder];
    return YES;
}

// Hide keyboard when tapping outside edit fields
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([_editPassphrase isFirstResponder] && [touch view] != _editPassphrase) {
        [_editPassphrase resignFirstResponder];
    }
    else if ([_editPassphraseVerify isFirstResponder] && [touch view] != _editPassphraseVerify) {
        [_editPassphraseVerify resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
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
