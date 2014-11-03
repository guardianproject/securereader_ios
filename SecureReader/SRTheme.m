//
//  SRTheme.m
//
//  Created by N-Pex on 2014-10-16.
//


#import "SRTheme.h"
#import "UIView+Theming.h"

@interface SRTheme ()
{
}
+(UIColor*) colorFromString:(NSString*)hexColorString;
@end

@implementation SRTheme

static NSMutableDictionary *themes;

+ (void) initialize
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Styles" ofType:@"plist"];
    NSData *plistData = [NSData dataWithContentsOfFile:path];
    NSError *error;
    NSPropertyListFormat format;
    
    themes = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error];
    if(!themes)
    {
        NSLog(error.localizedDescription);
    }
    else
    {
        // Any defaults we need to apply?
        [[UIButton appearance] setTheme:@"UIButton"];
    }
}

+ (void) applyTheme:(NSString*)theme toControl:(UIControl*)control
{
    NSMutableDictionary *styles = nil;
    [SRTheme getStylesForTheme:theme into:&styles];
    if (styles != nil)
    {
        for (NSString *property in styles.keyEnumerator)
        {
            if ([property isEqualToString:@"backgroundColor"] && [control respondsToSelector:@selector(setBackgroundColor:)])
            {
                UIColor *color = [self colorFromString:[styles objectForKey:property]];
                [control setBackgroundColor:color];
            }
            else if ([property isEqualToString:@"background"] && [control respondsToSelector:@selector(setBackgroundColor:)])
            {
                UIImage *image = [UIImage imageNamed:[styles objectForKey:property]];
                if (image != nil)
                {
                    UIColor *color = [UIColor colorWithPatternImage:image];
                    [control setBackgroundColor:color];
                }
            }
            else if ([property isEqualToString:@"tintColor"] && [control respondsToSelector:@selector(setTintColor:)])
            {
                UIColor *color = [self colorFromString:[styles objectForKey:property]];
                [control setTintColor:color];
            }
            else if ([property isEqualToString:@"corners"])
            {
                if (control.layer != nil)
                    control.layer.cornerRadius = [[styles objectForKey:property] floatValue];
            }
        }
    }
}

+ (void) getStylesForTheme:(NSString*)theme into:(NSMutableDictionary **)dict
{
    NSDictionary *themeDict = [themes objectForKey:theme];
    if (themeDict != nil)
    {
        NSString *parent = [themeDict objectForKey:@"parent"];
        if (parent != nil)
            [SRTheme getStylesForTheme:parent into:dict];
            
        for (NSString *property in themeDict.keyEnumerator)
        {
            if (*dict == nil)
                *dict = [[NSMutableDictionary alloc] init];
            [*dict setValue:[themeDict objectForKey:property] forKey:property];
        }
    }
}

+(UIColor*) colorFromString:(NSString*)hexColorString
{
    NSScanner *scanner = [NSScanner scannerWithString:hexColorString];
    [scanner setScanLocation:1];
    unsigned hex;
    if (![scanner scanHexInt:&hex]) return nil;
    int a = (hex >> 24) & 0xFF;
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}


@end
