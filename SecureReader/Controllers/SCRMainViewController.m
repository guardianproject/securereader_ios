//
//  SCRRootViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-05.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRMainViewController.h"
#import "SCRFeedViewController.h"

@interface SCRMainViewController ()

@end

@implementation SCRMainViewController

@synthesize tabBar = _tabBar;
@synthesize container = _container;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tabBar setSelectedItem:[self.tabBar.items objectAtIndex:0]];
    [self performSegueWithIdentifier:@"segueToNews" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSInteger i = [[self.tabBar items] indexOfObject:item];
    switch (i) {
        case 0:
            [self performSegueWithIdentifier:@"segueToNews" sender:self];
            break;
        case 1:
            [self performSegueWithIdentifier:@"segueToFeeds" sender:self];
            break;
        case 2:
            [self performSegueWithIdentifier:@"segueToFavorites" sender:self];
            break;
        case 3:
            [self performSegueWithIdentifier:@"segueToChat" sender:self];
            break;
        case 4:
            [self performSegueWithIdentifier:@"segueToMore" sender:self];
            break;
        default:
            break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"segueToFavorites"])
    {
        SCRFeedViewController *feedController = segue.destinationViewController;
        if (feedController != nil)
        {
            [feedController setFeedViewType:SCRFeedViewTypeFavorites feed:nil];
        }
    }
}

@end
