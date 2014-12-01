//
//  SCRSideMenuViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-10.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRSideMenuViewController.h"
#import "SCRAppDelegate.h"

@interface SCRSideMenuViewController ()

@end

@implementation SCRSideMenuViewController

//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//    UIViewController *vcMain = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"mainMenu"];
//    UIViewController *vcMenu = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"mainMenu"];
//    return [super initWithCenterViewController:vcMain leftDrawerViewController:vcMenu];
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewController *vcMain = [self.storyboard instantiateViewControllerWithIdentifier:@"navigation"];
    UIViewController *vcMenu = [self.storyboard instantiateViewControllerWithIdentifier:@"mainMenu"];
    [self setLeftDrawerViewController:vcMenu];
    [self setCenterViewController:vcMain];
    [self setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeBezelPanningCenterView];
    [self setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeBezelPanningCenterView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    if (self.navigationController != nil)
//    {
//        [self.navigationController setNavigationBarHidden:NO];
//    }
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
@dynamic main;
@dynamic menu;

//- (void)setMain:(NSString *)mainController
//{
////    self.mainViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"mainContent"]; //[self.storyboard instantiateViewControllerWithIdentifier:mainController];
//    [self setMainViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"mainContent"]];
//    
//}
//
//- (void)setMenu:(NSString *)menuController
//{
//    self.menuViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"mainMenu"]; //[self.storyboard instantiateViewControllerWithIdentifier:menuController];
//}

//- (id)initWithCoder:(NSCoder *)aDecoder
//{
//    //UIViewController *vcMain = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"mainContent"];
//    //UIViewController *vcMenu = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"mainMenu"];
//    self = [super initWithMenuViewController:vcMenu mainViewController:vcMain];
//    if (self != nil)
//    {
//    }
//    return self;
//}


@end
