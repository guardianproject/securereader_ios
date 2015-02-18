//
//  SRTheme.m
//
//  Created by N-Pex on 2014-10-16.
//


#import "SCRTheme.h"
#import "UIView+Theming.h"
#import "UIBarItem+Theming.h"
#import <objc/runtime.h>
#import "SCRGradientBackgroundView.h"
#import "SCRApplication.h"

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
            //[[UIButton appearance] setTheme:@"UIButton"];
            //[[UIButton appearanceWhenContainedIn:[UITableViewCell class], nil] setTheme:nil];
            //[[UIBarItem appearance] setTheme:@"UIBarButton"];
            
            id barButtonAppearanceInSearchBar = [UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil];
            [barButtonAppearanceInSearchBar setTitle:getLocalizedString(@"Feed_List_Search_Done", @"Done")];
        }
    }
}
+ (void) saveProperty:(NSString *)property value:(NSObject *)obj forControl:(NSObject *)control
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

+ (NSString *) getThemeForControl:(NSObject*)control
{
    return objc_getAssociatedObject(control, &_currentTheme);
}

+ (void) applyTheme:(NSString*)theme toControl:(NSObject*)control
{
    NSMutableDictionary *savedStyle = objc_getAssociatedObject(control, &_savedStyle);
    NSString *currentTheme = objc_getAssociatedObject(control, &_currentTheme);
    if (savedStyle != nil && currentTheme != nil && ![currentTheme isEqualToString:theme])
    {
        if ([theme isEqualToString:@"UIButton"])
            return;
        
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

+ (void) applyStyle:(NSDictionary *)style toControl:(NSObject *)control save:(BOOL)save
{
    for (NSString *property in style.keyEnumerator)
    {
        if ([property isEqualToString:@"backgroundColor"] && [control respondsToSelector:@selector(setBackgroundColor:)])
        {
            if (save && [control respondsToSelector:@selector(backgroundColor)])
                [SCRTheme saveProperty:property value:[control performSelector:@selector(backgroundColor)] forControl:control];
            UIColor *color = nil;
            NSObject *value = [self getNillableProperty:property fromDict:style];
            if ([value isKindOfClass:[NSString class]])
                color =  [self colorWithHexString:(NSString *)value];
            else
                color = (UIColor *)value;
            [control performSelector:@selector(setBackgroundColor:) withObject:color];
        }
        else if ([property isEqualToString:@"background"] && [control respondsToSelector:@selector(setBackgroundColor:)])
        {
            if (save && [control respondsToSelector:@selector(backgroundColor)])
                [SCRTheme saveProperty:property value:[control performSelector:@selector(backgroundColor)] forControl:control];
            UIColor *color = nil;
            NSObject *value = [self getNillableProperty:property fromDict:style];
            if ([value isKindOfClass:[NSString class]])
                color =  [self colorWithImageName:(NSString *)value];
            else
                color = (UIColor *)value;
            [control performSelector:@selector(setBackgroundColor:) withObject:color];
        }
        else if ([property isEqualToString:@"tintColor"] && [control respondsToSelector:@selector(setTintColor:)])
        {
            if (save && [control respondsToSelector:@selector(tintColor)])
                [SCRTheme saveProperty:property value:[control performSelector:@selector(tintColor)] forControl:control];
            UIColor *color = nil;
            NSObject *value = [self getNillableProperty:property fromDict:style];
            if ([value isKindOfClass:[NSString class]])
                color =  [self colorWithHexString:(NSString *)value];
            else
                color = (UIColor *)value;
            [control performSelector:@selector(setTintColor:) withObject:color];
        }
        else if ([property isEqualToString:@"onTintColor"] && [control respondsToSelector:@selector(setOnTintColor:)])
        {
            if (save && [control respondsToSelector:@selector(onTintColor)])
                [SCRTheme saveProperty:property value:[control performSelector:@selector(onTintColor)] forControl:control];
            UIColor *color = nil;
            NSObject *value = [self getNillableProperty:property fromDict:style];
            if ([value isKindOfClass:[NSString class]])
                color =  [self colorWithHexString:(NSString *)value];
            else
                color = (UIColor *)value;
            [control performSelector:@selector(setOnTintColor:) withObject:color];
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
            if ([control isKindOfClass:[UIControl class]])
            {
                UIControl *uiControl = (UIControl *)control;
                if (uiControl.layer != nil)
                {
                    if (save)
                        [SCRTheme saveProperty:property value:[NSNumber numberWithFloat:uiControl.layer.cornerRadius] forControl:control];
                    NSNumber *value = (NSNumber*)[self getNillableProperty:property fromDict:style];
                    if (value != nil)
                        uiControl.layer.cornerRadius = [value floatValue];
                }
            }
        }
        else if ([property isEqualToString:@"textSize"] && [control respondsToSelector:@selector(setFont:)] && [control respondsToSelector:@selector(font)])
        {
            UIFont *font = [control performSelector:@selector(font)];
            if (save)
                [SCRTheme saveProperty:property value:[NSNumber numberWithFloat:[font pointSize]] forControl:control];
            
            NSNumber *value = (NSNumber*)[self getNillableProperty:property fromDict:style];
            if (value != nil)
                [control performSelector:@selector(setFont:) withObject:[font fontWithSize:[value floatValue]]];
        }
        else if ([property isEqualToString:@"backgroundGradientV"])
        {
            NSMutableArray *colorArray = nil;
            NSMutableArray *stopsArray = nil;

            NSString *value = (NSString *)[self getNillableProperty:property fromDict:style];
            if (value != nil)
            {
                NSArray *gradientArray = [value componentsSeparatedByString: @":"];
                if (gradientArray.count > 0)
                {
                    // Parse the actual color values
                    NSArray *colorHexStringArray = [[gradientArray objectAtIndex:0] componentsSeparatedByString:@","];
                    colorArray = [[NSMutableArray alloc] initWithCapacity:[colorHexStringArray count]];
                    [colorHexStringArray enumerateObjectsUsingBlock:^(NSString *colorHexString, NSUInteger idx, BOOL *stop) {
                        [colorArray setObject:(id)[[SCRTheme colorWithHexString:colorHexString] CGColor] atIndexedSubscript:idx];
                    }];
                    
                    // Parse optional gradient stops
                    if (gradientArray.count > 1)
                    {
                        NSArray *stopsStringArray = [[gradientArray objectAtIndex:1] componentsSeparatedByString:@","];
                        stopsArray = [[NSMutableArray alloc] initWithCapacity:[stopsStringArray count]];
                        [stopsStringArray enumerateObjectsUsingBlock:^(NSString *stopString, NSUInteger idx, BOOL *stop) {
                            [stopsArray setObject:(id)[NSNumber numberWithFloat:[stopString floatValue]] atIndexedSubscript:idx];
                        }];
                    }
                }
                
                if ([control respondsToSelector:@selector(setBackgroundColors:withLocations:)])
                    [control performSelector:@selector(setBackgroundColors:withLocations:) withObject:colorArray withObject:stopsArray];
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
