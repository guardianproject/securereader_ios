//
//  SCRMediaCollectionView.h
//  SecureReader
//
//  Created by N-Pex on 2015-03-20.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRItem.h"
#import <SwipeView.h>

@interface SCRMediaCollectionView : UIView<SwipeViewDataSource, SwipeViewDelegate>

@property (strong) IBOutlet UIView *contentView;
@property (strong) IBOutlet UIView *downloadButton;
@property (strong) IBOutlet UIView *activityView;

@property BOOL showDownloadButtonIfNoneLoaded;

- (void) setItem:(SCRItem *)item;
- (void) createThumbnails:(BOOL)downloadIfNeeded;

@end
