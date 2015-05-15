//
//  SCRFeedListCategoryCell.h
//  SecureReader
//
//  Created by N-Pex on 2015-05-15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SVGKit.h>

@interface SCRFeedListCategoryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet SVGKImageView *categoryImage;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@end
