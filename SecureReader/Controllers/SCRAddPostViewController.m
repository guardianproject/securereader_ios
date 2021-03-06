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
#import "SCRPostsViewController.h"
#import "SCRTorAlertView.h"

@interface SCRAddPostViewController ()
@property (nonatomic, strong) SCRPostItem *item;
@property BOOL isEditing;
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic) UIPopoverController *imagePickerPopoverController;
@property (nonatomic, weak) SCRMediaItem *imagePickerReplaceThisItem;
@property (nonatomic, strong) MRProgressOverlayView *progressOverlayView;
@property (nonatomic, strong) UISwipeGestureRecognizer *operationButtonSwipeRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *operationButtonSwipeRightRecognizer;
@end

@implementation SCRAddPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mediaCollectionView.showPlaceholders = YES;
    self.operationButtonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(operationButtonsTapped:)];
    self.operationButtonTapRecognizer.delegate = self;
    self.operationButtonTapRecognizer.cancelsTouchesInView = NO;
    [self.operationButtonsContainer addGestureRecognizer:self.operationButtonTapRecognizer];
    self.operationButtonSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(operationButtonsSwiped:)];
    self.operationButtonSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.operationButtonsContainer addGestureRecognizer:self.operationButtonSwipeRecognizer];
    self.operationButtonSwipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(operationButtonsSwipedRight:)];
    self.operationButtonSwipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.operationButtonsContainer addGestureRecognizer:self.operationButtonSwipeRightRecognizer];
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
    self.operationButtonsToolbar.alpha = 0.0f;
    self.operationButtonsContainer.hidden = NO;
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
        int numImages = [self.mediaCollectionView numberOfImages];
        [self.operationButtonsToolbar setAlpha:0];
        [self.operationButtonsContainer setHidden:(numImages == 0)];
        [self.imagePlaceholder setHidden:(numImages > 0)];
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

- (UIViewController *)backViewController
{
    NSInteger numberOfViewControllers = self.navigationController.viewControllers.count;
    
    if (numberOfViewControllers < 2)
        return nil;
    else
        return [self.navigationController.viewControllers objectAtIndex:numberOfViewControllers - 2];
}

