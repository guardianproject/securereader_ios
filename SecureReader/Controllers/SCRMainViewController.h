//
//  SCRRootTabViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-01-07.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRHelpHintViewController.h"

@interface SCRMainViewController : UITabBarController<UITabBarControllerDelegate, SCRHelpHintViewControllerDelegate>

- (IBAction)showPanicAction:(id)sender;
- (IBAction)receiveShareAction:(id)sender;

@end
