//
//  SCRMediaCollectionViewDownloadView.m
//  SecureReader
//
//  Created by N-Pex on 2015-03-31.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaCollectionViewDownloadView.h"
#import "SCRMediaCollectionView.h"

@implementation SCRMediaCollectionViewDownloadView

@synthesize contentView;
@synthesize downloadButton;
@synthesize activityView;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"SCRMediaCollectionViewDownloadView" owner:self options:nil];
        [self.contentView setFrame:frame];
        [self.activityView setHidden:YES];
        [self addSubview:self.contentView];
    }
    return self;
}

- (IBAction)downloadButtonClicked:(id)sender
{
    if (self.delegate != nil)
    {
        [self.delegate downloadButtonClicked:self];
    }
}

@end
