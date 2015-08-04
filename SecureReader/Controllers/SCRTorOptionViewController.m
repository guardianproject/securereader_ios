//
//  SCRTorOptionViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-05-12.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRTorOptionViewController.h"
#import "SCRTorManager.h"
#import "SCRAppDelegate.h"
#import "SCRSettings.h"
#import "SCRAppSettingsViewController.h"
#import "IAskSettingsReader.h"

@interface SCRTorOptionViewController ()
@property BOOL isConnecting;
@end

@implementation SCRTorOptionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.progressTor setHidden:YES];
    [self.cancelTorButton setHidden:YES];
}

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

//- (void)startTor:(BOOL)animated
//{
//    __weak typeof(self)weakSelf = self;
//    [[SCRAppDelegate sharedAppDelegate].torManager currentBootstrapProgress:^(NSInteger progress, NSString *summary) {
//        __strong typeof(weakSelf)strongSelf = weakSelf;
//        [strongSelf updateTorSetting:progress summary:summary];
//    } queue:dispatch_get_main_queue()];
//}

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
        // Connected, lets move on
        [self.progressTor setProgress:1.0 animated:YES];
        if (self.isConnecting)
            [self performSegueWithIdentifier:@"segueToPickFeeds" sender:self];
    } else {
        [self.progressTor setProgress:((float)progress / 100.0) animated:YES];
    }
}

- (void)notNow:(id)sender
{
    [SCRSettings setUseTor:NO];
    [self performSegueWithIdentifier:@"segueToPickFeeds" sender:self];
}

- (IBAction)connectTor:(id)sender {
    self.isConnecting = YES;
    [self.notNowButton setEnabled:NO];
    [self.connectTorButton setEnabled:NO];
    [self.artworkView setHidden:YES];
    [self.progressTor setProgress:0.0];
    [self.progressTor setHidden:NO];
    [self.cancelTorButton setHidden:NO];
    [self setUseTor:YES];
}

- (IBAction)cancelTor:(id)sender {
    self.isConnecting = NO;
    [self.notNowButton setEnabled:YES];
    [self.connectTorButton setEnabled:YES];
    [self.progressTor setHidden:YES];
    [self.cancelTorButton setHidden:YES];
    [self setUseTor:NO];
    [self.artworkView setHidden:NO];
}

- (void)setUseTor:(BOOL)useTor
{
    [SCRSettings setUseTor:useTor];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged
                                                        object:kSCRUseTorKey
                                                      userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:useTor]
                                                                                           forKey:kSCRUseTorKey]];

}

@end
