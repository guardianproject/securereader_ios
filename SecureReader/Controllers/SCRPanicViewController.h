//
//  SCRPanicViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-12-05.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRPanicViewController : UIViewController

@property IBOutlet UIImageView *panicDragThumb;
@property IBOutlet UIView *panicDropZone;
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;

@end
