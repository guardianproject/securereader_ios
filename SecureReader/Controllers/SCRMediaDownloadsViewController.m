//
//  SCRMediaDownloadsControllerTableViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-27.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaDownloadsViewController.h"
#import "SCRAppDelegate.h"

@interface SCRMediaDownloadsViewController ()

@end

@implementation SCRMediaDownloadsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = [[SCRAppDelegate sharedAppDelegate] mediaDownloadsTableDelegate];
    self.tableView.dataSource = [[SCRAppDelegate sharedAppDelegate] mediaDownloadsTableDelegate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[SCRAppDelegate sharedAppDelegate] mediaDownloadsTableDelegate].tableView = self.tableView;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[SCRAppDelegate sharedAppDelegate] mediaDownloadsTableDelegate].tableView = nil;
    [super viewWillDisappear:animated];
}

@end
