//
//  SCRMediaCollectionView.m
//  SecureReader
//
//  Created by N-Pex on 2015-03-20.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaCollectionView.h"
#import "SCRDatabaseManager.h"
#import "SCRAppDelegate.h"
#import "SCRMediaItem.h"
#import "SCRMediaCollectionViewDownloadView.h"
#import "JTSImageViewController.h"
#import "SCRMediaServer+Video.h"
@import MediaPlayer;

@interface SCRMediaCollectionViewItem : NSObject

@property (nonatomic, weak) SCRMediaItem *mediaItem;
@property (nonatomic, strong) UIView *view;
@property (nonatomic) BOOL downloading;
@property (nonatomic) BOOL downloaded;

@end

@implementation SCRMediaCollectionViewItem
@end

@interface SCRMediaCollectionView ()
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) NSObject *item;
@property (nonatomic, strong) NSMutableArray *mediaItems;
@property (nonatomic, strong) dispatch_queue_t imageQueue;
@end

@implementation SCRMediaCollectionView

@synthesize contentView;
@synthesize pageControl;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Default values
        self.downloadViewHeight = 110;
        self.imageViewHeight = 200;
        self.noImagesViewHeight = 0;
        
        self.mediaItems = [NSMutableArray array];
        
        [[NSBundle mainBundle] loadNibNamed:@"SCRMediaCollectionView" owner:self options:nil];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.contentView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        _heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:80];
        [self addConstraint:_heightConstraint];
        
        [(SwipeView*)contentView setBounces:NO];
    }
    return self;
}

- (void)dealloc
{
    if (self.imageQueue != nil)
    {
        self.imageQueue = nil;
    }
}

- (void) setItem:(NSObject *)item
{
    if (_item != item)
    {
        _item = item;
        @synchronized(self.mediaItems)
        {
            [self.mediaItems removeAllObjects];
            [[SCRDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                if ([_item respondsToSelector:@selector(enumerateMediaItemsInTransaction:block:)])
                {
                    [_item performSelector:@selector(enumerateMediaItemsInTransaction:block:) withObject:transaction withObject:^(SCRMediaItem *mediaItem, BOOL *stop) {
                        SCRMediaCollectionViewItem *item = [SCRMediaCollectionViewItem new];
                        item.mediaItem = mediaItem;
                        item.view = nil;
                        item.downloading = NO;
                        item.downloaded = [[SCRAppDelegate sharedAppDelegate].fileManager hasDataForPath:mediaItem.localPath];
                        [self.mediaItems addObject:item];
                    }];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(SwipeView *)self.contentView reloadData];
                });
            }];
        }
    }
    [self updateHeight];
}

- (void)updateHeight
{
    NSInteger firstDownloaded = [self.mediaItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ((SCRMediaCollectionViewItem *)obj).downloaded;
    }];
    
    if (firstDownloaded != NSNotFound)
    {
        self.heightConstraint.constant = [self imageViewHeight];
    }
    else if (self.showDownloadButtonIfNotLoaded && self.mediaItems.count > 0)
    {
        self.heightConstraint.constant = [self downloadViewHeight];
    }
    else
    {
        self.heightConstraint.constant = [self noImagesViewHeight];
    }
}

- (void) createThumbnails:(BOOL)downloadIfNeeded completion:(void(^)())completion;
{
    if (_item != nil)
    {
        if (self.imageQueue == nil)
            self.imageQueue = dispatch_queue_create("ImageQueue",NULL);
        dispatch_async(self.imageQueue, ^{
            
            @synchronized(self.mediaItems)
            {
                for (SCRMediaCollectionViewItem *mediaItem in self.mediaItems)
                {
                    if (mediaItem.downloading)
                        continue;
                    if (mediaItem.downloaded && mediaItem.view != nil)
                        continue;
                    
                    if (mediaItem.view == nil)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            CGRect frame = CGRectMake(0, 0, self.contentView.bounds.size.width, [self imageViewHeight]);
                            SCRMediaCollectionViewDownloadView *view = [[SCRMediaCollectionViewDownloadView alloc] initWithFrame:frame];
                            view.delegate = self;
                            mediaItem.view = view;
                            if ([[SCRAppDelegate sharedAppDelegate].fileManager hasDataForPath:mediaItem.mediaItem.localPath])
                            {
                                [view.activityView setHidden:NO];
                                [view.activityView startAnimating];
                                [view.downloadButton setHidden:YES];
                                dispatch_async(self.imageQueue, ^{
                                    [self mediaItemCreate:mediaItem];
                                });
                            }
                            else if (downloadIfNeeded)
                            {
                                [view.activityView setHidden:NO];
                                [view.activityView startAnimating];
                                [view.downloadButton setHidden:YES];
                                [self mediaItemDownload:mediaItem];
                            }
                            else if (self.showPlaceholders)
                            {
                                [view.activityView setHidden:NO];
                                [view.activityView startAnimating];
                                [view.downloadButton setHidden:YES];
                            }
                            else
                            {
                                [view.activityView setHidden:YES];
                                [view.downloadButton setHidden:!self.showDownloadButtonIfNotLoaded];
                            }
                        });
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [(SwipeView *)self.contentView reloadData];
                if (completion != nil)
                    completion();
            });
        });
    }
}

