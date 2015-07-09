//
//  SCRItemPageViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemPageViewController.h"
#import "NSString+HTML.h"
#import "NSFormatter+SecureReader.h"
#import <Foundation/NSDateFormatter.h>
#import "RSSPerson.h"
#import "SCRApplication.h"
#import "SCRSettings.h"

@interface SCRItemPageViewController ()

@end

@implementation SCRItemPageViewController

@synthesize itemIndexPath;

@synthesize mediaCollectionView = _mediaCollectionView;
@synthesize imageViewHeightConstraint = _imageViewHeightConstraint;
@synthesize sourceView = _sourceView;
@synthesize titleView = _titleView;
@synthesize contentView = _contentView;

- (void)viewDidLoad {
    [super viewDidLoad];
    [_contentView setScrollEnabled:NO];
    [self.mediaCollectionView setShowDownloadButtonIfNotLoaded:YES];
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

    [self.mediaCollectionView setItem:self.item];
    [self.mediaCollectionView createThumbnails:[SCRSettings downloadMedia] completion:nil];
    
    self.sourceView.labelSource.text = [item.linkURL host];
    self.sourceView.labelDate.text = [[NSFormatter scr_sharedIntervalFormatter] stringForTimeIntervalFromDate:[NSDate date] toDate:item.publicationDate];

    self.titleView.text =  self.item.title;
    
    self.authorView.labelDate.text = [NSDateFormatter localizedStringFromDate:self.item.publicationDate dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    self.authorView.labelTime.text = [NSDateFormatter localizedStringFromDate:self.item.publicationDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    if (self.item.author != nil && self.item.author.name != nil)
        self.authorView.labelAuthorName.text = [NSString stringWithFormat:NSLocalizedString(@"ItemPage.AuthorName", @"Author name string"), self.item.author.name];
    else if (self.item.author != nil && self.item.author.email != nil)
        self.authorView.labelAuthorName.text = [NSString stringWithFormat:NSLocalizedString(@"ItemPage.AuthorName", @"Author name string"), self.item.author.email];
    else
        self.authorView.labelAuthorName.text = @"";
    self.authorView.labelAuthorName.text = [self.authorView.labelAuthorName.text uppercaseString];
    
    if (self.authorView.labelAuthorName.text.length == 0)
        self.authorView.authorNameHeightConstaint.priority = 1000;
    else
        self.authorView.authorNameHeightConstaint.priority = 1;
    
    self.contentView.text = [self.item.itemDescription stringByConvertingHTMLToPlainText];

    [self.view layoutIfNeeded];
}

@end
