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
#import "SCRAppDelegate.h"
#import "SCRMediaItem.h"
#import "MRProgress.h"
#import "SCRWordpressClient.h"
#import "SCRSettings.h"
#import "UIView+Theming.h"
#import "SCRTheme.h"

@interface SCRAddPostViewController ()
@property (nonatomic, strong) SCRPostItem *item;
@property BOOL isEditing;
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) UIPopoverController *imagePickerPopoverController;
@property (nonatomic, weak) SCRMediaItem *imagePickerReplaceThisItem;
@property (nonatomic, strong) MRProgressOverlayView *progressOverlayView;
@end

@implementation SCRAddPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mediaCollectionView.showPlaceholders = YES;
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
    [self.imagePlaceholder setHidden:YES];
    [self.operationButtons setHidden:YES];
    [self populateUIfromItem];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self saveDraft];
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self registerForKeyboardNotifications];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self unregisterForKeyboardNotifications];
    [super viewDidDisappear:animated];
}

- (void)editItem:(SCRPostItem *)item
{
    self.item = item;
    self.isEditing = YES;
}

- (void)populateUIfromItem
{
    self.titleView.text = self.item.title;
    self.descriptionView.text = self.item.itemDescription;
    self.tagView.text = [self.item.tags componentsJoinedByString:@" "];
    [self.mediaCollectionView setItem:self.item];
    [self.mediaCollectionView createThumbnails:NO completion:^{
        [self.operationButtons setHidden:([self.mediaCollectionView numberOfImages] == 0)];
        [self.imagePlaceholder setHidden:([self.mediaCollectionView numberOfImages] > 0)];
    }];
}

- (void)populateItemFromUI
{
    self.item.title = self.titleView.text;
    self.item.itemDescription = self.descriptionView.text;

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

- (IBAction)post:(id)sender
{
    [self populateItemFromUI];
    
    SCRWordpressClient *wpClient = [SCRWordpressClient defaultClient];
    [wpClient setUsername:[SCRSettings wordpressUsername] password:[SCRSettings wordpressPassword]];
    
    // upload images
    self.progressOverlayView = [MRProgressOverlayView showOverlayAddedTo:self.view title:NSLocalizedString(@"Uploading Images", @"shown when uploading images to wordpress") mode:MRProgressOverlayViewModeIndeterminate animated:YES];
    
    dispatch_group_t uploadGroup = dispatch_group_create();
    NSMutableArray *mediaURLs = [NSMutableArray array];
    dispatch_group_enter(uploadGroup);
    __block NSError *uploadError = nil;
    [[SCRDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction * __nonnull transaction) {
        [self.item enumerateMediaItemsInTransaction:transaction block:^(SCRMediaItem *mediaItem, BOOL *stop) {
            dispatch_group_enter(uploadGroup);
            NSURL *url = [mediaItem localURLWithPort:[SCRAppDelegate sharedAppDelegate].mediaServer.port];
            [wpClient uploadFileAtURL:url completionBlock:^(NSURL *url, NSString *fileId, NSError *error) {
                dispatch_group_leave(uploadGroup);
                if (url) {
                    [mediaURLs addObject:url];
                } else {
                    uploadError = error;
                    NSLog(@"Error uploading URL %@: %@", url, error);
                }
            }];
        }];
    }];
    dispatch_group_leave(uploadGroup);
    dispatch_group_notify(uploadGroup, dispatch_get_main_queue(), ^{
        if (uploadError) {
            [self.progressOverlayView setMode:MRProgressOverlayViewModeCross];
            [self.progressOverlayView dismiss:YES];
            return;
        } else {
            [self.progressOverlayView setMode:MRProgressOverlayViewModeCheckmark];
        }
        
        // append uploaded images to item description
        NSMutableString *newDescription = [self.item.itemDescription mutableCopy];
        [mediaURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL * __nonnull stop) {
            [newDescription appendFormat:@"\n<a href=\"%@\">%@</a>", url.absoluteString, url.absoluteString];
        }];
        
        //append tags to description
        [self.item.tags enumerateObjectsUsingBlock:^(NSString *tag, NSUInteger idx, BOOL * __nonnull stop) {
            [newDescription appendFormat:@"\n%@", tag];
        }];
        
        [self.progressOverlayView setTitleLabelText:NSLocalizedString(@"Posting Story", @"Progress for posting a new story to wordpress")];
        self.progressOverlayView.mode = MRProgressOverlayViewModeIndeterminate;
        
        [wpClient createPostWithTitle:self.item.title content:newDescription completionBlock:^(NSString *postId, NSError *error) {
            if (error) {
                self.progressOverlayView.mode = MRProgressOverlayViewModeCross;
            } else {
                self.progressOverlayView.mode = MRProgressOverlayViewModeCheckmark;
                self.item.publicationDate = [NSDate date];
                self.item.isSent = YES;
                [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [self.item saveWithTransaction:transaction];
                } completionBlock:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            }
            [self.progressOverlayView dismiss:YES];
        }];
        
        
        
    });
}

- (void)saveDraft
{
    if (self.item != nil && self.item.isSent == NO && (self.isEditing || self.titleView.text.length > 0 || self.descriptionView.text.length > 0 || self.tagView.text.length > 0 || [self.mediaCollectionView numberOfImages] > 0))
    {
        [self populateItemFromUI];
        [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [self.item saveWithTransaction:transaction];
        }];
    }
}

