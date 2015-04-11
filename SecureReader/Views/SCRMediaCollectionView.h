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
#import "SCRMediaCollectionViewDownloadView.h"
#import "SCRMediaItem.h"

IB_DESIGNABLE

@interface SCRMediaCollectionView : UIView<SwipeViewDataSource, SwipeViewDelegate, SCRMediaCollectionViewDownloadViewDelegate>

@property (nonatomic) IBInspectable NSInteger downloadViewHeight;
@property (nonatomic) IBInspectable NSInteger imageViewHeight;
@property (nonatomic) IBInspectable NSInteger noImagesViewHeight;

@property (strong) IBOutlet UIView *contentView;
@property (strong) IBOutlet UIPageControl *pageControl;

@property IBInspectable BOOL showDownloadButtonIfNotLoaded;

- (void) setItem:(NSObject *)item;
- (void) createThumbnails:(BOOL)downloadIfNeeded completion:(void(^)())completion;

- (int) numberOfImages;
- (int) currentImageIndex;
- (SCRMediaItem *) currentImageMediaItem;

@end
