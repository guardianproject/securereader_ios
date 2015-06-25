//
//  SCRLabel.h
//  SecureReader
//
//  Created by N-Pex on 2015-01-28.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface SCRLabel : UILabel

/**
 * lineHeight in percent, e.g. set to 120 for 1.2em. Default is 100.
 */
@property (nonatomic) IBInspectable  NSNumber* lineHeightInPercent;

@end
