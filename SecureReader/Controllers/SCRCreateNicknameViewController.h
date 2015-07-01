//
//  SCRCreateNicknameViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-06-30.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRCreateNicknameViewController : UIViewController<UITextFieldDelegate>
@property (nonatomic, strong) UIStoryboardSegue *openingSegue;
@property (weak, nonatomic) IBOutlet UITextField *nickname;
@property (weak, nonatomic) IBOutlet UIButton *buttonContinue;
@end
