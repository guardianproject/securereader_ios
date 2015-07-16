//
//  UIView+Theming.m
//
//  Created by N-Pex on 2014-10-16.
//

#import "UIView+Theming.h"
#import "SCRTheme.h"

@implementation UIView (Theming)

- (NSString *)theme
{
    return [SCRTheme getThemeForControl:self];
}

- (void)setTheme:(NSString *)theme
{
    [SCRTheme applyTheme:theme toControl:self];
}

@end
