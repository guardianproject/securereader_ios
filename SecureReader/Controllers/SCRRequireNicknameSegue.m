//
//  SCRRequireNicknameSegue.m
//  SecureReader
//
//  Created by N-Pex on 2015-06-30.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRRequireNicknameSegue.h"
#import "SCRSettings.h"
#import "SCRCreateNicknameViewController.h"
#import "SCRAllowPostsViewController.h"

@implementation SCRRequireNicknameSegue

- (void) perform {
    
    UIViewController *destination = self.destinationViewController;
    UIViewController *source = self.sourceViewController;

    if ([[SCRSettings userNickname] length] == 0)
    {
        destination = [source.storyboard instantiateViewControllerWithIdentifier:@"createNickname"];
        destination.modalPresentationStyle = UIModalPresentationFullScreen;
        [(SCRCreateNicknameViewController *)destination setOpeningSegue:self]; // Modal will call this after close if nick is set, to continute on to destination
        [source presentViewController:destination animated:YES completion:nil];
    }
    else if (self.alsoRequirePostPermission && ![SCRSettings hasGivenPostPermission])
    {
        destination = [source.storyboard instantiateViewControllerWithIdentifier:@"allowPosts"];
        destination.modalPresentationStyle = UIModalPresentationFullScreen;
        [(SCRAllowPostsViewController *)destination setOpeningSegue:self]; // Modal will call this after close if nick is set, to continute on to destination
        [source presentViewController:destination animated:YES completion:nil];
    }
    else
    {
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        source.navigationItem.backBarButtonItem = backItem;
        [source.navigationController pushViewController:self.destinationViewController animated:YES];
    }
}

@end
