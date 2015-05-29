//
//  SCRHelpHintViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-14.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SCRHelpHintViewControllerDelegate;

@interface SCRHelpHintViewController : UIViewController<UITableViewDelegate>

@property (nonatomic, weak) id<SCRHelpHintViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *shaderView;
@property (weak, nonatomic) IBOutlet UIView *hiliteView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hiliteX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hiliteY;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hiliteWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *hiliteHeight;

@property (weak, nonatomic) UIViewController *targetViewController;

-(void) addTarget:(NSString *)targetIdentifier withText:(NSString *)text;

@end

@protocol SCRHelpHintViewControllerDelegate
-(void)helpHintViewControllerDidClose:(SCRHelpHintViewController*)viewController;
@end

