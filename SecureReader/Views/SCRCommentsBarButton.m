//
//  SCRBarButtonItem.m
//  SecureReader
//
//  Created by N-Pex on 2015-05-26.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRCommentsBarButton.h"
#import "UIView+Theming.h"
#import "SCRTheme.h"

@interface SCRCommentsBarButton ()
@property IBOutlet UIImageView *iconView;
@property IBOutlet UILabel *titleView;
@property IBOutlet UIButton *badgeView;
@property BOOL initialized;
@property (nonatomic, strong) UIColor *colorNormal;
@property (nonatomic, strong) UIColor *colorHighlighted;
@end

@implementation SCRCommentsBarButton

@synthesize iconView;
@synthesize titleView;
@synthesize badgeView;

- (void)setTheme:(NSString *)theme
{
    [super setTheme:theme];
    if (theme != nil)
    {
        _colorNormal = [SCRTheme getColorProperty:@"tintColor" forTheme:theme];
        _colorHighlighted = [_colorNormal colorWithAlphaComponent:0.2];
    }
}

- (void)layoutSubviews
{
    if (!self.initialized)
    {
        self.initialized = YES;
        [self.titleView setTextColor:_colorNormal];
        [self.iconView setImage:[self.iconView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [self setHighlighted:self.highlighted];
    }
    [super layoutSubviews];
    badgeView.layer.cornerRadius = badgeView.bounds.size.height / 2;
    badgeView.layer.masksToBounds = YES;
}

-(void) setHighlighted:(BOOL)highlighted
{
    [self.titleView setTextColor:(highlighted ? _colorHighlighted : _colorNormal)];
    [self.iconView setTintColor:(highlighted ? _colorHighlighted : _colorNormal)];
    [self.badgeView setAlpha:(highlighted ? 0.2 : 1.0)];
    [super setHighlighted:highlighted];
}

- (void)setBadge:(NSString *)badge
{
    [self.badgeView setTitle:badge forState:UIControlStateNormal];
    if (badge == nil)
        self.badgeView.hidden = YES;
    else
        self.badgeView.hidden = NO;
}

@end
