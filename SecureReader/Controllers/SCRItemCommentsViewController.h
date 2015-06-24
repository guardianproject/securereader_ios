//
//  SCRItemCommentsViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-06-18.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRItem.h"
#import "SCRTextView.h"

@interface SCRItemCommentsViewController : UIViewController<UITextViewDelegate>

@property (strong, nonatomic) SCRItem *item;
@property (weak, nonatomic) IBOutlet SCRTextView *commentsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentsViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentsViewHeightConstraint;

@end
