//
//  SCRAuthorView.h
//  SecureReader
//
//  Created by N-Pex on 2015-01-20.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRAuthorView : UIView

@property (strong) IBOutlet UIView *contentView;

@property IBOutlet UILabel *labelDate;
@property IBOutlet UILabel *labelTime;
@property IBOutlet UILabel *labelAuthorName;

@end
