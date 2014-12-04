//
//  SCRMenuItemWithCountView.h
//  SecureReader
//
//  Created by N-Pex on 2014-12-04.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRMenuItemWithCountCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *countView;

@end
