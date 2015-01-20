//
//  SCRItemPageViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemPageViewController.h"
#import <UIImageView+AFNetworking.h>
#import <TTTTimeIntervalFormatter.h>

@interface SCRItemPageViewController ()

@end

@implementation SCRItemPageViewController

@synthesize itemIndexPath;

@synthesize imageView = _imageView;
@synthesize imageViewHeightConstraint = _imageViewHeightConstraint;
@synthesize sourceView = _sourceView;
@synthesize titleView = _titleView;
@synthesize contentView = _contentView;

- (void)viewDidLoad {
    [super viewDidLoad];
    [_contentView setScrollEnabled:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setItem:(SCRItem *)item
{
    _item = item;
    NSLog(@"String is %f", self.view.bounds.size.width);
    if (self.item != nil)
    {
        if (self.item.thumbnailURL == nil)
            self.imageViewHeightConstraint.constant = 0;
        else
            [self.imageView setImageWithURL:item.thumbnailURL];
        
        self.sourceView.labelSource.text = [item.linkURL host];
        TTTTimeIntervalFormatter *timeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
        self.sourceView.labelDate.text = [timeIntervalFormatter stringForTimeIntervalFromDate:item.publicationDate toDate:[NSDate dateWithTimeIntervalSinceNow:0]];

        self.titleView.text =  self.item.title;
        self.contentView.text = self.item.itemDescription;

        [self.view layoutIfNeeded];
    }
}

@end