- (void) mediaItemCreate:(SCRMediaCollectionViewItem *)mediaItem
{
    [self imageForMediaItem:mediaItem.mediaItem completion:^(UIImage *image, NSError *error) {
        mediaItem.downloading = false;
        if (error == nil)
        {
            mediaItem.downloaded = true;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                [imageView setFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, [self imageViewHeight])];
                mediaItem.view = imageView;
                [(SwipeView *)self.contentView reloadData];
            });
        }
    }];
}

- (void) createViewForMediaItem:(SCRMediaItem *)mediaItem
{
    @synchronized(self.mediaItems)
    {
        [self.mediaItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SCRMediaCollectionViewItem *mediaViewItem = obj;
            if ([mediaViewItem.mediaItem isEqual:mediaItem])
            {
                *stop = YES;
                [self mediaItemCreate:mediaViewItem];
            }
        }];
    }
}

- (void)imageForMediaItem:(SCRMediaItem *)mediaItem completion:(void (^)(UIImage *image, NSError *error))completion;
{
    if (!completion) {
        return;
    }
    
    dispatch_async(self.imageQueue, ^{
        __block UIImage *image = nil;
        SCRMediaItemType mediaType = [mediaItem mediaType];
        if (mediaType == SCRMediaItemTypeImage) {
            
            [[SCRAppDelegate sharedAppDelegate].fileManager dataForPath:mediaItem.localPath completionQueue:self.imageQueue completion:^(NSData *data, NSError *error) {
                image = [UIImage imageWithData:data];
                completion(image,error);
            }];
            
        } else if (mediaType == SCRMediaItemTypeVideo) {
            
            image = [[SCRAppDelegate sharedAppDelegate].mediaServer videoThumbnail:mediaItem];
            
            completion(image,nil);
            
        } else if (mediaType == SCRMediaItemTypeAudio ) {
            
        }
        
        
    });
}

- (void) mediaItemDownload:(SCRMediaCollectionViewItem *)mediaItem
{
    mediaItem.downloading = YES;
    [[SCRAppDelegate sharedAppDelegate].mediaFetcher downloadMediaItem:mediaItem.mediaItem completionBlock:^(NSError *error) {
        mediaItem.downloading = NO;
        
        [self imageForMediaItem:mediaItem.mediaItem completion:^(UIImage *image, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    mediaItem.downloaded = true;
                    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                    mediaItem.view = imageView;
                    [imageView setFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, [self imageViewHeight])];
                    [(SwipeView *)self.contentView reloadData];
                    
                    UITableViewCell *cell = [self cellThisViewIsContainedIn];
                    UITableView *tableView = [self tableViewForCell:cell];
                    if (tableView != nil && cell != nil)
                    {
                        NSIndexPath *indexPath = [tableView indexPathForCell:cell];
                        if (indexPath != nil)
                        {
                            [tableView beginUpdates];
                            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                            [tableView endUpdates];
                        }
                    }
                    else
                    {
                        [self updateHeight];
                    }
                }
                else if (mediaItem.view != nil && [mediaItem.view isKindOfClass:[SCRMediaCollectionViewDownloadView class]])
                {
                    [[(SCRMediaCollectionViewDownloadView *)mediaItem.view downloadButton] setHidden:NO];
                    [[(SCRMediaCollectionViewDownloadView *)mediaItem.view activityView] stopAnimating];
                    [[(SCRMediaCollectionViewDownloadView *)mediaItem.view activityView] setHidden:YES];
                }
                
                
            });
        }];
    }];
}

