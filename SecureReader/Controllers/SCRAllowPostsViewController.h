//
//  SCRAllowPostsViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-07-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRAllowPostsViewController : UIViewController
@property (nonatomic, strong) UIStoryboardSegue *openingSegue;
@property (weak, nonatomic) IBOutlet UIButton *buttonContinue;
@property (weak, nonatomic) IBOutlet UIImageView *buttonPermission;
@property (weak, nonatomic) IBOutlet UILabel *labelPermission;
@end
