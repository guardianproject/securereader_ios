//
//  SCRMediaServer+SecureReader.h
//  SecureReader
//
//  Created by David Chiles on 7/23/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaServer.h"

@class SCRMediaItem;

@import UIKit;

@interface SCRMediaServer (Video)

- (UIImage *)videoThumbnail:(SCRMediaItem *)mediaItem;
   

@end
