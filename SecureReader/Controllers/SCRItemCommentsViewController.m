//
//  SCRItemCommentsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-06-18.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRItemCommentsViewController.h"

@interface SCRItemCommentsViewController ()

@end

@implementation SCRItemCommentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) setItem:(SCRItem *)item
{
    _item = item;
    NSParameterAssert(item != nil);
    if (!self.item) {
        return;
    }
    [self view]; // force view to load if it hasn't already
    
    self.label.text = self.item.title;
    
    [self.view layoutIfNeeded];
}

@end
