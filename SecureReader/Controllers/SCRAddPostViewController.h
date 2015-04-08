//
//  SCRAddPostViewController.h
//  SecureReader
//
//  Created by N-Pex on 2015-03-31.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRPostItem.h"
#import "SCRTextView.h"

@interface SCRAddPostViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet SCRTextView *titleView;
@property (weak, nonatomic) IBOutlet SCRTextView *descriptionView;
@property (weak, nonatomic) IBOutlet SCRTextView *tagView;
-(void) editItem:(SCRPostItem *)item;

@end
