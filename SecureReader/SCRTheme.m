//
//  SRTheme.m
//
//  Created by N-Pex on 2014-10-16.
//


#import "SCRTheme.h"
#import "UIView+Theming.h"
#import <objc/runtime.h>

@interface SCRTheme ()
{
}
+ (UIColor*) colorWithHexString:(NSString*)hexColorString;
+ (UIColor*) colorWithImageName:(NSString*)imageName;
@end

@implementation SCRTheme

static const char _savedStyle=0;
static const char _currentTheme=1;

static NSMutableDictionary *themes = nil;

+ (void) initialize
{
    if (themes == nil)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Styles" ofType:@"plist"];
        NSData *plistData = [NSData dataWithContentsOfFile:path];
        NSError *error;
        NSPropertyListFormat format;
    
        themes = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable    format:&format error:&error];
        if(!themes)
        {
            NSLog(@"%@", error.localizedDescription);
        }
        else
        {
            // Any defaults we need to apply?
            [[UIButton appearance] setTheme:@"UIButton"];
            [[UIButton appearanceWhenContainedIn:[UITableViewCell class], nil] setTheme:nil];
        }
    }
}
+ (void) saveProperty:(NSString *)property value:(NSObject *)obj forControl:(UIControl *)control
{
    NSMutableDictionary *savedStyle = objc_getAssociatedObject(control, &_savedStyle);
    if (savedStyle != nil && [savedStyle objectForKey:property] == nil)
    {
        if (obj == nil)
            obj = [NSNull null];
        [savedStyle setObject:obj forKey:property];
    }
}

+ (NSObject *) getNillableProperty:(NSString *)property fromDict:(NSDictionary *)dict
{
    NSObject *obj = [dict objectForKey:property];
    if (obj == [NSNull null])
        return nil;
    return obj;
}

+ (void) applyTheme:(NSString*)theme toControl:(UIControl*)control
{
    NSMutableDictionary *savedStyle = objc_getAssociatedObject(control, &_savedStyle);
    NSString *currentTheme = objc_getAssociatedObject(control, &_currentTheme);
    if (savedStyle != nil && currentTheme != nil && ![currentTheme isEqualToString:theme])
    {
        // Reset to old style first
        //
        [self applyStyle:savedStyle toControl:control save:NO];
    }
    
    if (savedStyle == nil)
    {
        savedStyle = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(control, &_savedStyle, savedStyle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // Store which theme we are using
    objc_setAssociatedObject(control, &_currentTheme, theme, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Apply all styles
    NSMutableDictionary *style = nil;
    [SCRTheme getStylesForTheme:theme into:&style];
    if (style != nil)
    {
        [self applyStyle:style toControl:control save:YES];
    }
}


+ (NSObject*) getProperty:(NSString *)property forTheme:(NSString*)theme
{
    NSMutableDictionary *style = nil;
    [SCRTheme getStylesForTheme:theme into:&style];
    if (style != nil)
    {
        return [style objectForKey:property];
    }
    return nil;
}

+ (UIColor*) getColorProperty:(NSString *)property forTheme:(NSString*)theme
{
    NSObject *value = [SCRTheme getProperty:property forTheme:theme];
    if (value != nil)
    {
        if ([value isKindOfClass:[NSString class]])
            return [self colorWithHexString:(NSString *)value];
        else
            return (UIColor *)value;
    }
    return nil;
}

+ (void) applyStyle:(NSDictionary *)style toControl:(UIControl *)control save:(BOOL)save
{
    for (NSString *property in style.keyEnumerator)
    {
        if ([property isEqualToString:@"backgroundColor"] && [control respondsToSelector:@selector(setBackgroundColor:)])
        {
            if (save)
                [SCRTheme saveProperty:property value:[control backgroundColor] forControl:control];
            UIColor *color = nil;
            NSObject *value = [self getNillableProperty:property fromDict:style];
            if ([value isKindOfClass:[NSString class]])
                color =  [self colorWithHexString:(NSString *)value];
            else
                color = (UIColor *)value;
            [control setBackgroundColor:color];
        }
        else if ([property isEqualToString:@"background"] && [control respondsToSelector:@selector(setBackgroundColor:)])
        {
            if (save)
                [SCRTheme saveProperty:property value:[control backgroundColor] forControl:control];
            UIColor *color = nil;
            NSObject *value = [self getNillableProperty:property fromDict:style];
            if ([value isKindOfClass:[NSString class]])
                color =  [self colorWithImageName:(NSString *)value];
            else
                color = (UIColor *)value;
            [control setBackgroundColor:color];
        }
        else if ([property isEqualToString:@"tintColor"] && [control respondsToSelector:@selector(setTintColor:)])
        {
            if (save)
                [SCRTheme saveProperty:property value:[control tintColor] forControl:control];
            UIColor *color = nil;
            NSObject *value = [self getNillableProperty:property fromDict:style];
            if ([value isKindOfClass:[NSString class]])
                color =  [self colorWithHexString:(NSString *)value];
            else
                color = (UIColor *)value;
            [control setTintColor:color];
        }
        else if ([property isEqualToString:@"textColor"] && [control respondsToSelector:@selector(setTextColor:)])
        {
            if (save && [control respondsToSelector:@selector(textColor)])
                [SCRTheme saveProperty:property value:[control performSelector:@selector(textColor)] forControl:control];
            UIColor *color = nil;
            NSObject *value = [self getNillableProperty:property fromDict:style];
            if ([value isKindOfClass:[NSString class]])
                color =  [self colorWithHexString:(NSString *)value];
            else
                color = (UIColor *)value;
            [control performSelector:@selector(setTextColor:) withObject:color];
        }
        else if ([property isEqualToString:@"corners"])
        {
            if (control.layer != nil)
            {
                if (save)
                    [SCRTheme saveProperty:property value:[NSNumber numberWithFloat:control.layer.cornerRadius] forControl:control];
                NSNumber *value = (NSNumber*)[self getNillableProperty:property fromDict:style];
                if (value != nil)
                    control.layer.cornerRadius = [value floatValue];
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
            [SCRTheme getStylesForTheme:parent into:dict];
            
        for (NSString *property in themeDict.keyEnumerator)
        {
            if (*dict == nil)
                *dict = [[NSMutableDictionary alloc] init];
            [*dict setValue:[themeDict objectForKey:property] forKey:property];
        }
    }
}

+ (UIColor*) colorWithHexString:(NSString*)hexColorString
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

+ (UIColor*) colorWithImageName:(NSString*)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    if (image == nil)
        return nil;
    return [UIColor colorWithPatternImage:image];
}

@end
