//
//  SCRTextView.h
//  SecureReader
//
//  Created by N-Pex on 2015-01-28.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface SCRTextView : UITextView<UITextViewDelegate>
@property (nonatomic, strong) IBInspectable UIColor *textColorDisabled;
@property (nonatomic, strong) IBInspectable NSString *prompt;
@end
