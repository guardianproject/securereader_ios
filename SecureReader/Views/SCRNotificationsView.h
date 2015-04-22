//
//  SCRNotificationsView.h
//  SecureReader
//
//  Created by David Chiles on 4/21/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRNotificationsView : UIView

@property (nonatomic, strong, readonly) UILabel *textLabel;

/** A square view pinned to the leading edge of the text label*/
@property (nonatomic, strong) UIView *accessoryView;

@end
