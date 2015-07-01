//
//  SCRAllowPostsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-07-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRAllowPostsViewController.h"
#import "SCRSettings.h"

@interface SCRAllowPostsViewController ()
@property (nonatomic) BOOL permissionGiven;
@end

@implementation SCRAllowPostsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.buttonPermission.userInteractionEnabled = YES;
    self.labelPermission.userInteractionEnabled = YES;
    [self.buttonPermission addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPermissionClicked:)]];
    [self.labelPermission addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPermissionClicked:)]];
    [self updateButtonStates];
}

- (IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:self completion:nil];
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

@end
