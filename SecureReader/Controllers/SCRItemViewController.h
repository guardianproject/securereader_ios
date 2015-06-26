//
//  SCRItemViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-11-24.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRFeedViewController.h"
#import "SCRCommentsBarButton.h"
#import "SCRItem.h"

@protocol SCRItemViewControllerDataSource
- (SCRItem*) itemForIndexPath:(NSIndexPath *)indexPath;
@end

@interface SCRItemViewController : UIViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate>

- (void) setDataView:(id<SCRItemViewControllerDataSource>)dataView withStartAt:(NSIndexPath *)indexPath;

/**
 * Set whether the favorite button should be shown in the toolbar.
 */
@property (nonatomic) BOOL showsFavoriteButton;

@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIView *textSizeView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textSizeViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UISlider *textSizeSlider;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonFavorite;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonFavoriteSpace;
@property (weak, nonatomic) IBOutlet SCRCommentsBarButton *buttonComment;

@end