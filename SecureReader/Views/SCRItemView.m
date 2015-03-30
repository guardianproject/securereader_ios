//
//  ItemView.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemView.h"

@implementation SCRItemView

@synthesize mediaCollectionView = _mediaCollectionView;
@synthesize sourceView = _sourceView;
@synthesize titleView = _titleView;
@synthesize textView = _textView;

- (void)layoutSubviews
{
    [super layoutSubviews];
    _titleView.preferredMaxLayoutWidth = _titleView.bounds.size.width;
    [super layoutSubviews];
}

@end
