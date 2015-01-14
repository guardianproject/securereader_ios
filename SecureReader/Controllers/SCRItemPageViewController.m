//
//  SCRItemPageViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemPageViewController.h"

@interface SCRItemPageViewController ()

@end

@implementation SCRItemPageViewController

@synthesize itemIndexPath;

@synthesize titleView;
@synthesize contentView = _contentView;
@synthesize scrollView = _scrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
    [_contentView setScrollEnabled:NO];
    
    if (self.item != nil)
    {
        self.titleView.text =  self.item.title;
        self.contentView.text = self.item.itemDescription;
        
//        NSURL *contentURL = [[NSBundle mainBundle] URLForResource:@"content" withExtension:@"txt"];
//        NSTextStorage *textStorage = [[NSTextStorage alloc] initWithFileURL:contentURL
//                                                                    options:nil
//                                                         documentAttributes:NULL
//                                                                      error:NULL];
//        [self.contentView setText:[textStorage string]];
        
        [self.view layoutIfNeeded];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setItem:(SCRItem *)item
{
    _item = item;
    NSLog(@"String is %f", self.view.bounds.size.width);
}

@end
