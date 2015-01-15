//
//  UIBarItem+Theming.h
//  SecureReader
//
//  Created by N-Pex on 2015-01-15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIBarItem (Theming)

@property (nonatomic, assign) NSString *theme UI_APPEARANCE_SELECTOR;
- (void) setTheme:(NSString*)theme;

@end
