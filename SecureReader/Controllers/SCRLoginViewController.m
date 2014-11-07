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

@interface SCRLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *editPassphrase;
@end

@implementation SCRLoginViewController
{
    UIViewController *destinationViewController;
    BOOL animateDestination;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setDestinationViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    destinationViewController = viewController;
    animateDestination = animated;
}

- (IBAction)loginButtonClicked:(id)sender
{
    //TEMP
    if ([[SCRAppDelegate sharedAppDelegate] loginWithPassphrase:_editPassphrase.text])
    {
        if (destinationViewController != nil)
        {
            SCRNavigationController *vcNav = (SCRNavigationController *)[self presentingViewController];
            [vcNav pushViewController:destinationViewController animated:NO];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
