//
//  SRTheme.h
//
//  Created by N-Pex on 2014-10-16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SCRTheme : NSObject

+ (void) applyTheme:(NSString*)theme toControl:(UIControl*)control;
+ (NSObject*) getProperty:(NSString *)property forTheme:(NSString*)theme;
+ (UIColor*) getColorProperty:(NSString *)property forTheme:(NSString*)theme;

@end
