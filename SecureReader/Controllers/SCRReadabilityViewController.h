//
//  SCRReadablityViewController.h
//  SecureReader
//
//  Created by David Chiles on 6/15/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCRItem;

@interface SCRReadabilityViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) SCRItem *item;

- (IBAction)segmentedControlDidChange:(id)sender;

@end
