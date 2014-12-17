//
//  SCRReceiveShareView.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRReceiveShareView.h"

@implementation SCRReceiveShareView

@synthesize contentView;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"SCRReceiveShareView" owner:self options:nil];
        [self addSubview:self.contentView];
        [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    }
    return self;
}

//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//    self = [super initWithCoder:aDecoder];
//    if (self)
//    {
//        [[NSBundle mainBundle] loadNibNamed:@"SCRSourceView" owner:self options:nil];
//        self.separator.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.1 alpha:0.5];
//        self.translatesAutoresizingMaskIntoConstraints = NO;
//        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
//        [self addSubview:self.contentView];
//    }
//    return self;
//}

@end
