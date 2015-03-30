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

@interface SCRMediaCollectionViewItem : NSObject

@property (nonatomic, weak) SCRMediaItem *mediaItem;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic) BOOL downloading;

@end

@implementation SCRMediaCollectionViewItem
@end

@interface SCRMediaCollectionView ()
@property (nonatomic, strong) NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) SCRItem *item;

@property (nonatomic, strong) NSMutableArray *mediaItems;

@property (nonatomic, strong) dispatch_queue_t imageQueue;
@property BOOL hasMedia;
@property BOOL atLeastOneMediaItemDownloaded;
@end

@implementation SCRMediaCollectionView

@synthesize contentView;
@synthesize downloadButton;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
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

- (void) setItem:(SCRItem *)item
{
    if (_item != item)
    {
        _item = item;
        [self.mediaItems removeAllObjects];
        self.hasMedia = NO;
        self.atLeastOneMediaItemDownloaded = NO;
        [self.activityView setHidden:YES];
        [self.downloadButton setHidden:YES];
        [[SCRDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [_item enumerateMediaItemsInTransaction:transaction block:^(SCRMediaItem *mediaItem, BOOL *stop) {
                SCRMediaCollectionViewItem *item = [SCRMediaCollectionViewItem new];
                item.mediaItem = mediaItem;
                item.imageView = nil;
                item.downloading = NO;
                [self.mediaItems addObject:item];
            }];
        }];
    }
    [self updateHeight];
}

- (void)updateHeight
{
    if (!self.atLeastOneMediaItemDownloaded)
    {
        for (SCRMediaCollectionViewItem *mediaItem in self.mediaItems)
        {
            self.hasMedia = YES;
            if ([[SCRAppDelegate sharedAppDelegate].fileManager hasDataForPath:mediaItem.mediaItem.localPath])
            {
                self.atLeastOneMediaItemDownloaded = YES;
                break;
            }
        }
    }
    
    if (self.atLeastOneMediaItemDownloaded)
    {
        self.heightConstraint.constant = [self imageViewHeight];
        [self.downloadButton setHidden:YES];
        [self.activityView setHidden:YES];
    }
    else if (self.showDownloadButtonIfNoneLoaded && self.hasMedia)
    {
        self.heightConstraint.constant = [self downloadViewHeight];
        [self.downloadButton setHidden:NO];
    }
    else
    {
        self.heightConstraint.constant = 0;
        [self.downloadButton setHidden:YES];
        [self.downloadButton setHidden:YES];
    }
}

- (int)downloadViewHeight
{
    return 80;
}

- (int)imageViewHeight
{
    return 200;
}

- (void) createThumbnails:(BOOL)downloadIfNeeded
{
    if (_item != nil)
    {
        if (self.imageQueue == nil)
            self.imageQueue = dispatch_queue_create("ImageQueue",NULL);
        dispatch_async(self.imageQueue, ^{
            
            for (SCRMediaCollectionViewItem *mediaItem in self.mediaItems)
            {
                if (mediaItem.imageView != nil || mediaItem.downloading)
                    continue;
                
                self.hasMedia = YES;
                
                if ([[SCRAppDelegate sharedAppDelegate].fileManager hasDataForPath:mediaItem.mediaItem.localPath])
                {
                    self.atLeastOneMediaItemDownloaded = YES;
                    [self.activityView setHidden:YES];
                    
                    [[SCRAppDelegate sharedAppDelegate].fileManager dataForPath:mediaItem.mediaItem.localPath completionQueue:self.imageQueue completion:^(NSData *data, NSError *error) {
                        UIImage *image = [UIImage imageWithData:data];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                            [imageView setFrame:CGRectMake(0, 0, self.contentView.bounds.size.width, [self imageViewHeight])];
                            mediaItem.imageView = imageView;
                            [(SwipeView *)self.contentView reloadData];
                        });
                    }];
                }
                else if (downloadIfNeeded)
                {
                    // Don't have the data, needs downloading
                    mediaItem.downloading = YES;
                    [[SCRAppDelegate sharedAppDelegate].mediaFetcher downloadMediaItem:mediaItem.mediaItem completionBlock:^(NSError *error) {
                        mediaItem.downloading = NO;
                        [self.activityView setHidden:YES];
                        
                        [[SCRAppDelegate sharedAppDelegate].fileManager dataForPath:mediaItem.mediaItem.localPath completionQueue:self.imageQueue   completion:^(NSData *data, NSError *error) {

                            self.atLeastOneMediaItemDownloaded = YES;
                            
                            UIImage *image = [UIImage imageWithData:data];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                                mediaItem.imageView = imageView;
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
                            });
                        }];
                    }];
                }
            }
        });
    }
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
    __block int count = 0;
    [self.mediaItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SCRMediaCollectionViewItem *mediaItem = obj;
        if (mediaItem.imageView != nil)
            count++;
    }];
    return count;
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
{
    __block UIView *imageView = nil;
    __block int count = 0;
    [self.mediaItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SCRMediaCollectionViewItem *mediaItem = obj;
        if (mediaItem.imageView != nil)
        {
            if (count == index)
            {
                imageView = mediaItem.imageView;
                *stop = YES;
            }
            count++;
        }
    }];
    return imageView;
}

- (IBAction) downloadMedia:(id)sender {
    [self.downloadButton setHidden:YES];
    [self.activityView setHidden:NO];
    [self createThumbnails:YES];
}

@end
