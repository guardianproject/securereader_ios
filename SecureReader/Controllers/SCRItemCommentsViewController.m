//
//  SCRItemCommentsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-06-18.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRItemCommentsViewController.h"

@interface SCRItemCommentsViewController ()

@end

@implementation SCRItemCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.commentsView.layoutManager.allowsNonContiguousLayout = NO;
}

- (BOOL)automaticallyAdjustsScrollViewInsets{
    return NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self unregisterForKeyboardNotifications];
    [super viewDidDisappear:animated];
}

- (void) setItem:(SCRItem *)item
{
    _item = item;
    NSParameterAssert(item != nil);
    if (!self.item) {
        return;
    }
    [self view]; // force view to load if it hasn't already
    
    //self.label.text = self.item.title;
    
    [self.view layoutIfNeeded];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.commentsViewBottomConstraint.constant = kbSize.height;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    self.commentsViewBottomConstraint.constant = 0;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if (![[touch view] isKindOfClass:[UITextView class]]) {
        [self.view endEditing:YES];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.commentsView)
    {
        CGSize constraint = CGSizeMake(self.commentsView.frame.size.width - 2 * self.commentsView.textContainer.lineFragmentPadding, NSUIntegerMax);
        CGSize size = [self.commentsView sizeThatFits:constraint];
        int height = size.height + self.commentsView.textContainerInset.top + self.commentsView.textContainerInset.bottom;
        self.commentsViewHeightConstraint.constant = height;
    }
}

@end
