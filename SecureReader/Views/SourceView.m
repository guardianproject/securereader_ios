//
//  SourceView.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SourceView.h"

@interface SourceView ()
@property (weak, nonatomic) IBOutlet UIView *separator;
@property (nonatomic, strong) NSMutableArray *customConstraints;
@end

@implementation SourceView

@synthesize contentView;

//- (void) awakeFromNib
//{
//    [super awakeFromNib];
//    if (self)
//    {
//        [[NSBundle mainBundle] loadNibNamed:@"SourceView" owner:self options:nil];
//        self.separator.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.1 alpha:0.5];
//        [self addSubview:self.contentView];
//    }
//}
//
//- (instancetype)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self)
//    {
//        [[NSBundle mainBundle] loadNibNamed:@"SourceView" owner:self options:nil];
//        self.separator.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.1 alpha:0.5];
//        [self addSubview:self.contentView];
//    }
//    return self;
//}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"SourceView" owner:self options:nil];
        self.separator.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.1 alpha:0.5];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.contentView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    }
    return self;
}

@end
