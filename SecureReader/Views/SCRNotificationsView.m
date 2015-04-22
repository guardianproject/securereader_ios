//
//  SCRNotificationsView.m
//  SecureReader
//
//  Created by David Chiles on 4/21/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRNotificationsView.h"
#import "PureLayout.h"


CGFloat const kSCRNotificationsViewMargin = 3;

@interface SCRNotificationsView ()

@property (nonatomic) BOOL addConstraints;

@property (nonatomic, strong) NSLayoutConstraint *textLabelLeadingEdge;

/** Help center text label and accessory view */
@property (nonatomic, strong) UIView *leadingMarginView;
@property (nonatomic, strong) UIView *trailingMarginView;

@end

@implementation SCRNotificationsView

- (instancetype)initWithFrame:(CGRect)frame
{
    if  (self = [super initWithFrame:frame]) {
        _textLabel = [[UILabel alloc] initForAutoLayout];
        
        self.leadingMarginView = [[UIView alloc] initForAutoLayout];
        self.leadingMarginView.backgroundColor = [UIColor clearColor];
        self.trailingMarginView = [[UIView alloc] initForAutoLayout];
        self.trailingMarginView.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.textLabel];
        [self addSubview:self.leadingMarginView];
        [self addSubview:self.trailingMarginView];
        
    }
    return self;
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    [self.accessoryView removeFromSuperview];
    _accessoryView = accessoryView;
    
    if(accessoryView) {
        [self addSubview:self.accessoryView];
        
        [self.textLabelLeadingEdge autoRemove];
        
        [self.accessoryView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.leadingMarginView];
        [self.accessoryView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:kSCRNotificationsViewMargin];
        [self.accessoryView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:kSCRNotificationsViewMargin];
        [self.accessoryView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.accessoryView];
        
        [self.accessoryView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    }
    
    [self addTextLabelLeadingEdgeConstraint];
    
    [self setNeedsUpdateConstraints];
}

- (void)addTextLabelLeadingEdgeConstraint
{
    [self.textLabelLeadingEdge autoRemove];
    if(self.accessoryView) {
        self.textLabelLeadingEdge = [self.textLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.accessoryView withOffset:kSCRNotificationsViewMargin];
    } else {
        self.textLabelLeadingEdge = [self.textLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.leadingMarginView];
    }
}

- (void)updateConstraints
{
    if (!self.addConstraints) {
        
        [self.leadingMarginView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTrailing];
        [self.trailingMarginView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeLeading];
        
        [self.leadingMarginView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.trailingMarginView];
        
        [self.textLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:kSCRNotificationsViewMargin];
        [self.textLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:kSCRNotificationsViewMargin];
        [self.textLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.trailingMarginView];
        
        [self addTextLabelLeadingEdgeConstraint];
        
        self.addConstraints = YES;
    }
    [super updateConstraints];
}

@end
