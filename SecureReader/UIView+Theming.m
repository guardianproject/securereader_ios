//
//  UIView+Theming.m
//
//  Created by N-Pex on 2014-10-16.
//

#import "UIView+Theming.h"
#import "SRTheme.h"

@implementation UIView (Theming)

@dynamic theme;

- (void)setTheme:(NSString *)theme
{
    [SRTheme applyTheme:theme toControl:(UIControl*)self];
}

@end
