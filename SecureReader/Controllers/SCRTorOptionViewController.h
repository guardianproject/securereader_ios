//
//  SCRTorOptionViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-05-12.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVGDocumentView.h"

@interface SCRTorOptionViewController : UIViewController
- (IBAction)notNow:(id)sender;
- (IBAction)connectTor:(id)sender;
- (IBAction)cancelTor:(id)sender;
@property (weak, nonatomic) IBOutlet SVGDocumentView *artworkView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressTor;
@property (weak, nonatomic) IBOutlet UIButton *cancelTorButton;
@property (weak, nonatomic) IBOutlet UIButton *notNowButton;
@property (weak, nonatomic) IBOutlet UIButton *connectTorButton;
@end
