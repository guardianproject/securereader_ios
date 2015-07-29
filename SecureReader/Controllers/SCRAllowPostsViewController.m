//
//  SCRAllowPostsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-07-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRAllowPostsViewController.h"
#import "SCRSettings.h"
#import "SCRTheme.h"

@interface SCRAllowPostsViewController ()
@property (nonatomic) BOOL permissionGiven;
@end

@implementation SCRAllowPostsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.infoTextView.linkTextAttributes = @{NSForegroundColorAttributeName:[SCRTheme getColorProperty:@"highlightColor" forTheme:@"Colors"]};
    [self.infoTextView setAttributedText:[self autoLinkURLs:self.infoTextView.text]];
    
    self.buttonPermission.userInteractionEnabled = YES;
    self.labelPermission.userInteractionEnabled = YES;
    [self.buttonPermission addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPermissionClicked:)]];
    [self.labelPermission addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPermissionClicked:)]];
    [self updateButtonStates];
}

- (IBAction)continueClicked:(id)sender {
    [self dismissViewControllerAnimated:self completion:^{
        [SCRSettings setHasGivenPostPermission:self.permissionGiven];
        [self.openingSegue perform];
    }];
}

- (void)buttonPermissionClicked:(UIGestureRecognizer *)gestureRecognizer
{
    self.permissionGiven = !self.permissionGiven;
    [self updateButtonStates];
}

- (void) updateButtonStates
{
    if (self.permissionGiven)
    {
        [self.buttonPermission setImage:[UIImage imageNamed:@"ic_toggle_selected"]];
    }
    else
    {
        [self.buttonPermission setImage:[UIImage imageNamed:@"ic_toggle_unselected"]];
    }
    [self.buttonContinue setEnabled:self.permissionGiven];
}

- (NSAttributedString *)autoLinkURLs:(NSString *)string {
    NSDictionary *originalAttributes = @{ NSForegroundColorAttributeName: self.infoTextView.textColor, NSFontAttributeName: self.infoTextView.font };
    NSMutableAttributedString *linkedString = [[NSMutableAttributedString alloc] initWithString:string attributes:originalAttributes];
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<a href=\"([^\"]+)\">([^<]+)</a>" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *results = [regex matchesInString:string options:kNilOptions range:NSMakeRange(0, [string length])];
    for(NSTextCheckingResult *match in [results reverseObjectEnumerator])
    {
        NSString *url = [string substringWithRange:[match rangeAtIndex:1]];
        NSString *replacement = [string substringWithRange:[match rangeAtIndex:2]];
        NSDictionary *attributes = @{ NSLinkAttributeName: url };
        [linkedString addAttributes:attributes range:match.range];
        [linkedString replaceCharactersInRange:match.range withString:replacement];
    }
    return linkedString;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    UIViewController *destination = [self.storyboard instantiateViewControllerWithIdentifier:@"termsAndConditions"];
    destination.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:destination animated:YES completion:nil];
    return NO;
}

@end
