//
//  SCRCreateNicknameViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-06-30.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRCreateNicknameViewController.h"
#import "SCRSettings.h"

@interface SCRCreateNicknameViewController ()

@end

@implementation SCRCreateNicknameViewController

- (IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:self completion:nil];
}

- (IBAction)continueClicked:(id)sender {
    [self dismissViewControllerAnimated:self completion:^{
        [SCRSettings setUserNickname:self.nickname.text];
        [self.openingSegue perform];
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
