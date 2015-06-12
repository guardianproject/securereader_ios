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
#import "SCRConstants.h"

@interface SCRCreatePassphraseViewController ()
@property (weak, nonatomic) IBOutlet UITextField *editPassphrase;
@property (weak, nonatomic) IBOutlet UITextField *editPassphraseVerify;
@end

@implementation SCRCreatePassphraseViewController

- (IBAction)setPassphrasePressed:(id)sender
{
    if ([_editPassphrase.text length] == 0 && [_editPassphraseVerify.text length] == 0)
        return;

    if (![_editPassphrase.text isEqualToString:_editPassphraseVerify.text])
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CreatePassphrase.Mismatched.Title", @"Title for create passphrase, mismatched passwords") message:NSLocalizedString(@"CreatePassphrase.Mismatched.Message", @"Message for create passphrase, mismatched passwords") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        return;
    }
    NSString *passphrase = _editPassphrase.text;
    if (passphrase.length == 0) {
        return;
    }
    
    // Remove PIN because it's not really needed w/ complex passcode
    [[SCRTouchLock sharedInstance] deletePasscode];
    
    [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"You will now need to enter your password every time you launch the app.", @"dialog for complex passphrase creation") delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
    
    /** Time out the app, do sqlite3_rekey with new key */
    [[NSNotificationCenter defaultCenter] postNotificationName:kApplicationDidTimeoutNotification object:nil userInfo:@{kNewPasswordUserInfoKey: passphrase}];
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

@end
