//
//  UIGradientBackgroundView.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-20.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRGradientBackgroundView.h"

@interface SCRGradientBackgroundView()
@property CAGradientLayer *gradientLayer;
@end

@implementation SCRGradientBackgroundView

- (void) setBackgroundColors:(NSArray *)colors withLocations:(NSArray *)locations
{
    if (_gradientLayer != nil)
        [_gradientLayer removeFromSuperlayer];
    
    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.frame = self.bounds;
    _gradientLayer.colors = colors;
    _gradientLayer.locations = locations;
    [self.layer insertSublayer:_gradientLayer atIndex:0];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (_gradientLayer != nil)
        _gradientLayer.frame = self.bounds;
}

@end
