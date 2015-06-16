//
//  SCRReadablityViewController.h
//  SecureReader
//
//  Created by David Chiles on 6/15/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCRItem;

@interface SCRReadablityViewController : UIViewController

@property (nonatomic, strong, readonly) IBOutlet UIWebView *webView;
@property (nonatomic, strong) SCRItem *item;

@end
