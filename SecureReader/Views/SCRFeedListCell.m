//
//  SCRMenuItemWithCountView.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-04.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeedListCell.h"

@interface SCRFeedListCell()
@property BOOL isIniailized;
@property int designTimeTitleTrailingConstraint;
@end

@implementation SCRFeedListCell

@synthesize imageView = _imageView;
@synthesize titleView = _titleView;
@synthesize descriptionView = _descriptionView;
@synthesize switchView = _switchView;

- (void)layoutSubviews
{
    if (!self.isIniailized)
    {
        self.isIniailized = YES;
        self.designTimeTitleTrailingConstraint = self.titleTrailingConstraint.constant;
    }
    if (_showSwitch)
    {
        self.titleTrailingConstraint.constant = self.designTimeTitleTrailingConstraint;
        [_switchView setHidden:NO];
    }
    else
    {
        self.titleTrailingConstraint.constant = self.switchTrailingConstraint.constant;
        [_switchView setHidden:YES];
    }
    [super layoutSubviews];
    _titleView.preferredMaxLayoutWidth = _titleView.bounds.size.width;
    _descriptionView.preferredMaxLayoutWidth = _descriptionView.bounds.size.width;
    [super layoutSubviews];
}

-(void)setShowSwitch:(BOOL)showSwitch
{
    _showSwitch = showSwitch;
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
}

@end
