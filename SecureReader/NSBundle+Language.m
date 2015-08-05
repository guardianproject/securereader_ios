//
//  NSBundle+Language.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-15.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "NSBundle+Language.h"

#import <objc/runtime.h>

static const char _bundle=0;
static const char _language=1;

@interface BundleEx : NSBundle
@end

@implementation BundleEx
-(NSString*)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName
{
    NSBundle* bundle=objc_getAssociatedObject(self, &_bundle);
    return bundle ? [bundle localizedStringForKey:key value:value table:tableName] : [super localizedStringForKey:key value:value table:tableName];
}
@end

@implementation NSBundle (Language)
+(void)setLanguage:(NSString*)language
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      object_setClass([NSBundle mainBundle],[BundleEx class]);
                  });
    NSString *bundleLanguage = language;
    if ([bundleLanguage isEqualToString:@"en"])
        bundleLanguage = @"Base"; // English resources are here
    objc_setAssociatedObject([NSBundle mainBundle], &_bundle, bundleLanguage ? [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:bundleLanguage ofType:@"lproj"]] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject([NSBundle mainBundle], &_language, language, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+(NSString*)getLanguage
{
    return objc_getAssociatedObject(self, &_language);
}
@end