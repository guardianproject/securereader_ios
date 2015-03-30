//
//  ItemView.h
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRSourceView.h"
#import <SWTableViewCell.h>
#import "SCRItem.h"
#import "SCRMediaCollectionView.h"

@interface SCRItemView : SWTableViewCell

@property (weak, nonatomic) SCRItem *item;
@property (weak, nonatomic) IBOutlet SCRMediaCollectionView *mediaCollectionView;
@property (weak, nonatomic) IBOutlet SCRSourceView *sourceView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITextField *textView;
@property (weak, nonatomic) IBOutlet UICollectionView *tagCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *tagCollectionViewLayout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tagCollectionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tagCollectionViewBottomConstraint;

@end
