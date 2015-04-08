//
//  SCREditTagsTextView.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-07.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCREditTagsTextView.h"
#import "SCRTheme.h"

@interface SCREditTagsTextView ()
@property (nonatomic, strong) UIColor *textColorNormal;
@end
@implementation SCREditTagsTextView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview != nil)
    {
        [super setDelegate:self];
    }
}

- (void)setTextColor:(UIColor *)textColor
{
    [super setTextColor:textColor];
    self.textColorNormal = textColor;
}

-(void)setText:(NSString *)text
{
    [super setText:text];
    if (super.text.length > 0)
        [self updateText:super.text lastOperationWasRemove:NO];
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL removed = (range.length > text.length);
    
    NSString *fullText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [self updateText:fullText lastOperationWasRemove:removed];
    return NO;
}

-(void)updateText:(NSString *)fullText lastOperationWasRemove:(BOOL)removed
{
    NSArray *array = [fullText componentsSeparatedByString:@" "];

    NSMutableString *ret = [NSMutableString string];
    for (int i = 0; i < array.count; i++)
    {
        NSString *s = [array objectAtIndex:i];
        if (s.length > 0)
        {
            if (ret.length > 0)
            {
                [ret appendString:@" "];
            }
            if (![s hasPrefix:@"#"])
            {
                [ret appendString:@"#"];
            }
            [ret appendString:[s stringByReplacingOccurrencesOfString:@"#" withString:@"" options:0 range:NSMakeRange(1, s.length -1)]];
        }
        else if (!removed && i > 0 && [[array objectAtIndex:(i - 1)] length] > 1)
        {
            [ret appendString:@" #"];
        }
    }
    
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.font, NSFontAttributeName,
                                     self.textColorNormal, NSForegroundColorAttributeName,
                                     self.backgroundColor, NSBackgroundColorAttributeName,
                                     nil];
    
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:ret attributes:attrsDictionary];
    [attributed beginEditing];
    [ret enumerateSubstringsInRange:NSMakeRange(0, ret.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if ([substring isEqualToString:@"#"])
            [attributed addAttribute:NSForegroundColorAttributeName value:self.textColorDisabled range:substringRange];
    }];
    [attributed endEditing];
    self.attributedText = attributed;
}


@end
