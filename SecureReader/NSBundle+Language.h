//
//  NSBundle+Language.h
//  SecureReader
//
//  Created by N-Pex on 2014-09-15.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (Language)
+(void)setLanguage:(NSString*)language;
+(NSString*)getLanguage;
@end
