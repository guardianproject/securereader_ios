
//
//  SCRItemPageViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemPageViewController.h"
#import "NSString+HTML.h"
#import "NSFormatter+SecureReader.h"
#import <Foundation/NSDateFormatter.h>
#import "RSSPerson.h"
#import "SCRApplication.h"
#import "SCRSettings.h"
#import "SCRDatabaseManager.h"
#import "SCRFeed.h"
#import "SCRFileManager.h"
#import "SCRHTMLFetcher.h"
#import "DZReadability.h"
#import "SCRAppDelegate.h"

@interface SCRItemPageViewController ()

@property (nonatomic, strong) SCRHTMLFetcher *htmlFetcher;
@property (nonatomic, strong) DZReadability *readability;
@property (nonatomic, strong) SCRFileManager *fileManager;

@end

@implementation SCRItemPageViewController

@synthesize itemIndexPath;

@synthesize mediaCollectionView = _mediaCollectionView;
@synthesize imageViewHeightConstraint = _imageViewHeightConstraint;
@synthesize sourceView = _sourceView;
@synthesize titleView = _titleView;
@synthesize contentView = _contentView;

- (void)viewDidLoad {
    [super viewDidLoad];
    [_contentView setScrollEnabled:NO];
    [self.mediaCollectionView setShowDownloadButtonIfNotLoaded:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    __block SCRFeedViewPreference viewPreference = SCRFeedViewPreferenceRSS;
    [[SCRDatabaseManager sharedInstance].readConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * transaction) {
        SCRFeed *feed = [transaction objectForKey:self.item.feedYapKey inCollection:[SCRFeed yapCollection]];
        viewPreference = feed.viewPreference;
    } completionQueue:dispatch_get_main_queue() completionBlock:^(void){
        [self switchToView:viewPreference];
    }];
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    [self.scrollView setContentInset:UIEdgeInsetsMake(navBarHeight, 0, 0, 0)];
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, self.scrollView.frame.size.width, 1) animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setItem:(SCRItem *)item
{
    _item = item;
    NSParameterAssert(item != nil);
    if (!self.item) {
        return;
    }
    [self view]; // force view to load if it hasn't already

    [self.mediaCollectionView setItem:self.item];
    [self.mediaCollectionView createThumbnails:[SCRSettings downloadMedia] completion:nil];
    
    [[SCRDatabaseManager sharedInstance].readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * __nonnull transaction) {
        SCRFeed *existingFeed = [transaction objectForKey:item.feedYapKey inCollection:[[SCRFeed class] yapCollection]];
        if (existingFeed) {
            self.sourceView.labelSource.text = existingFeed.title;
        }
        else {
            self.sourceView.labelSource.text = [item.linkURL host];
        }
    }];
    
    self.sourceView.labelDate.text = [[NSFormatter scr_sharedIntervalFormatter] stringForTimeIntervalFromDate:[NSDate date] toDate:item.publicationDate];

    self.titleView.text =  self.item.title;
    
    self.authorView.labelDate.text = [NSDateFormatter localizedStringFromDate:self.item.publicationDate dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    self.authorView.labelTime.text = [NSDateFormatter localizedStringFromDate:self.item.publicationDate dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    if (self.item.author != nil && self.item.author.name != nil)
        self.authorView.labelAuthorName.text = [NSString stringWithFormat:NSLocalizedString(@"ItemPage.AuthorName", @"Author name string"), self.item.author.name];
    else if (self.item.author != nil && self.item.author.email != nil)
        self.authorView.labelAuthorName.text = [NSString stringWithFormat:NSLocalizedString(@"ItemPage.AuthorName", @"Author name string"), self.item.author.email];
    else
        self.authorView.labelAuthorName.text = @"";
    self.authorView.labelAuthorName.text = [self.authorView.labelAuthorName.text uppercaseString];
    
    if (self.authorView.labelAuthorName.text.length == 0)
        self.authorView.authorNameHeightConstaint.priority = 1000;
    else
        self.authorView.authorNameHeightConstaint.priority = 1;
    
    self.contentView.text = [self.item.itemDescription stringByConvertingHTMLToPlainText];

    [self.view layoutIfNeeded];
}

 #pragma - mark Readability

- (SCRFileManager *)fileManager
{
    if (!_fileManager) {
        _fileManager = [SCRAppDelegate sharedAppDelegate].fileManager;
    }
    return _fileManager;
}

- (SCRHTMLFetcher *)htmlFetcher
{
    if (!_htmlFetcher) {
        _htmlFetcher = [[SCRHTMLFetcher alloc] initWithStorage:self.fileManager.ioCipher];
    }
    return _htmlFetcher;
}

- (void)switchToView:(SCRFeedViewPreference)viewPreference
{
    if(viewPreference == SCRFeedViewPreferenceRSS) {
        
        self.contentView.text = [self.item.itemDescription stringByConvertingHTMLToPlainText];
        
    } else if (viewPreference == SCRFeedViewPreferenceReadability) {
        
        [self loadHTML];
        
    }
}

- (void)loadHTML {
    __block NSString *path = [self.item pathForDownloadedHTML];
    
    __weak typeof(self)weakSelf = self;
    void (^loadBlock)(NSError *error) = ^void(NSError *error) {
        if (!error) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf.fileManager dataForPath:path completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSData *data, NSError *error) {
                [strongSelf loadHTMLFile:data];
            }];
            
        }
    };
    
    BOOL isDirecotry = NO;
    BOOL fileExists = [self.fileManager.ioCipher fileExistsAtPath:path isDirectory:&isDirecotry];
    
    //Ned to fetch the html
    if (!fileExists || isDirecotry) {
        [self.htmlFetcher fetchHTMLFor:self.item
                       completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                            completion:loadBlock];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            loadBlock(nil);
        });
    }
}

- (void)loadHTMLFile:(NSData *)data
{
    NSString *string = [self htmlStringFromData:data];
    NSNumber *options = @([DZReadability defaultOptions]);
    self.readability = [[DZReadability alloc] initWithURL:nil rawDocumentContent:string options:options completionHandler:^(DZReadability *sender, NSString *content, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentView.text = [content stringByConvertingHTMLToPlainText];
            [self.view setNeedsLayout];
        });
        
    }];
    [self.readability start];
}

- (NSString *)htmlStringFromData:(NSData *)data
{
    NSString *string = nil;
    NSInteger encodings[4] = {
        NSUTF8StringEncoding,
        NSMacOSRomanStringEncoding,
        NSASCIIStringEncoding,
        NSUTF16StringEncoding
    };
    
    // some sites might not be UTF8, so try until nil
    for( size_t i = 0; i < sizeof( encodings ) / sizeof( NSInteger ); i++ ) {
        if( ( string = [[NSString alloc] initWithData:data encoding:encodings[i]] ) != nil ) {
            break;
        }
    }
    return string;
}

@end
