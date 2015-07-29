//
//  SCRPulseView.m
//  SecureReader
//
//  Created by N-Pex on 2015-05-27.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPulseView.h"
#import "SCRTheme.h"

@interface SCRPulseView ()
@property (nonatomic, strong) UIColor *viewColor;
@end

@implementation SCRPulseView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        [self setUserInteractionEnabled:NO];
        self.viewColor = [SCRTheme getColorProperty:@"highlightColor" forTheme:@"Colors"];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Remove all sublayers
    //
    if (self.layer.sublayers != nil)
    {
        for (long i = self.layer.sublayers.count - 1; i >= 0; i--)
        {
            CALayer *layer = [self.layer.sublayers objectAtIndex:i];
            [layer removeAllAnimations];
            [layer removeFromSuperlayer];
        }
    }
    
    [self addCicle];
    [self addCicleToStartIn:0];
    [self addCicleToStartIn:.3];
    [self addCicleToStartIn:0.6];
}

- (void) addCicle
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    [self.layer addSublayer:circle];
    circle.path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, self.bounds.size.width / 2 - 3, self.bounds.size.height / 2 - 3)].CGPath;
    circle.fillColor = self.viewColor.CGColor;
    circle.strokeColor = self.viewColor.CGColor;
    circle.lineWidth = 2;
}

- (void) addCicleToStartIn:(float) ms
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    [self.layer addSublayer:circle];
    
    circle.path = nil;
    circle.fillColor = [UIColor clearColor].CGColor;
    circle.strokeColor = self.viewColor.CGColor;
    circle.lineWidth = 2;
    
    // Add to parent layer
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    scaleAnimation.fromValue = (__bridge id)([UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds), 0, 0)].CGPath);
    scaleAnimation.toValue = (__bridge id)([UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath);
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    alphaAnimation.toValue = [NSNumber numberWithFloat:0];
    
    CAAnimationGroup* group = [CAAnimationGroup animation];
    group.animations = [NSArray arrayWithObjects:scaleAnimation, alphaAnimation, nil];
    group.beginTime = CACurrentMediaTime() + ms;
    group.timeOffset = 0;
    group.duration = 2.0;
    group.repeatCount = 3;
    group.autoreverses = NO;
    group.fillMode = kCAFillModeBoth;
    group.removedOnCompletion = YES;
    [circle addAnimation:group forKey:[NSString stringWithFormat:@"Circle%f", ms]];
}


@end
