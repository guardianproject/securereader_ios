//
//  UIAlertView+SecureReader.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-13.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (SecureReader)

- (void)showWithCompletion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion;

@end
