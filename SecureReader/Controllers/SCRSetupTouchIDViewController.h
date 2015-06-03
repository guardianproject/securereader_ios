//
//  SCRSetupTouchIDViewController.h
//  SecureReader
//
//  Created by Christopher Ballinger on 6/3/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRSetupTouchIDViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *topLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *touchIDButton;
- (IBAction)touchIDButtonPressed:(id)sender;

@end
