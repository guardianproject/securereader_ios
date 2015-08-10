//
//  SCRTorAlertView.m
//  SecureReader
//
//  Created by David Chiles on 8/10/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRTorAlertView.h"
#import "UIAlertView+SecureReader.h"
#import "UIAlertView+SecureReader.h"
#import "IASKSettingsReader.h"
#import "SCRTorManager.h"
#import "SCRSettings.h"
#import "SCRAppDelegate.h"

@implementation SCRTorAlertView

+ (instancetype)showTorAlertView
{
    //Need to make sure new comments are posted through tor
    SCRTorAlertView *alertView = [[self alloc] initWithTitle:NSLocalizedString(@"Connect to Tor to post.", @"Title for alertview telling user to connect to Tor in order to post")  message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"Posts.Draft.Delete.Cancel", @"Cancel String") otherButtonTitles:NSLocalizedString(@"Connet Tor", @"Button title to turn Tor on"), nil];
    [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (alertView.cancelButtonIndex != buttonIndex) {
            [SCRSettings setUseTor:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged
                                                                object:kSCRUseTorKey
                                                              userInfo:[NSDictionary dictionaryWithObject:@(YES)
                                                                                                   forKey:kSCRUseTorKey]];
        }
    }];
    
    return alertView;
}

@end
