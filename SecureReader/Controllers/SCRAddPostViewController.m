//
//  SCRAddPostViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-03-31.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRAddPostViewController.h"
#import "SCRDatabaseManager.h"
#import "SCRApplication.h"

@interface SCRAddPostViewController ()
@property (nonatomic, strong) SCRPostItem *item;
@property BOOL isEditing;
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) UIPopoverController *imagePickerPopoverController;
@end

@implementation SCRAddPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self showPostBarButton:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.item == nil)
    {
        self.item = [[SCRPostItem alloc] init];
        self.item.uuid = [[NSUUID UUID] UUIDString];
        self.isEditing = NO;
    }
    [self populateUIfromItem];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveDraft];
}

- (void) showPostBarButton:(BOOL) show
{
    if (show)
    {
        UIBarButtonItem *btnPost = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(post:)];
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObjects:self.navigationItem.rightBarButtonItem, btnPost, nil]];
    }
    else
    {
        [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObject:self.navigationItem.rightBarButtonItem]];
    }
}

- (void)editItem:(SCRPostItem *)item
{
    self.item = item;
    self.isEditing = YES;
}

- (void)populateUIfromItem
{
    self.titleView.text = self.item.title;
    self.descriptionView.text = self.item.content;
    self.tagView.text = [self.item.tags componentsJoinedByString:@" "];
}

- (void)populateItemFromUI
{
    self.item.title = self.titleView.text;
    self.item.content = self.descriptionView.text;

    // Get the tags and trim away all extra
    //
    NSMutableArray *tags = nil;
    NSArray *rawtags = [self.tagView.text componentsSeparatedByString:@"#"];
    if (rawtags != nil && rawtags.count > 0)
    {
        for (NSString *tag in rawtags)
        {
            NSString *trimmed = [tag stringByTrimmingCharactersInSet:
                                                           [NSCharacterSet whitespaceCharacterSet]];
            if (trimmed.length > 0)
            {
                if (tags == nil)
                    tags = [NSMutableArray array];
                [tags addObject:trimmed];
            }
        }
    }
    self.item.tags = tags;
    self.item.lastEdited = [NSDate dateWithTimeIntervalSinceNow:0];
}

- (void)post:(id)sender
{
    [self populateItemFromUI];
    
    //TODO check valid for post
    self.item.isSent = YES;
    [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self.item saveWithTransaction:transaction];
    }];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveDraft
{
    if (self.item != nil && self.item.isSent == NO && (self.isEditing || self.titleView.text.length > 0 || self.descriptionView.text.length > 0 || self.tagView.text.length > 0))
    {
        [self populateItemFromUI];
        [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [self.item saveWithTransaction:transaction];
        }];
    }
}

- (IBAction)addMediaButtonClicked:(id)sender
{
    BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    BOOL hasSavedPics = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    if(hasCamera && hasSavedPics)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:getLocalizedString(@"Add_Post_Pick_Image_Title", @"Pick Image")
                                                                       message:getLocalizedString(@"Add_Post_Pick_Image_SubTitle", @"Select source")
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* libraryAction = [UIAlertAction actionWithTitle:getLocalizedString(@"Add_Post_Pick_Image_Library", @"Photos") style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self getImageFromGallery:sender];
                                                              }];
        
        [alert addAction:libraryAction];
        UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:getLocalizedString(@"Add_Post_Pick_Image_Camera", @"Camera") style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 [self getImageFromCamera:sender];
                                                             }];
        
        [alert addAction:cameraAction];
        
        if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
            [self presentViewController:alert animated:YES completion:nil];
        else
        {
            UIPopoverController *popover=[[UIPopoverController alloc]initWithContentViewController:alert];
            [popover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
    else if (hasSavedPics)
    {
        [self getImageFromGallery:sender];
    }
    else if (hasCamera)
    {
        [self getImageFromCamera:sender];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"No Image Source Available." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        alert = nil;
    }
}

- (IBAction)getImageFromGallery:(id)sender
{
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    else
    {
        self.imagePickerPopoverController = [[UIPopoverController alloc]initWithContentViewController:self.imagePickerController];
        [self.imagePickerPopoverController presentPopoverFromRect:[sender frame] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (IBAction)getImageFromCamera:(id)sender
{
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - ImagePickerController Delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone || self.imagePickerPopoverController == nil)
    {
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
    }
    self.imagePickerController = nil;
    self.imagePickerPopoverController = nil;
    //ivPickedImage.image = [info objectForKey:UIImagePickerControllerOriginalImage];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerController = nil;
    self.imagePickerPopoverController = nil;
}

@end
