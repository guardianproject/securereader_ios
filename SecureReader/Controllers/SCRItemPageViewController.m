//
//  SCRItemPageViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemPageViewController.h"
#import "NSString+HTML.h"
#import <UIImageView+AFNetworking.h>
#import "NSFormatter+SecureReader.h"

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    [self.scrollView setContentInset:UIEdgeInsetsMake(navBarHeight, 0, 0, 0)];
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, self.scrollView.frame.size.width, 1) animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setItem:(SCRItem *)item
{
    _item = item;
    NSParameterAssert(item != nil);
    if (!self.item) {
        return;
    }
    [self view]; // force view to load if it hasn't already

    if (self.item.thumbnailURL == nil)
        self.imageViewHeightConstraint.constant = 0;
    else
        [self.imageView setImageWithURL:item.thumbnailURL];
    
    self.sourceView.labelSource.text = [item.linkURL host];
    self.sourceView.labelDate.text = [[NSFormatter scr_sharedIntervalFormatter] stringForTimeIntervalFromDate:[NSDate date] toDate:item.publicationDate];

    self.titleView.text =  self.item.title;
    self.contentView.text = [self.item.itemDescription stringByConvertingHTMLToPlainText];

    [self.view layoutIfNeeded];
}

@end
