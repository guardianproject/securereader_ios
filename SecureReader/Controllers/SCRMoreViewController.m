//
//  SCRMoreViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-16.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRMoreViewController.h"
#import "SCRFeedViewController.h"
#import "SCRReceiveShareView.h"
#import "SCRNavigationController.h"
#import "UIView+Theming.h"

@interface SCRMoreViewController ()

@end

@implementation SCRMoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"segueToReceived"])
    {
        SCRFeedViewController *feedViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"feedViewController"];
        [feedViewController setFeedViewType:SCRFeedViewTypeReceived feed:nil];

        // Set the header
        SCRReceiveShareView *header = [[SCRReceiveShareView alloc] initWithFrame:CGRectMake(0, 0, 100, 60)];
        feedViewController.tableView.tableHeaderView = header;
        
        [self.navigationController pushViewController:feedViewController animated:YES];
        return NO;
    }
    return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UITableViewHeaderFooterView *header = [[UITableViewHeaderFooterView alloc] init];
    header.textLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    dispatch_async(dispatch_get_main_queue(), ^{
        [header.textLabel setTheme:@"MoreSectionStyle"];
    });
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([[self tableView:tableView titleForHeaderInSection:section] length] == 0)
        return 0;
    return 50;
}

@end
