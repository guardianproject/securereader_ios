//
//  SCRItemViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-11-24.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRFeedViewController.h"

@interface SCRItemViewController : UIViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

- (void) setDataView:(SCRFeedViewController *)feedView withStartAt:(NSIndexPath *)indexPath;

@end