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
#import "SCRAppDelegate.h"
#import "UIView+Theming.h"
#import "SCRTheme.h"

@interface SCRHelpHintViewController ()
@property (strong, nonatomic) NSMutableArray *arrayTargets;
@property (strong, nonatomic) NSMutableArray *arrayTexts;
@property (nonatomic) int currentTarget;
@end

@implementation SCRHelpHintViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.hiliteView != nil)
    {
        [_hiliteView.layer setMasksToBounds:YES];
    }

    if (self.currentTarget < self.arrayTargets.count)
        self.descriptionView.text = [self.arrayTexts objectAtIndex:self.currentTarget];

    if (self.targetViewController != nil && [self.targetViewController isKindOfClass:[UITableViewController class]])
    {
        UITableViewController *controller = (UITableViewController *)self.targetViewController;
        controller.tableView.delegate = self;
    }
}

- (void)addTarget:(NSString *)targetIdentifier withText:(NSString *)text
{
    if (self.arrayTargets == nil)
    {
        self.arrayTargets = [NSMutableArray array];
        self.arrayTexts = [NSMutableArray array];
        self.currentTarget = 0;
    }
    [self.arrayTargets addObject:targetIdentifier];
    [self.arrayTexts addObject:text];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.arrayTargets != nil && self.currentTarget < self.arrayTargets.count && [[self.arrayTargets objectAtIndex:self.currentTarget] isEqualToString:cell.reuseIdentifier])
    {
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGRect frame = cell.textLabel.frame;
        CGRect targetRect = [self.view convertRect:frame fromView:cell];
        targetRect = CGRectInset(targetRect, -5, -5);

        [self updateHilite:targetRect];
        self.hiliteX.constant = targetRect.origin.x;
        self.hiliteY.constant = targetRect.origin.y;
        self.hiliteWidth.constant = targetRect.size.width;
        self.hiliteHeight.constant = targetRect.size.height;
        [self.view setNeedsUpdateConstraints];
    }
}

- (void)doneButtonPressed:(id)sender
{
    self.currentTarget += 1;
    if (self.currentTarget >= self.arrayTargets.count)
    {
        if (self.delegate != nil)
            [self.delegate helpHintViewControllerDidClose:self];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }
    else
    {
        self.descriptionView.text = [self.arrayTexts objectAtIndex:self.currentTarget];
        if (self.targetViewController != nil && [self.targetViewController isKindOfClass:[UITableViewController class]])
        {
            UITableViewController *controller = (UITableViewController *)self.targetViewController;
            [controller.tableView reloadData];
        }
    }
}

- (void)updateHilite:(CGRect)hiliteRect
{
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.frame = self.shaderView.bounds;

    int radius = [SCRTheme getIntegerProperty:@"corners" forTheme:self.hiliteView.theme withDefaultValue:10];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.shaderView.bounds];
    [path appendPath:[UIBezierPath bezierPathWithRoundedRect:hiliteRect cornerRadius:radius]];
    mask.path = path.CGPath;
    mask.fillRule = kCAFillRuleEvenOdd;
    mask.fillColor = [UIColor blackColor].CGColor;
    mask.strokeColor = [UIColor blackColor].CGColor;
    mask.lineWidth = 0;
    self.shaderView.layer.mask = mask;
}

@end
