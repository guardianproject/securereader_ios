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
#import "SCRTheme.h"
#import "SCRApplication.h"
#import <KVOController/FBKVOController.h>
#import "MRCircularProgressView.h"
#import "MRActivityIndicatorView.h"

static void * kSCRAllFeedsViewControllerContext = &kSCRAllFeedsViewControllerContext;

@interface SCRAllFeedsViewController ()

@property (nonatomic, weak) SCRFeedFetcher *feedFetcher;

@property (nonatomic, strong) SCRNotificationsView *notificationsView;

@end

@implementation SCRAllFeedsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setFeedViewType:SCRFeedViewTypeAllFeeds feed:nil];
    self.feedFetcher = ((SCRAppDelegate *)[UIApplication sharedApplication].delegate).feedFetcher;
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedTorNotificatoin:)
                                                 name:CPAProxyDidStartSetupNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedTorNotificatoin:)
                                                 name:CPAProxyDidFinishSetupNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTorNotificatoin:)
                                                 name:kSCRTorManagerBootstrapProgressNotification
                                               object:nil];
    
    if (self.feedFetcher.isRefreshing) {
        [self.refreshControl beginRefreshing];
    } else {
        [self.refreshControl endRefreshing];
    }
    
    /** KVO */
    
    [self.KVOController observe:self.feedFetcher keyPath:NSStringFromSelector(@selector(isRefreshing)) options:NSKeyValueObservingOptionNew action:@selector(isRefreshingChanged:)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[SCRAppDelegate sharedAppDelegate].torManager currentBootstrapProgress:^(NSInteger progress, NSString *summary) {
        [self updateHeaderWithTorProgress:progress];
    } queue:dispatch_get_main_queue()];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshPulled:(id)sender
{
    BOOL didStartRefreshing = [self.feedFetcher refreshSubscribedFeedsWithCompletionQueue:dispatch_get_main_queue() completion:^{
        [self.refreshControl endRefreshing];
    }];
    
    if (!didStartRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

#pragma - mark KVO

- (void)isRefreshingChanged:(id)sender {
    BOOL isRefreshing = self.feedFetcher.isRefreshing;
    
    // Possibly redundant if the pull to refresh starts the refresh
    // but if refresh is started from somewhere else (after launch) then the refresh control will reflect current refresh status
    if (isRefreshing) {
        [self.refreshControl beginRefreshing];
    } else {
        [self.refreshControl endRefreshing];
    }
    
}

#pragma - mark Tor Methods

- (void)receivedTorNotificatoin:(NSNotification *)notification
{
    if ([notification.name isEqualToString:CPAProxyDidStartSetupNotification]) {
        [self updateHeaderWithTorStatus:CPAStatusConnecting];
    } else if ([notification.name isEqualToString:CPAProxyDidFinishSetupNotification]) {
        [self updateHeaderWithTorStatus:CPAStatusOpen];
    } else if ([notification.name isEqualToString:kSCRTorManagerBootstrapProgressNotification]) {
        NSInteger progress = [notification.userInfo[kSCRTorManagerBootstrapProgressKey] integerValue];
        [self updateHeaderWithTorProgress:progress];
    }
}

- (void)updateHeaderWithTorStatus:(CPAStatus)status
{
    if (status == CPAStatusConnecting) {
        self.notificationsView = [[SCRNotificationsView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 33)];
        self.notificationsView.backgroundColor = [SCRTheme torColor];
        self.notificationsView.textLabel.text = NSLocalizedString(@"Tor starting", @"Label for alert for when tor is starting");
        self.notificationsView.textLabel.textColor = [UIColor lightGrayColor];
        self.notificationsView.textLabel.textAlignment = NSTextAlignmentCenter;
        MRActivityIndicatorView *activityIndicator = [[MRActivityIndicatorView alloc] init];
        activityIndicator.tintColor = [UIColor lightGrayColor];
        activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        self.notificationsView.accessoryView = activityIndicator;
        [activityIndicator startAnimating];
        self.tableView.tableHeaderView = self.notificationsView;
    } else {
        //Remove header if exists
        self.tableView.tableHeaderView = nil;
        self.notificationsView = nil;
    }
}

- (void)updateHeaderWithTorProgress:(NSInteger)progress {
    MRCircularProgressView *circularProgressView = nil;
    if ([self.notificationsView.accessoryView isKindOfClass:[MRCircularProgressView class]]) {
        circularProgressView = (MRCircularProgressView *)self.notificationsView.accessoryView;
    } else {
        circularProgressView = [[MRCircularProgressView alloc] init];
        circularProgressView.translatesAutoresizingMaskIntoConstraints = NO;
        circularProgressView.tintColor = [UIColor lightGrayColor];
    }
    
    [circularProgressView setProgress:progress/100.0 animated:YES];
    //Weird hack to remove label
    [circularProgressView.valueLabel removeFromSuperview];
    
    self.notificationsView.accessoryView = circularProgressView;
}

@end
