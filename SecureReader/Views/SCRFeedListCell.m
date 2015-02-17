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
@end

@implementation SCRFeedListCell

@synthesize imageView = _imageView;
@synthesize titleView = _titleView;
@synthesize descriptionView = _descriptionView;

- (void)layoutSubviews
{
    if (!self.isIniailized)
    {
        self.isIniailized = YES;
    }
    [super layoutSubviews];
    _titleView.preferredMaxLayoutWidth = _titleView.bounds.size.width;
    _descriptionView.preferredMaxLayoutWidth = _descriptionView.bounds.size.width;
    [super layoutSubviews];
}

@end
