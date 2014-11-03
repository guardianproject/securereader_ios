//
//  SRLoginViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-09-15.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SRSelectLanguageViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UIPickerView *pickerLanguage;
@property (weak, nonatomic) IBOutlet UIView *pickerFrame;
@property (weak, nonatomic) IBOutlet UILabel *labelCurrentLanguage;

- (IBAction)getStartedButtonClicked:(id)sender;
- (IBAction)selectLanguageButtonClicked:(id)sender;
- (IBAction)saveLanguageButtonClicked:(id)sender;

@end
