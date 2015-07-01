//
//  SCRButton.m
//  SecureReader
//
//  Created by N-Pex on 2015-07-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRButton.h"
#import "SCRTheme.h"
#import "UIView+Theming.h"

@interface SCRButton()
@property (strong, nonatomic) UIColor *backgroundNormal;
@property (strong, nonatomic) UIColor *backgroundDisabled;
@property (strong, nonatomic) UIColor *borderNormal;
@property (strong, nonatomic) UIColor *borderDisabled;
@property (nonatomic) int borderWidthNormal;
@property (nonatomic) int borderWidthDisabled;
@end

@implementation SCRButton

- (void)setTheme:(NSString *)theme
{
    [super setTheme:theme];

    self.backgroundNormal = [SCRTheme getColorProperty:@"backgroundColorNormal" forTheme:self.theme];
    self.backgroundDisabled = [SCRTheme getColorProperty:@"backgroundColorDisabled" forTheme:self.theme];

    self.borderNormal = [SCRTheme getColorProperty:@"borderColorNormal" forTheme:self.theme];
    self.borderDisabled = [SCRTheme getColorProperty:@"borderColorDisabled" forTheme:self.theme];

    self.borderWidthNormal = [(NSNumber*)[SCRTheme getProperty:@"borderWidthNormal" forTheme:self.theme] intValue];
    self.borderWidthDisabled = [(NSNumber*)[SCRTheme getProperty:@"borderWidthDisabled" forTheme:self.theme] intValue];

    UIColor *textColor = [SCRTheme getColorProperty:@"textColorNormal" forTheme:self.theme];
    if (textColor != nil)
        [self setTitleColor:textColor forState:UIControlStateNormal];
    textColor = [SCRTheme getColorProperty:@"textColorDisabled" forTheme:self.theme];
    if (textColor != nil)
        [self setTitleColor:textColor forState:UIControlStateDisabled];

    [self updateStyle];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self updateStyle];
}

- (void) updateStyle
{
    if (self.enabled)
    {
        [self setBackground:self.backgroundNormal edge:self.borderNormal width:self.borderWidthNormal];
    }
    else
    {
        [self setBackground:self.backgroundDisabled edge:self.borderDisabled width:self.borderWidthDisabled];
    }
}

- (void) setBackground:(UIColor *)background edge:(UIColor*)edge width:(int)width
{
    if (background != nil)
        self.layer.backgroundColor = background.CGColor;
    else
        self.layer.backgroundColor = nil;
    if (edge != nil)
        self.layer.borderColor = edge.CGColor;
    else
        self.layer.borderColor = nil;
    self.layer.borderWidth = width;
}


@end
