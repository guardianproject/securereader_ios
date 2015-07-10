//
//  SCRCreateNicknameViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-06-30.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRCreateNicknameViewController.h"
#import "SCRSettings.h"
#import "SCRWordpressClient.h"
#import "SCRConstants.h"
#import "SCRAppDelegate.h"
#import "MRProgress.h"

@implementation SCRCreateNicknameViewController


- (IBAction)continueClicked:(id)sender {
    SCRWordpressClient *wpClient = [SCRWordpressClient defaultClient];
    [MRProgressOverlayView showOverlayAddedTo:self.view animated:YES];
    [wpClient requestNewAccountWithNickname:self.nickname.text completionBlock:^(NSString *username, NSString *password, NSError *error) {
        [MRProgressOverlayView dismissAllOverlaysForView:self.view animated:YES];
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Creating Account", @"Shown when error creating wordpress acct") message:NSLocalizedString(@"Please try again later.", @"wordpress acct error") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
            [alert show];
            return;
        }
        [SCRSettings setUserNickname:self.nickname.text];
        [SCRSettings setWordpressUsername:username];
        [SCRSettings setWordpressPassword:password];
        [self dismissViewControllerAnimated:self completion:^{
            [self.openingSegue perform];
        }];
    }];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(UITextFieldTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:textField];
}

- (void) UITextFieldTextDidChange:(NSNotification*)notification
{
    UITextField * textfield = (UITextField*)notification.object;
    NSString * text = textfield.text;
    
    [self.buttonContinue setEnabled:(text.length > 0)];
}

@end
