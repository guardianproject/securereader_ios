//
//  UIBarItem+Theming.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "UIBarItem+Theming.h"
#import "SCRTheme.h"

@implementation UIBarItem (Theming)

@dynamic theme;

- (void)setTheme:(NSString *)theme
{
    [SCRTheme applyTheme:theme toControl:self];
}

@end