- (UITableViewCell *)cellThisViewIsContainedIn
{
    id view = [self superview];
    while (view && [view isKindOfClass:[UITableViewCell class]] == NO) {
        view = [view superview];
    }
    return view;
}

- (UITableView *)tableViewForCell:(UITableViewCell *)cell
{
    if (cell == nil)
        return nil;
    id view = [cell superview];
    while (view && [view isKindOfClass:[UITableView class]] == NO) {
        view = [view superview];
    }
    return view;
}

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    int count = [self numberOfImages];
    [self.pageControl setNumberOfPages:count];
    return count;
}

-(void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView
{
    [self.pageControl setCurrentPage:[swipeView currentItemIndex]];
}

- (int)numberOfImages
{
    @synchronized(self.mediaItems)
    {
        return (int)self.mediaItems.count;
    }
}

- (int)currentImageIndex
{
    SwipeView *swipe = (SwipeView *)contentView;
    return (int)swipe.currentItemIndex;
}

- (SCRMediaItem *)currentImageMediaItem
{
    @synchronized(self.mediaItems)
    {
        return [[self.mediaItems objectAtIndex:[self currentImageIndex]] mediaItem];
    }
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    @synchronized(self.mediaItems)
    {
        return [[self.mediaItems objectAtIndex:index] view];
    }
}

- (void)downloadButtonClicked:(SCRMediaCollectionViewDownloadView *)view
{
    @synchronized(self.mediaItems)
    {
        [self.mediaItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SCRMediaCollectionViewItem *mediaItem = obj;
            if (mediaItem.view == view && !mediaItem.downloaded && !mediaItem.downloading)
            {
                if ([mediaItem.view isKindOfClass:[SCRMediaCollectionViewDownloadView class]])
                {
                    [[(SCRMediaCollectionViewDownloadView *)mediaItem.view downloadButton] setHidden:YES];
                    [[(SCRMediaCollectionViewDownloadView *)mediaItem.view activityView] setHidden:NO];
                    [[(SCRMediaCollectionViewDownloadView *)mediaItem.view activityView] startAnimating];
                }
                *stop = YES;
                [self mediaItemDownload:mediaItem];
            }
        }];
    }
}

- (void)swipeView:(SwipeView *)swipeView didSelectItemAtIndex:(NSInteger)index
{
    if (index < [self.mediaItems count]) {
        SCRMediaCollectionViewItem *collectionViewItem = self.mediaItems[index];
        
        //Make sure the tapped view is an imageview and not the downloading view
        if ([collectionViewItem.view isKindOfClass:[UIImageView class]]) {
            
            SCRMediaItemType type  = [collectionViewItem.mediaItem mediaType];
            
            // Get parent View Controller a bit ugly but it works
            UIViewController *parentViewController = nil;
            UIResponder *responder = collectionViewItem.view;
            while ([responder isKindOfClass:[UIView class]]) {
                responder = [responder nextResponder];
            }
            if ([responder isKindOfClass:[UIViewController class]]) {
                parentViewController = (UIViewController *)responder;
            }
            
            //Show correct view depending on media
            if (type == SCRMediaItemTypeImage) {
                JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
                imageInfo.image = ((UIImageView *)collectionViewItem.view).image;
                imageInfo.referenceRect = collectionViewItem.view.frame;
                imageInfo.referenceView = collectionViewItem.view.superview;
                
                // Setup view controller
                JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                       initWithImageInfo:imageInfo
                                                       mode:JTSImageViewControllerMode_Image
                                                       backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
                
                
                
                [imageViewer showFromViewController:parentViewController transition:JTSImageViewControllerTransition_FromOriginalPosition];
            } else if (type == SCRMediaItemTypeVideo || type == SCRMediaItemTypeAudio) {
                NSURL *meidaURL = [collectionViewItem.mediaItem localURLWithPort:[SCRAppDelegate sharedAppDelegate].mediaServer.port];
                MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:meidaURL];
                [parentViewController presentViewController:moviePlayerViewController animated:YES completion:nil];
            }
            
            
        }
        
        
    }
}

@end
