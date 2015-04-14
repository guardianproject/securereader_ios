//
//  SCRHelpHintViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-14.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRHelpHintViewController.h"
#import <IASKAppSettingsViewController.h>
#import <IASKSettingsReader.h>

@interface SCRHelpHintViewController ()
@property (nonatomic, strong) UIViewController *targetViewController;
@property (nonatomic, strong) NSIndexPath *targetIndexPath;
@property (nonatomic, strong) UIView *targetView;
@end

@implementation SCRHelpHintViewController

-(id)awakeAfterUsingCoder:(NSCoder *)aDecoder
{
    id ret = [super awakeAfterUsingCoder:aDecoder];
    if (self.targetStoryboardId != nil)
    {
        self.targetViewController = [self.storyboard instantiateViewControllerWithIdentifier:self.targetStoryboardId];
        [self addChildViewController:self.targetViewController];
    }
    return ret;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.targetViewController.view setUserInteractionEnabled:NO];
    [self.view insertSubview:self.targetViewController.view atIndex:0];

    if (self.hiliteView != nil)
    {
        [_hiliteView.layer setMasksToBounds:YES];
    }
    
    if (self.targetSettingsKey != nil)
    {
        if ([self.targetViewController isKindOfClass:[IASKAppSettingsViewController class]])
        {
            IASKAppSettingsViewController *settingsViewController = (IASKAppSettingsViewController *)self.targetViewController;
            self.targetIndexPath = [settingsViewController.settingsReader indexPathForKey:self.targetSettingsKey];
            if (self.targetIndexPath != nil)
            {
                //TODO wrap instead of stealing the delegate!
                settingsViewController.tableView.delegate = self;
            }
        }
    }
}

- (void)setTargetSettingsKey:(NSString *)settingsKey
{
    _targetSettingsKey = settingsKey;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.targetIndexPath != nil && [self.targetIndexPath compare:indexPath] == NSOrderedSame)
    {
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGRect frame = cell.textLabel.frame;
        CGRect targetRect = [self.view convertRect:frame fromView:cell];
        targetRect = CGRectInset(targetRect, -11, -7);
        
        self.hiliteX.constant = targetRect.origin.x;
        self.hiliteY.constant = targetRect.origin.y;
        self.hiliteWidth.constant = targetRect.size.width;
        self.hiliteHeight.constant = targetRect.size.height;
        [self.view setNeedsUpdateConstraints];
    }
}

- (void)doneButtonPressed:(id)sender
{
    if ([self shouldPerformSegueWithIdentifier:@"next" sender:self])
    {
        [self performSegueWithIdentifier:@"next" sender:self];
        [self removeFromParentViewController];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
