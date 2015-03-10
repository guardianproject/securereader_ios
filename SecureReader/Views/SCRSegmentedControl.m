//
//  SCRSegmentedControl.m
//  SecureReader
//
//  Created by N-Pex on 2015-02-24.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRSegmentedControl.h"
#import "SCRTheme.h"

@implementation SCRSegmentedControl

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        // Get default properties set in stylesheet
        //
        UIColor *textColorNormal = [SCRTheme getColorProperty:@"textColorNormal" forTheme:@"SCRSegmentedControl"];
        UIColor *textColorSelected = [SCRTheme getColorProperty:@"textColorSelected" forTheme:@"SCRSegmentedControl"];
        NSNumber *textSizeNormal = (NSNumber*)[SCRTheme getProperty:@"textSizeNormal" forTheme:@"SCRSegmentedControl"];
        NSNumber *textSizeSelected = (NSNumber*)[SCRTheme getProperty:@"textSizeSelected" forTheme:@"SCRSegmentedControl"];

        int edgeHeight = [(NSNumber*)[SCRTheme getProperty:@"edgeHeight" forTheme:@"SCRSegmentedControl"] intValue];

        UIColor *backgroundColorNormal = [SCRTheme getColorProperty:@"backgroundColorNormal" forTheme:@"SCRSegmentedControl"];
        UIColor *backgroundColorSelected = [SCRTheme getColorProperty:@"backgroundColorSelected" forTheme:@"SCRSegmentedControl"];

        CGRect rect = CGRectMake(0, 0, 1, self.bounds.size.height);
        UIGraphicsBeginImageContext(rect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [backgroundColorNormal CGColor]);
        CGContextFillRect(context, rect);
        CGContextSetFillColorWithColor(context, [backgroundColorSelected CGColor]);
        CGContextFillRect(context, CGRectMake(0, self.bounds.size.height - edgeHeight, 1, edgeHeight));
        
        UIImage *backgroundSelected = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        UIImage *nullImage = [UIImage new];
        [self setDividerImage:nullImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self setDividerImage:nullImage forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [self setDividerImage:nullImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        [self setDividerImage:nullImage forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];

        // Normal state
        NSDictionary *dict = [self titleTextAttributesForState:UIControlStateNormal];
        UIFont *font = nil;
        if (dict != nil)
            font = [dict objectForKey:NSFontAttributeName];
        if (font != nil)
            font = [font fontWithSize:[textSizeNormal floatValue]];
        else
            font = [UIFont systemFontOfSize:[textSizeNormal floatValue]];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:textColorNormal, NSForegroundColorAttributeName, font, NSFontAttributeName, nil];
        [self setTitleTextAttributes:dict forState:UIControlStateNormal];
        [self setBackgroundImage:nullImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

        // Selected state
        dict = [self titleTextAttributesForState:UIControlStateSelected];
        font = nil;
        if (dict != nil)
            font = [dict objectForKey:NSFontAttributeName];
        if (font != nil)
            font = [font fontWithSize:[textSizeSelected floatValue]];
        else
            font = [UIFont systemFontOfSize:[textSizeSelected floatValue]];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:textColorSelected, NSForegroundColorAttributeName, font, NSFontAttributeName, nil];
        [self setTitleTextAttributes:dict forState:UIControlStateSelected];
        [self setBackgroundImage:backgroundSelected forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    }
    return self;
}

@end
