//
//  SCRHelpHintViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-14.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRHelpHintViewController : UIViewController<UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *hiliteView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hiliteX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hiliteY;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hiliteWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hiliteHeight;

@property (nonatomic) IBInspectable NSString *targetStoryboardId;
@property (nonatomic) IBInspectable NSString *targetSettingsKey;

-(IBAction)doneButtonPressed:(id)sender;

@end
