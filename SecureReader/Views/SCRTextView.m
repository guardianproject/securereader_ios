//
//  SCRTextView.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-28.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRTextView.h"
#import <objc/runtime.h>
#import "SCRApplication.h"
#import "SCRSettings.h"

@interface SCRTextView ()
@property (nonatomic, weak) id<UITextViewDelegate> originalDelegate;
@property (nonatomic) UIColor *originalTextColor;
@property (nonatomic) BOOL isDisplayingPrompt;
@end

@implementation SCRTextView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangeSetting:)
                                                     name:kSettingChangedNotification
                                                   object:nil];
        [self setFontSizeAdjustment:[SCRSettings fontSizeAdjustment]];
        [super setDelegate:self];
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


- (void) setDelegate:(id<UITextViewDelegate>)delegate
{
    self.originalDelegate = delegate;
}

- (void)setTextColor:(UIColor *)textColor
{
    self.originalTextColor = textColor;
    if (!self.isDisplayingPrompt)
        [super setTextColor:textColor];
}

- (NSString *)getPrompt
{
    return _prompt;
}

- (void)setPrompt:(NSString *)prompt
{
    _prompt = prompt;
    if (self.isDisplayingPrompt || (!self.isFirstResponder && self.text.length == 0))
    {
        [self showPrompt:YES];
    }
}

- (UIColor *)getTextColorDisabled
{
    return _textColorDisabled;
}

- (void)setTextColorDisabled:(UIColor *)textColorDisabled
{
    _textColorDisabled = textColorDisabled;
    if (self.isDisplayingPrompt)
        [super setTextColor:_textColorDisabled];
}

-(void)showPrompt:(BOOL)show
{
    if (show)
    {
        if (!self.isDisplayingPrompt)
            self.originalTextColor = [self textColor];
        [super setTextColor:self.textColorDisabled];
        [super setText:_prompt];
        self.isDisplayingPrompt = YES;
    }
    else
    {
        [super setText:@""];
        [super setTextColor:self.originalTextColor];
        self.isDisplayingPrompt = NO;
    }
}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    BOOL ret = YES;
    if (self.originalDelegate != nil && self.originalDelegate != self && [self.originalDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)])
        ret = [self.originalDelegate textViewShouldBeginEditing:textView];
    if (ret && self.isDisplayingPrompt)
    {
        [self showPrompt:NO];
    }
    return ret;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.text.length == 0)
    {
        [self showPrompt:YES];
    }
    if (self.originalDelegate != nil && self.originalDelegate != self && [self.originalDelegate respondsToSelector:@selector(textViewDidEndEditing:)])
        [self.originalDelegate textViewDidEndEditing:textView];
}

- (NSString *)text
{
    if (self.isDisplayingPrompt)
        return nil;
    return [super text];
}

- (void)setText:(NSString *)text
{
    if (text.length > 0 && self.isDisplayingPrompt)
    {
        [self showPrompt:NO];
    }
    [super setText:text];
    if (self.text.length == 0 && ![self isFirstResponder])
    {
        [self showPrompt:YES];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (self.originalDelegate != nil && self.originalDelegate != self && [self.originalDelegate respondsToSelector:@selector(textViewDidChange:)])
        [self.originalDelegate textViewDidChange:textView];
}

@end