- (IBAction)post:(id)sender
{
    if (![SCRSettings useTor]) {
        //Need to make sure new posts are posted through tor
        [SCRTorAlertView showTorAlertView];
        
        return;
    }
    
    [self populateItemFromUI];
    
    SCRWordpressClient *wpClient = [SCRWordpressClient defaultClient];
    [wpClient setUsername:[SCRSettings wordpressUsername] password:[SCRSettings wordpressPassword]];
    
    // upload images
    self.progressOverlayView = [MRProgressOverlayView showOverlayAddedTo:self.view title:NSLocalizedString(@"Uploading Images", @"shown when uploading images to wordpress") mode:MRProgressOverlayViewModeIndeterminate animated:YES];
    
    dispatch_group_t uploadGroup = dispatch_group_create();
    NSMutableArray *mediaURLs = [NSMutableArray array];
    NSMutableArray<SCRMediaItem *> *mediaItems = [NSMutableArray array];
    dispatch_group_enter(uploadGroup);
    __block NSError *uploadError = nil;
    [[SCRDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction * __nonnull transaction) {
        [self.item enumerateMediaItemsInTransaction:transaction block:^(SCRMediaItem *mediaItem, BOOL *stop) {
            dispatch_group_enter(uploadGroup);
            [mediaItems addObject:mediaItem];
            NSURL *url = [mediaItem localURLWithPort:[SCRAppDelegate sharedAppDelegate].mediaServer.port];
            [wpClient uploadFileAtURL:url postId:nil completionBlock:^(NSURL *url, NSString *fileId, NSError *error) {
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
        NSString *linkString = NSLocalizedString(@"Link to Media", @"text shown for media links e.g. <a href=\"blah.jpg\">Link To Media</a>");
        [mediaURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL * __nonnull stop) {
            [newDescription appendFormat:@"\n<a href=\"%@\">%@</a>", url.absoluteString, linkString];
        }];
        
        //append tags to description
        [self.item.tags enumerateObjectsUsingBlock:^(NSString *tag, NSUInteger idx, BOOL * __nonnull stop) {
            [newDescription appendFormat:@"\n#%@", tag];
        }];
        
        [self.progressOverlayView setTitleLabelText:NSLocalizedString(@"Posting Story", @"Progress for posting a new story to wordpress")];
        self.progressOverlayView.mode = MRProgressOverlayViewModeIndeterminate;
        
        SCRMediaItem *enclosure = [mediaItems firstObject];
        IOCipher *iocipher = [SCRAppDelegate sharedAppDelegate].fileManager.ioCipher;
        NSError *error = nil;
        NSDictionary *stats = [iocipher fileAttributesAtPath:enclosure.localPath error:&error];
        if (error) {
            NSLog(@"Error getting file stats: %@", error);
        }
        NSUInteger enclosureLength = stats.fileSize;
        NSURL *enclosureURL = [mediaURLs firstObject];
        
        [wpClient createPostWithTitle:self.item.title content:newDescription enclosureURL:enclosureURL enclosureLength:enclosureLength completionBlock:^(NSString *postId, NSError *error) {
            if (error) {
                self.progressOverlayView.mode = MRProgressOverlayViewModeCross;
            } else {
                self.progressOverlayView.mode = MRProgressOverlayViewModeCheckmark;
                self.item.publicationDate = [NSDate date];
                self.item.isSent = YES;
                [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [self.item saveWithTransaction:transaction];
                } completionBlock:^{
                    // Select the "My Posts" tab when going back
                    //
                    UIViewController *backVC = [self backViewController];
                    if (backVC != nil && [backVC isKindOfClass:[SCRPostsViewController class]])
                    {
                        SCRPostsViewController *pVC = (SCRPostsViewController *)backVC;
                        [pVC.segmentedControl setSelectedSegmentIndex:0];
                        [pVC.segmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
                    }
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
    [self.mediaCollectionView viewCurrentImage];
}

- (IBAction)deleteMediaButtonClicked:(id)sender
{
    SCRMediaItem *itemToRemove = [self.mediaCollectionView currentImageMediaItem];
    if (itemToRemove != nil)
    {
        [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [itemToRemove removeWithTransaction:transaction];
        } completionBlock:^(void){
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
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        
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
                        [newArray insertObject:mediaItem.yapKey atIndex:[newArray indexOfObject:[self.imagePickerReplaceThisItem yapKey]]];
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
            } completionBlock:^(void){
                [self updateMediaCollectionView];
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Make sure to post on same queue as updateMediaColletionView, because that needs to happen first!
                    [[SCRAppDelegate sharedAppDelegate].mediaFetcher saveMediaItem:mediaItem data:jpegData completionBlock:^(NSError *error) {
                        if (error) {
                            NSLog(@"Error saving media item: %@", error);
                        } else {
                            [self.mediaCollectionView createViewForMediaItem:mediaItem];
                        }
                    }];
                });
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
            int numImages = [self.mediaCollectionView numberOfImages];
            [self.operationButtonsToolbar setAlpha:0];
            [self.operationButtonsContainer setHidden:(numImages == 0)];
            [self.imagePlaceholder setHidden:(numImages > 0)];
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

- (void)operationButtonsTapped:(UITapGestureRecognizer *)gesture
{
    [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
        self.operationButtonsToolbar.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hideOperationButtons:) withObject:self afterDelay:5];
    }];
}

- (void)operationButtonsSwiped:(UISwipeGestureRecognizer *)gesture
{
    [self.mediaCollectionView.contentView scrollByNumberOfItems:1 duration:0.5f];
}

- (void)operationButtonsSwipedRight:(UISwipeGestureRecognizer *)gesture
{
    [self.mediaCollectionView.contentView scrollByNumberOfItems:-1 duration:0.5f];
}

- (void) hideOperationButtons:(id)sender
{
    [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
        self.operationButtonsToolbar.alpha = 0.0f;
    } completion:^(BOOL finished) {
    }];
}

@end
