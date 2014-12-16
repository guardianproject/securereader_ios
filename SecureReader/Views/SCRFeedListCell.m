//
//  SCRMenuItemWithCountView.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-04.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRFeedListCell.h"

@implementation SCRFeedListCell

@synthesize imageView = _imageView;
@synthesize titleView = _titleView;
@synthesize descriptionView = _descriptionView;

- (void)layoutSubviews
{
    [super layoutSubviews];
    _titleView.preferredMaxLayoutWidth = _titleView.bounds.size.width;
    _descriptionView.preferredMaxLayoutWidth = _descriptionView.bounds.size.width;
    [super layoutSubviews];
}

@end
