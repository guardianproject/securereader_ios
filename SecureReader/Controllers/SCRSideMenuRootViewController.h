//
//  SCRSideMenuViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-11-10.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "MMDrawerController.h"

@interface SCRSideMenuRootViewController : MMDrawerController
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *menu;

- (IBAction)openDrawerAction:(id)sender;

@end
