//
//  SCRBarButtonItem.h
//  SecureReader
//
//  Created by N-Pex on 2015-05-26.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCRCommentsBarButton : UIButton

/**
 Set a badge to show over the button. Set to nil to hide the badge.
 */
-(void) setBadge:(NSString *)badge;

@end
