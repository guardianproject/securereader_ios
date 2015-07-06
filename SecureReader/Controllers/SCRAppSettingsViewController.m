//
//  SCRAppSettingsViewController.m
//  SecureReader
//
//  Created by David Chiles on 7/6/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "SCRTorManager.h"

@interface SCRAppSettingsViewController ()

@property (nonatomic, strong) NSString *torSummary;

@end

@implementation SCRAppSettingsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(torBootstrapProgress:)
                                                 name:kSCRTorManagerBootstrapProgressNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSCRTorManagerBootstrapProgressNotification
                                                  object:nil];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    IASKSpecifier *specifier = [self.settingsReader specifierForIndexPath:indexPath];
    if ([specifier.key isEqualToString: @"useTor"]) {
        
        cell.detailTextLabel.text = self.torSummary;
    }
    
    return cell;
}


- (void)torBootstrapProgress:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    self.torSummary = userInfo[kSCRTorManagerBootstrapProgressSummaryKey];
    NSIndexPath *indexPath = [self.settingsReader indexPathForKey:@"useTor"];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
@end
