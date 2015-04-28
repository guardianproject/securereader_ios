//
//  SCRAllFeedsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-07.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRAllFeedsViewController.h"
#import "SCRTorManager.h"
#import "SCRAppDelegate.h"
#import "SCRNotificationsView.h"

@interface SCRAllFeedsViewController ()

@end

@implementation SCRAllFeedsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setFeedViewType:SCRFeedViewTypeAllFeeds feed:nil];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshPulled:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /** Get current tor status */
    CPAStatus currentStatus = ((SCRAppDelegate *)[UIApplication sharedApplication].delegate).torManager.proxyManager.status;
    [self updateHeaderWithTorStatus:currentStatus];
    
    /** Get Notifications for Tor status changes */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTorNotificatoin:) name:CPAProxyDidStartSetupNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTorNotificatoin:) name:CPAProxyDidFinishSetupNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshPulled:(id)sender
{
    [((SCRAppDelegate *)[UIApplication sharedApplication].delegate).feedFetcher refreshSubscribedFeedsWithCompletionQueue:dispatch_get_main_queue() completion:^{
        [self.refreshControl endRefreshing];
    }];
}

#pragma - mark Tor Methods

- (void)receivedTorNotificatoin:(NSNotification *)notification
{
    if ([notification.name isEqualToString:CPAProxyDidStartSetupNotification]) {
        [self updateHeaderWithTorStatus:CPAStatusConnecting];
    } else if ([notification.name isEqualToString:CPAProxyDidFinishSetupNotification]) {
        [self updateHeaderWithTorStatus:CPAStatusOpen];
    }
}

- (void)updateHeaderWithTorStatus:(CPAStatus)status
{
    if (status == CPAStatusConnecting) {
        SCRNotificationsView *notificationsView = [[SCRNotificationsView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 33)];
        notificationsView.backgroundColor = [UIColor darkGrayColor];
        notificationsView.textLabel.text = NSLocalizedString(@"Tor starting", @"Label for alert for when tor is starting");
        notificationsView.textLabel.textColor = [UIColor whiteColor];
        notificationsView.textLabel.textAlignment = NSTextAlignmentCenter;
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        notificationsView.accessoryView = activityIndicator;
        [activityIndicator startAnimating];
        self.tableView.tableHeaderView = notificationsView;
    } else {
        //Remove header if exists
        self.tableView.tableHeaderView = nil;
    }
}

@end
