//
//  SCRPanicViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-05.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRPanicViewController.h"
#import "SCRApplication.h"
#import "SCRPanicController.h"

@interface SCRPanicViewController ()
- (IBAction)closePanicAction:(id)sender;
@property (nonatomic) CGPoint panicDragThumbStartingPoint;
@end

@implementation SCRPanicViewController

@synthesize panicDragThumb;
@synthesize panicDragThumbStartingPoint;
@synthesize panicDropZone;

- (void)viewDidLoad {
    [super viewDidLoad];
     self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closePanicAction:)];
    panicDragThumb.image = [panicDragThumb.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [panicDragThumb setTintColor:[UIColor whiteColor]];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    panicDragThumbStartingPoint = CGPointMake(panicDragThumb.center.x, panicDragThumb.center.y);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)closePanicAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {

    if (recognizer.state == UIGestureRecognizerStateEnded) {

        if (CGRectIntersectsRect(panicDropZone.frame, panicDragThumb.frame))
        {
            // Dropped in drop zone, panic!
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                panicDragThumb.transform = CGAffineTransformMakeScale(0.1, 0.1);
                panicDragThumb.center = panicDropZone.center;
            } completion:^(BOOL finished)
             {
                 [panicDragThumb setHidden:YES];
                 [SCRPanicController showPanicConfirmationDialogInViewController:self];
             }
             ];
        }
        else
        {
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                recognizer.view.center = panicDragThumbStartingPoint;
            } completion:nil];
        }
    }
    else
    {
        CGPoint translation = [recognizer translationInView:self.view];
        recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                         recognizer.view.center.y + translation.y);
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
        
        // Is the frame over the drop zone?
        if (CGRectIntersectsRect(panicDropZone.frame, panicDragThumb.frame))
            [panicDragThumb setTintColor:[UIColor redColor]];
        else
            [panicDragThumb setTintColor:[UIColor whiteColor]];
    }
}

@end
