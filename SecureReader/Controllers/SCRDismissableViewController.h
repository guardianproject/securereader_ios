//
//  SCRDismissableViewController.h
//  SecureReader
//
//  A thin layer built on UIViewController just to add the dismiss action, that can be referenced from interface builder elemetns
//
//  Created by N-Pex on 2015-07-02.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRDismissableViewController : UIViewController
- (IBAction)dismissSelf:(id)sender;
@end
