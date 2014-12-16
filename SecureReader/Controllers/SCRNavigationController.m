//
//  SRNavigationController.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRNavigationController.h"
#import "SCRAppDelegate.h"
#import "SCRSelectLanguageViewController.h"
#import "SCRCreatePassphraseViewController.h"
#import "SCRLoginViewController.h"
#import "SCRItemViewController.h"
#import "SCRFeedViewController.h"

#define kAnimationDurationFadeIn 0.2
#define kAnimationDurationExpand 0.5
#define kAnimationDurationCollapse 0.5
#define kAnimationDurationFadeOut 0.2

@interface SCRNavigationController ()

@end

@implementation SCRNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self performSegueWithIdentifier:@"segueToMain" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController class] != [SCRSelectLanguageViewController class] &&
        [viewController class] != [SCRCreatePassphraseViewController class] &&
        [viewController class] != [SCRLoginViewController class])
    {
        if (![[SCRAppDelegate sharedAppDelegate] isLoggedIn])
        {
            SCRLoginViewController *vcLogin = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
            vcLogin.modalPresentationStyle = UIModalPresentationFullScreen;
            [vcLogin setDestinationViewController:viewController navigationController:self animated:animated];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:vcLogin animated:YES completion:nil];
            });
            return;
        }
    }
//    if([viewController class] == [SCRItemViewController class] && [[self.viewControllers lastObject] class] == [SCRFeedViewController class])
//    {
//        SCRFeedViewController *vcMain = (SCRFeedViewController*)[self.viewControllers lastObject];
//        
//        UIView *tempView = [[UIView alloc] initWithFrame:vcMain.selectedItemRect];
//        [tempView setClipsToBounds:YES];
//        [tempView setTranslatesAutoresizingMaskIntoConstraints:NO];
//        [tempView setAutoresizingMask:UIViewAutoresizingNone];
//        [viewController.view setAutoresizingMask:UIViewAutoresizingNone];
//        [tempView addSubview:viewController.view];
//        int navBarHeight = [vcMain.topLayoutGuide length];
//        int screenHeight = self.view.bounds.size.height - navBarHeight;
//        viewController.view.frame = CGRectMake(0, 0, vcMain.view.bounds.size.width, screenHeight);
//        tempView.frame = CGRectMake(vcMain.selectedItemRect.origin.x, vcMain.selectedItemRect.origin.y/* + navBarHeight*/, vcMain.selectedItemRect.size.width, vcMain.selectedItemRect.size.height);
//        [viewController.view setAlpha:0.0];
//        [self.view addSubview:tempView];
//        
//        void (^animations)(void) = ^{
//            [viewController.view setAlpha:1.0];
//        };
//        
//        void (^completion)(BOOL finished) = ^(BOOL finished){
//            
//            // After fade in, move
//            [UIView animateWithDuration:kAnimationDurationExpand
//                             animations:^{
//                                 tempView.frame = CGRectMake(0, navBarHeight, self.view.bounds.size.width, screenHeight);
//                             }
//                             completion:^(BOOL finished){
//                                 [viewController.view removeFromSuperview];
//                                 [tempView removeFromSuperview];
//                                 [viewController.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
//                                 [super pushViewController:viewController animated:NO];
//                             }];
//        };
//        [UIView animateWithDuration:kAnimationDurationFadeIn
//                         animations:animations
//                         completion:completion];
//    }
//    else
    {
        [super pushViewController:viewController animated:animated];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
//    if(self.viewControllers.count > 1 &&
//       [[self.viewControllers lastObject] class] == [SCRItemViewController class] &&
//       [[self.viewControllers objectAtIndex:(self.viewControllers.count - 2)] class] == [SCRFeedViewController class]
//    )
//    {
//        SCRItemViewController *viewController = [self.viewControllers lastObject];
//        SCRFeedViewController *vcMain = [self.viewControllers objectAtIndex:(self.viewControllers.count - 2)];
//        
//        [super popViewControllerAnimated:NO];
//        
//        UIView *tempView = [[UIView alloc] initWithFrame:vcMain.selectedItemRect];
//        [tempView setClipsToBounds:YES];
//        [tempView setTranslatesAutoresizingMaskIntoConstraints:NO];
//        [tempView setAutoresizingMask:UIViewAutoresizingNone];
//        [viewController.view setAutoresizingMask:UIViewAutoresizingNone];
//        [tempView addSubview:viewController.view];
//        int navBarHeight = [vcMain.topLayoutGuide length];
//        int screenHeight = self.view.bounds.size.height - navBarHeight;
//        viewController.view.frame = CGRectMake(0, 0, vcMain.view.bounds.size.width, screenHeight);
//        tempView.frame = CGRectMake(0, navBarHeight, self.view.bounds.size.width, screenHeight);
//        [self.view addSubview:tempView];
//        
//        void (^animations)(void) = ^{
//            tempView.frame = CGRectMake(vcMain.selectedItemRect.origin.x, vcMain.selectedItemRect.origin.y/* + navBarHeight*/, vcMain.selectedItemRect.size.width, vcMain.selectedItemRect.size.height);
//        };
//        
//        void (^completion)(BOOL finished) = ^(BOOL finished){
//            
//            // After move, fade out
//            [UIView animateWithDuration:kAnimationDurationFadeOut
//                             animations:^{
//                                 [viewController.view setAlpha:0.0];
//                             }
//                             completion:^(BOOL finished){
//                                 [viewController.view removeFromSuperview];
//                                 [tempView removeFromSuperview];
//                                 [viewController.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
//                             }];
//        };
//        [UIView animateWithDuration:kAnimationDurationCollapse
//                         animations:animations
//                         completion:completion];
//        return viewController;
//    } else
    {
        return [super popViewControllerAnimated:animated];
    }
}

- (IBAction)showPanicAction:(id)sender
{
    UIViewController *vcLogin = [self.storyboard instantiateViewControllerWithIdentifier:@"panic"];
    vcLogin.modalPresentationStyle = UIModalPresentationFullScreen;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:vcLogin animated:YES completion:nil];
    });
}

@end
