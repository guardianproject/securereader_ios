//
//  SCRItemCommentsViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-06-18.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRItem.h"

@interface SCRItemCommentsViewController : UIViewController

@property (strong, nonatomic) SCRItem *item;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end
