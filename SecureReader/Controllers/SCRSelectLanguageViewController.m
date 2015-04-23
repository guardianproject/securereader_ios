//
//  SRLoginViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-15.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRSelectLanguageViewController.h"
#import "NSBundle+Language.h"
#import "SCRTheme.h"
#import "SCRSettings.h"
#import "SCRApplication.h"
#import "SCRAppDelegate.h"
#import "SCRHelpHintViewController.h"
#import "SCRMoreViewController.h"

@interface SCRSelectLanguageViewController ()
@property NSArray *languages;
@property NSArray *languageCodes;
- (NSString*) getLanguageDisplayName:(NSString*)languageCode;
@end

@implementation SCRSelectLanguageViewController
{
    UITapGestureRecognizer *tap;
}

@synthesize pickerFrame;
@synthesize pickerLanguage;
@synthesize labelCurrentLanguage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.languages = [[NSArray alloc] initWithObjects:NSLocalizedString(@"English", @"Language name for English") , NSLocalizedString(@"Svenska", @"Language name for Swedish"), nil];
    self.languageCodes = [[NSArray alloc] initWithObjects:@"Base", @"sv", nil];
    
    [pickerLanguage setDataSource:self];
    [pickerLanguage setDelegate:self];
    
    [labelCurrentLanguage setText:[self getLanguageDisplayName:[SCRSettings getUiLanguage]]];
    labelCurrentLanguage.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectLanguageButtonClicked:)];
    [labelCurrentLanguage addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    CGRect newFrame = pickerFrame.frame;
    CGRect parentFrame = pickerFrame.superview.frame;
    newFrame.origin.y = parentFrame.size.height;
    pickerFrame.frame = newFrame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getStartedButtonClicked:(id)sender
{
//    [self performSegueWithIdentifier:@"segueToCreatePassphrase" sender:self];
    [self performSegueWithIdentifier:@"segueToHint" sender:self];
    [self removeFromParentViewController];
}

- (IBAction)selectLanguageButtonClicked:(id)sender
{
    [self showLanguagePicker];
}

- (IBAction)saveLanguageButtonClicked:(id)sender
{
    [self hideLanguagePicker:YES];
}

- (void)updateLanguage
{
    long row = [pickerLanguage selectedRowInComponent:0];
    NSString *newLanguage = [self.languageCodes objectAtIndex:row];
    [SCRSettings setUiLanguage:newLanguage];
    [NSBundle setLanguage:newLanguage];
    [SCRTheme reinitialize];
    UIViewController *cont = [self.storyboard instantiateViewControllerWithIdentifier:self.restorationIdentifier];
    [[SCRAppDelegate sharedAppDelegate].window setRootViewController:cont];
}

- (void) showLanguagePicker
{
    CGRect newFrame = pickerFrame.frame;
    CGRect superBounds = pickerFrame.superview.bounds;
    newFrame.origin.y = superBounds.size.height - newFrame.size.height;
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         pickerFrame.frame = newFrame;
                     }
                     completion:^(BOOL finished){
                         NSLog(@"Done!");
                     }];
    
    // Capture taps outside the bounds of this alert view
    if (tap == nil)
    {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOut:)];
        tap.cancelsTouchesInView = NO; // So that legit taps on the table bubble up to the tableview
        [self.view addGestureRecognizer:tap];
    }
}

- (void) hideLanguagePicker:(BOOL)setLanguageOnCompletion
{
    if (tap != nil)
    {
        [self.view removeGestureRecognizer:tap];
        tap = nil;
    }
    
    CGRect newFrame = pickerFrame.frame;
    newFrame.origin.y = pickerFrame.superview.bounds.size.height;
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         pickerFrame.frame = newFrame;
                     }
                     completion:^(BOOL finished){
                         if (setLanguageOnCompletion)
                             [self updateLanguage];
                         NSLog(@"Done!");
                     }];
}

-(void)tapOut:(UIGestureRecognizer *)gestureRecognizer {
	CGPoint p = [gestureRecognizer locationInView:pickerFrame];
	if (p.y < 0)
    {
        // They tapped outside
        [self hideLanguagePicker:NO];
	}
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.languages count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.languages objectAtIndex:row];
}

- (void)addChildViewController:(UIViewController *)childController
{
    [super addChildViewController:childController];
}

- (NSString*) getLanguageDisplayName:(NSString*)languageCode;
{
    NSUInteger idx = [self.languageCodes indexOfObject:languageCode];
    if (idx != NSNotFound)
        return [self.languages objectAtIndex:idx];
    return [self.languages objectAtIndex:0];
}

@end