- (IBAction)addMediaButtonClicked:(id)sender
{
    self.imagePickerReplaceThisItem = nil;
    [self getImageFromGalleryOrCamera:sender];
}

- (IBAction)replaceMediaButtonClicked:(id)sender
{
    self.imagePickerReplaceThisItem = [self.mediaCollectionView currentImageMediaItem];
    if (self.imagePickerReplaceThisItem != nil)
    {
        [self getImageFromGalleryOrCamera:sender];
    }
}

- (IBAction)viewMediaButtonClicked:(id)sender
{
    
}

- (IBAction)deleteMediaButtonClicked:(id)sender
{
    SCRMediaItem *itemToRemove = [self.mediaCollectionView currentImageMediaItem];
    if (itemToRemove != nil)
    {
        [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            if (self.item.mediaItemsYapKeys.count > 0)
            {
                NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:self.item.mediaItemsYapKeys];
                [newArray removeObject:[itemToRemove yapKey]];
                self.item.mediaItemsYapKeys = newArray;
                [self.item saveWithTransaction:transaction];
            }
            [itemToRemove removeWithTransaction:transaction];
            [self updateMediaCollectionView];
        }];
    }
}

- (void) getImageFromGalleryOrCamera:(id)sender
{
    BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    BOOL hasSavedPics = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    if(hasCamera && hasSavedPics)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"AddPost.PickImage.PickSource.Title", @"Post screen: Alert title, get image from gallery")
                                                                       message:NSLocalizedString(@"AddPost.PickImage.PickSource.Message", @"Post screen: Alert message, get image from gallery")
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction* libraryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"AddPost.PickImage.PickSource.Option.Photos", @"Post screen: pick image from photos") style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self getImageFromGallery:sender];
                                                              }];
        
        [alert addAction:libraryAction];
        UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"AddPost.PickImage.PickSource.Option.Camera", @"Post screen: pick image from camera") style:UIAlertActionStyleDefault
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"AddPost.PickImage.NoSource.Title", "Title for AddPost -> pick image when no sources are available") message:NSLocalizedString(@"AddPost.PickImage.NoSource.Message", @"Message for AddPost -> pick image when no sources are available") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        [alert show];
        alert = nil;
    }
}

- (IBAction)getImageFromGallery:(id)sender
{
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    // Styled navigation bar
    [self.imagePickerController.navigationBar setTheme:@"NavigationBarItemStyle"];
    UIColor *color = [SCRTheme getColorProperty:@"textColor" forTheme:@"NavigationBarItemStyle"];
    if (color != nil)
    {
        [self.imagePickerController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName]];
    }
    
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
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (image == nil)
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image != nil)
    {
        // TODO resize image
        NSData *jpegData = UIImageJPEGRepresentation(image, 0.75);
        if (jpegData != nil)
        {
            NSString *path = [NSString stringWithFormat:@"post/%@.jpg", [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""]];
            NSURL *url = [NSURL fileURLWithPath:path];
            SCRMediaItem *mediaItem = [[SCRMediaItem alloc] initWithURL:url];
            [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [mediaItem saveWithTransaction:transaction];
                if (self.item.mediaItemsYapKeys.count > 0)
                {
                    if (self.imagePickerReplaceThisItem != nil)
                    {
                        NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:self.item.mediaItemsYapKeys];
                        [newArray replaceObjectAtIndex:[newArray indexOfObject:[self.imagePickerReplaceThisItem yapKey]] withObject:mediaItem.yapKey];
                        self.item.mediaItemsYapKeys = newArray;
                        [self.imagePickerReplaceThisItem removeWithTransaction:transaction];
                        self.imagePickerReplaceThisItem = nil;
                    }
                    else
                    {
                        self.item.mediaItemsYapKeys = [self.item.mediaItemsYapKeys arrayByAddingObject:mediaItem.yapKey];
                    }
                }
                else
                    self.item.mediaItemsYapKeys = [NSArray arrayWithObject:mediaItem.yapKey];
                [self populateItemFromUI];
                [self.item saveWithTransaction:transaction];
                [self updateMediaCollectionView];
                [[SCRAppDelegate sharedAppDelegate].mediaFetcher saveMediaItem:mediaItem data:jpegData completionBlock:^(NSError *error) {
                    if (error) {
                        NSLog(@"Error saving media item: %@", error);
                    } else {
                        [self.mediaCollectionView createViewForMediaItem:mediaItem];
                    }
                }];
            }];
        }
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.imagePickerController = nil;
    self.imagePickerPopoverController = nil;
}

- (void) updateMediaCollectionView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mediaCollectionView setItem:nil];
        [self.mediaCollectionView setItem:self.item];
        [self.mediaCollectionView createThumbnails:NO completion:^{
            [self.operationButtons setHidden:([self.mediaCollectionView numberOfImages] == 0)];
            [self.imagePlaceholder setHidden:([self.mediaCollectionView numberOfImages] > 0)];
        }];
    });
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.bottomConstraint.constant = kbSize.height;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    self.bottomConstraint.constant = 0;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches] anyObject];
    if (![[touch view] isKindOfClass:[UITextView class]]) {
        [self.view endEditing:YES];
    }
    [super touchesBegan:touches withEvent:event];
}

@end
