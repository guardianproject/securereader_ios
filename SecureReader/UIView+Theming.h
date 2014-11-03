//
//  UIView+Theming.h
//
//  Created by N-Pex on 2014-10-16.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (Theming)

@property (nonatomic, assign) NSString *theme UI_APPEARANCE_SELECTOR;
- (void) setTheme:(NSString*)theme;

@end

