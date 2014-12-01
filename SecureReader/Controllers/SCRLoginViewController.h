//
//  SRLoginViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRLoginViewController : UIViewController

- (IBAction)loginButtonClicked:(id)sender;

- (void) setDestinationViewController:(UIViewController *)viewController navigationController:(UINavigationController *)navigationController animated:(BOOL)animated;

@end
