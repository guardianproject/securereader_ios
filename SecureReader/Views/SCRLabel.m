//
//  SCRLabel.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-28.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRLabel.h"
#import <objc/runtime.h>
#import "SCRApplication.h"
#import "SCRSettings.h"

@implementation SCRLabel

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    
    // If this is a multiline label, need to make sure
    // preferredMaxLayoutWidth always matches the frame width
    // (i.e. orientation change can mess this up)
    
    if (self.numberOfLines == 0 && bounds.size.width != self.preferredMaxLayoutWidth) {
        self.preferredMaxLayoutWidth = self.bounds.size.width;
        [self setNeedsUpdateConstraints];
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeSetting:)
                                                 name:kSettingChangedNotification
                                               object:nil];
        [self setFontSizeAdjustment:[SCRSettings fontSizeAdjustment]];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didChangeSetting:(NSNotification *)notification
{
    NSString *key = [notification.userInfo objectForKey:@"key"];
    if (key != nil && [key isEqualToString:kFontSizeAdjustmentSettingsKey])
    {
        [self setFontSizeAdjustment:[SCRSettings fontSizeAdjustment]];
    }
}

- (CGFloat) getUnadjustedSize
{
    NSNumber *originalSize = (NSNumber *)objc_getAssociatedObject(self, @selector(setUnadjustedSize:));
    if (originalSize == nil)
    {
        originalSize = [NSNumber numberWithFloat:self.font.pointSize];
        [self setUnadjustedSize:self.font.pointSize];
    }
    return [originalSize floatValue];
}

- (void) setUnadjustedSize:(CGFloat)size
{
    NSNumber *unadjustedSize = [NSNumber numberWithFloat:size];
    objc_setAssociatedObject(self, @selector(setUnadjustedSize:), unadjustedSize, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setFontSizeAdjustment:(float)fontSizeAdjustment
{
    CGFloat originalSize = [self getUnadjustedSize];
    [super setFont:[self.font fontWithSize:(originalSize + fontSizeAdjustment)]];
}

- (void)setFont:(UIFont *)font
{
    [self setUnadjustedSize:font.pointSize];
    [super setFont:[font fontWithSize:(font.pointSize + [SCRSettings fontSizeAdjustment])]];
}

- (void)setText:(NSString *)text
{
    if (self.lineHeightInPercent != nil && [self.lineHeightInPercent intValue] != 100)
    {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineHeightMultiple = [self.lineHeightInPercent floatValue] / 100.0;
        NSDictionary *attrsDictionary = @{ NSFontAttributeName: self.font, NSParagraphStyleAttributeName: paragraphStyle};
        [self setAttributedText:[[NSAttributedString alloc] initWithString:text attributes:attrsDictionary]];
    }
    else
    {
        [super setText:text];
    }
}

@end
