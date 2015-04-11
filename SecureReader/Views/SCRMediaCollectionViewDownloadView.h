//
//  SCRMediaCollectionViewDownloadView.h
//  SecureReader
//
//  Created by N-Pex on 2015-03-31.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCRMediaCollectionViewDownloadView;

@protocol SCRMediaCollectionViewDownloadViewDelegate <NSObject>
-(void)downloadButtonClicked:(SCRMediaCollectionViewDownloadView *)view;
@end

@interface SCRMediaCollectionViewDownloadView : UIView

@property (strong) IBOutlet UIView *contentView;
@property (strong) IBOutlet UIView *downloadButton;
@property (strong) IBOutlet UIActivityIndicatorView *activityView;

@property (nonatomic, weak) id<SCRMediaCollectionViewDownloadViewDelegate> delegate;

@end
