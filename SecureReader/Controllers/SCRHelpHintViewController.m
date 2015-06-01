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
@property (nonatomic) int cornerRadius;
@property (nonatomic) int currentTarget;
@property (nonatomic) CGRect currentHiliteRect;
@end

@implementation SCRHelpHintViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.hiliteView != nil)
    {
        [_hiliteView.layer setMasksToBounds:YES];
    }

    self.currentHiliteRect = CGRectNull;
    self.cornerRadius = [SCRTheme getIntegerProperty:@"corners" forTheme:self.hiliteView.theme withDefaultValue:10];
    
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.frame = self.shaderView.bounds;
    mask.fillRule = kCAFillRuleEvenOdd;
    mask.fillColor = [UIColor blackColor].CGColor;
    mask.strokeColor = [UIColor blackColor].CGColor;
    mask.lineWidth = 0;
    self.shaderView.layer.mask = mask;
    
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
        CGSize textSize = [[cell.textLabel text] sizeWithAttributes:@{NSFontAttributeName:[cell.textLabel font]}];
        frame.size.width = textSize.width;
        
        CGRect targetRect = [self.view convertRect:frame fromView:cell];
        targetRect = CGRectInset(targetRect, -10, -5);

        [self updateHilite:targetRect animated:!CGRectIsNull(self.currentHiliteRect)];
    }
}

- (void)doneButtonPressed:(id)sender
{
    self.currentTarget += 1;
    if (self.currentTarget >= self.arrayTargets.count)
    {
        // Fade out and remove
        //
        [UIView animateWithDuration:kSCRHintViewAnimationFadeInDuration animations:^{
            [self.view setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (self.delegate != nil)
                [self.delegate helpHintViewControllerDidClose:self];
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }];
    }
    else
    {
        // Normally we would set the description here, but since we animate the hilite, we set it once
        // the description view is faded into invisibility.
        //self.descriptionView.text = [self.arrayTexts objectAtIndex:self.currentTarget];
        if (self.targetViewController != nil && [self.targetViewController isKindOfClass:[UITableViewController class]])
        {
            UITableViewController *controller = (UITableViewController *)self.targetViewController;
            [controller.tableView reloadData];
        }
    }
}

- (void)updateHilite:(CGRect)hiliteRect animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:kSCRHintViewAnimationTextFadeOutDuration animations:^{
            self.buttonView.alpha = 0;
            self.descriptionView.alpha = 0;
        } completion:^(BOOL finished) {
            self.hiliteX.constant = hiliteRect.origin.x;
            self.hiliteY.constant = hiliteRect.origin.y;
            self.hiliteWidth.constant = hiliteRect.size.width;
            self.hiliteHeight.constant = hiliteRect.size.height;
            [self.view setNeedsUpdateConstraints];
            
            UIBezierPath *pathFrom = [UIBezierPath bezierPathWithRect:self.shaderView.bounds];
            [pathFrom appendPath:[UIBezierPath bezierPathWithRoundedRect:self.currentHiliteRect cornerRadius:self.cornerRadius]];
            
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.shaderView.bounds];
            [path appendPath:[UIBezierPath bezierPathWithRoundedRect:hiliteRect cornerRadius:self.cornerRadius]];
            
                CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
                pathAnimation.fromValue = (__bridge id)(pathFrom.CGPath);
                pathAnimation.toValue = (__bridge id)(path.CGPath);
                pathAnimation.duration = kSCRHintViewAnimationHiliteMoveDuration;
                pathAnimation.repeatCount = 0;
                pathAnimation.removedOnCompletion = NO;
                pathAnimation.fillMode = kCAFillModeForwards;
                pathAnimation.delegate = self;
                [self.shaderView.layer.mask addAnimation:pathAnimation forKey:@"pathAnimation"];
                self.currentHiliteRect = hiliteRect;
        }];
    }
    else
    {
        self.currentHiliteRect = hiliteRect;

        UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.shaderView.bounds];
        [path appendPath:[UIBezierPath bezierPathWithRoundedRect:hiliteRect cornerRadius:self.cornerRadius]];
        [(CAShapeLayer *)self.shaderView.layer.mask setPath:path.CGPath];
        
        self.hiliteX.constant = hiliteRect.origin.x;
        self.hiliteY.constant = hiliteRect.origin.y;
        self.hiliteWidth.constant = hiliteRect.size.width;
        self.hiliteHeight.constant = hiliteRect.size.height;
        [self.view setNeedsUpdateConstraints];
    }

}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    self.descriptionView.text = [self.arrayTexts objectAtIndex:self.currentTarget];

    [UIView animateWithDuration:kSCRHintViewAnimationTextFadeInDuration animations:^{
        self.buttonView.alpha = 1.0;
        self.descriptionView.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];    
}


@end
