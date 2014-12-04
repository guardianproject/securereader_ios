//
//  SCRMenuItemWithCountView.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-04.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRMenuItemWithCountCell.h"

@implementation SCRMenuItemWithCountCell

@synthesize imageView = _imageView;
@synthesize titleView = _titleView;
@synthesize countView = _countView;

- (void)layoutSubviews
{
    [super layoutSubviews];
    _titleView.preferredMaxLayoutWidth = _titleView.bounds.size.width;
    [super layoutSubviews];
}

@end
