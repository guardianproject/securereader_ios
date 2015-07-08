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
#import "SCRAppDelegate.h"

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    __weak typeof(self)weakSelf = self;
    [[SCRAppDelegate sharedAppDelegate].torManager currentBootstrapProgress:^(NSInteger progress, NSString *summary) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf updateTorSetting:progress summary:summary];
    } queue:dispatch_get_main_queue()];
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
    
    NSInteger progress = [((NSNumber *)userInfo[kSCRTorManagerBootstrapProgressKey]) integerValue];
    NSString *summary = userInfo[kSCRTorManagerBootstrapProgressSummaryKey];
    [self updateTorSetting:progress summary:summary];
}

- (void)updateTorSetting:(NSInteger)progress summary:(NSString *)summary
{
    if (progress == 100) {
        BOOL torEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"useTor"];
        if (torEnabled) {
            self.torSummary = NSLocalizedString(@"Tor is running and enabled.", @"Shown when Tor is connected and enabled.");
        } else {
            self.torSummary = NSLocalizedString(@"Tor is running but disabled. Force quit to stop.", @"Shown when Tor is still connected but disabled in settings.");
        }
    } else {
        self.torSummary = summary;
    }
    NSIndexPath *indexPath = [self.settingsReader indexPathForKey:@"useTor"];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}
@end
