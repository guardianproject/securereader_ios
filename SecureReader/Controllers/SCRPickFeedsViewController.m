//
//  SCRPickFeedsViewController.m
//  SecureReader
//
//  Created by N-Pex on 2015-05-13.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRPickFeedsViewController.h"
#import "SCRFeedTableDelegate.h"
#import "SCRDatabaseManager.h"
#import "SCRAppDelegate.h"
#import "SCRFeedListCell.h"
#import "SCRFeedListCategoryCell.h"
#import "RSSParser.h"
#import "NSString+SecureReader.h"
#import "SCRPassphraseManager.h"

@interface SCRPickFeedsViewController ()
@property (nonatomic, strong) NSMutableDictionary *feedsDictionary;
@property (nonatomic, strong) NSMutableArray *categoriesArray; // For deterministic ordering!
@property (nonatomic, strong) UITableViewCell *prototype;
@property (nonatomic, strong) NSArray *feeds;
@end

@implementation SCRPickFeedsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    UINib *nib = [UINib nibWithNibName:@"SCRFeedListCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellFeed"];
    nib = [UINib nibWithNibName:@"SCRFeedListCellWithDescription" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellFeedWithDescription"];
    nib = [UINib nibWithNibName:@"SCRFeedListCategoryCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"cellFeedCategory"];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSString *opmlPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"opml"];
    NSData *opmlData = [NSData dataWithContentsOfFile:opmlPath];
    
    RSSParser *parser = [SCRFeedFetcher defaultParser];
    
    [parser feedsFromOPMLData:opmlData completionBlock:^(NSArray *feeds, NSError *error) {
        self.feeds = feeds;
        [self processFeeds:feeds];
    } completionQueue:dispatch_get_main_queue()];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL) shouldPerformSegueWithIdentifier:(nonnull NSString *)identifier sender:(nullable id)sender {
    if ([identifier isEqualToString:@"finishFeedCuration"]) {
        
        // Save all subscribed feeds to a property list so that we can
        // add them later, when we have created the DB. Only add hashes for the URLs, to avoid
        // plain text URLs being kept.
        NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        NSURL *processedFileURL = [[tmpDirURL URLByAppendingPathComponent:@"filtered"] URLByAppendingPathExtension:@"opml"];
        
        NSMutableArray *array = [NSMutableArray new];
        for (SCRFeed *feed in self.feeds)
        {
            if (feed.subscribed)
                [array addObject:[[feed.xmlURL absoluteString] scr_md5]];
        }
        
        NSString *errorStr;
        NSData *dataRep = [NSPropertyListSerialization dataFromPropertyList:array
                                                                     format:NSPropertyListXMLFormat_v1_0
                                                           errorDescription:&errorStr];
        if (!dataRep) {
            // Handle error
        }
        else{
            [dataRep writeToURL:processedFileURL atomically:YES];
        }
        
        // Setup db on first run
        [[SCRTouchLock sharedInstance] deletePasscode];
        NSString *passphrase = [[SCRPassphraseManager sharedInstance] generateNewPassphrase];
        [[SCRPassphraseManager sharedInstance] setDatabasePassphrase:passphrase storeInKeychain:YES];
        BOOL success = [[SCRAppDelegate sharedAppDelegate] setupDatabase];
        if (!success) {
            NSLog(@"Error setting up database!");
        }
    }
    return YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void) processFeeds:(NSArray *)feeds
{
    _feedsDictionary = [NSMutableDictionary dictionary];
    _categoriesArray = [NSMutableArray array];
    for (SCRFeed *feed in feeds)
    {
        NSString *category = nil;
        if ([feed.feedCategory length] > 0)
            category = feed.feedCategory;
        
        category = [[NSBundle mainBundle] localizedStringForKey:category value:category table:@"FeedCategories"];
        
        NSMutableArray *categoryFeeds = [_feedsDictionary objectForKey:category];
        if (categoryFeeds == nil)
        {
            categoryFeeds = [NSMutableArray new];
            [_feedsDictionary setObject:categoryFeeds forKey:category];
            [_categoriesArray addObject:category];
        }
        [categoryFeeds addObject:feed];
    }
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [_categoriesArray count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableArray *sectionFeeds = [_feedsDictionary objectForKey:[_categoriesArray objectAtIndex:section]];
    return [sectionFeeds count];
}

- (void)configureCell:(UITableViewCell *)genericcell forItem:(NSObject *)genericitem
{
    SCRFeedListCell *cell = (SCRFeedListCell *)genericcell;
    SCRFeed *feed = (SCRFeed *)genericitem;
    
    cell.titleView.text = feed.title;
    if (cell.descriptionView != nil)
    {
        cell.descriptionView.text = feed.feedDescription;
        if (cell.descriptionView.text.length == 0)
            cell.descriptionView.text = [feed.xmlURL absoluteString];
    }
    
    cell.iconViewWidthConstraint.constant = 70;
    if ([feed subscribed])
        [cell.iconView setImage:[UIImage imageNamed:@"ic_toggle_selected"]];
    else
        [cell.iconView setImage:[UIImage imageNamed:@"ic_toggle_add"]];
    [cell.iconView setHidden:NO];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *key = [_categoriesArray objectAtIndex:section];
    if (key.length == 0)
        return @"Uncategorized";
    return key;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 91;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SCRFeedListCategoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellFeedCategory"];
    cell.titleView.text = [self tableView:tableView titleForHeaderInSection:section];
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    NSString *category = (NSString *)[_categoriesArray objectAtIndex:section];
    NSURL *url = nil;
    if ([@"World News" isEqualToString:category])
    {
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"img_cat-worldnews" ofType:@"svg"]];
        [cell.documentView setArtworkPath:@"img_cat-worldnews"];
    }
    else if ([@"National News" isEqualToString:category])
    {
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"img_cat-nationalnews" ofType:@"svg"]];
        [cell.documentView setArtworkPath:@"img_cat-nationalnews"];
    }
    else if ([@"Arts & Culture" isEqualToString:category])
    {
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"img_cat-artsculture" ofType:@"svg"]];
        [cell.documentView setArtworkPath:@"img_cat-artsculture"];
    }
    else if ([@"Business" isEqualToString:category])
    {
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"img_cat-business" ofType:@"svg"]];
        [cell.documentView setArtworkPath:@"img_cat-business"];
    }
    else if ([@"Sports" isEqualToString:category])
    {
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"img_cat-sports" ofType:@"svg"]];
        [cell.documentView setArtworkPath:@"img_cat-sports"];
    }
    else if ([@"Technology" isEqualToString:category])
    {
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"img_cat-technology" ofType:@"svg"]];
        [cell.documentView setArtworkPath:@"img_cat-technology"];
    }
    else if ([@"Security" isEqualToString:category])
    {
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"img_cat-security" ofType:@"svg"]];
        [cell.documentView setArtworkPath:@"img_cat-security"];
    }
    else if ([@"Discussion" isEqualToString:category])
    {
        url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"img_cat-discussion" ofType:@"svg"]];
        [cell.documentView setArtworkPath:@"img_cat-discussion"];
    }
    else
    {
        [cell.catImageView setBackgroundColor:self.tableView.tableHeaderView.backgroundColor];
        [cell.documentView setDefaultColor:[UIColor clearColor]];
        [cell.documentView setBackgroundColor:[UIColor clearColor]];
        [cell.documentView setBeTransparent:YES];
    }
    
    if (url != nil)
    {
        SVGRenderer *renderer = [[SVGRenderer alloc] initWithContentsOfURL:url];
        UIImage *image = [self render:renderer asImageWithSize:cell.catImageView.frame.size andScale:1.0f];
        UIColor *color = [self getColorForPixel:CGPointMake(0, 5) inImage:image];

        [cell.documentView setContentMode:UIViewContentModeScaleAspectFit];
        [cell.documentView setDefaultColor:color];
        [cell.documentView setBackgroundColor:[UIColor clearColor]];
        [cell.documentView setBeTransparent:YES];
        
        //change width of frame
        cell.imageWidthConstraint.constant = image.size.width;
        if (color != nil)
        {
            [cell.catImageView setBackgroundColor:color];
        }
    }

    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *item = [self itemForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellFeedWithDescription" forIndexPath:indexPath];
    [self configureCell:cell forItem:item];
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    return cell;
}

- (UITableViewCell *)prototypeWithIdentifier:(NSString *)identifier
{
    if (self.prototype == nil)
    {
        self.prototype = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    }
    return self.prototype;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *item = [self itemForIndexPath:indexPath];
    UITableViewCell *prototype = [self prototypeWithIdentifier:@"cellFeedWithDescription"];
    [self configureCell:prototype forItem:item];
    [prototype setNeedsUpdateConstraints];
    [prototype updateConstraintsIfNeeded];
    prototype.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(prototype.bounds));
    [prototype setNeedsLayout];
    [prototype layoutIfNeeded];
    CGSize size = [prototype.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height+1;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (NSObject *) itemForIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *feedsInSection = [_feedsDictionary objectForKey:[_categoriesArray objectAtIndex:indexPath.section]];
    return [feedsInSection objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    SCRFeed *feed = (SCRFeed *)[self itemForIndexPath:indexPath];
    feed.subscribed = !feed.subscribed;
    [self.tableView reloadData];
}

- (UIColor *)getColorForPixel:(CGPoint)pt inImage:(UIImage *)image{
    
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel    = 4;
    size_t bytesPerRow      = (width * bitsPerComponent * bytesPerPixel + 7) / 8;
    size_t dataSize         = bytesPerRow * height;
    
    unsigned char *data = malloc(dataSize);
    memset(data, 0, dataSize);
    
    CGContextRef context = CGBitmapContextCreate(data, width, height,
                                                 bitsPerComponent,
                                                 bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
    
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    int offset = pt.y * bytesPerRow + pt.y * bytesPerPixel;
    
    int alpha =  data[offset+0];
    int red = data[offset+1];
    int green = data[offset+2];
    int blue = data[offset+3];
    UIColor *color = [UIColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:(alpha/255.0f)];
    
    // When finished, release the context
    CGContextRelease(context);
    if (data) { free(data); }
    
    return color;
}

-(UIImage*)render:(SVGRenderer *)renderer asImageWithSize:(CGSize)maximumSize andScale:(CGFloat)scale
{
    CGSize documentSize = renderer.viewRect.size;
    
    CGFloat interiorAspectRatio = maximumSize.width/maximumSize.height;
    CGFloat rendererAspectRatio = documentSize.width/documentSize.height;
    CGFloat fittedScaling;
    if(interiorAspectRatio >= rendererAspectRatio)
    {
        fittedScaling = maximumSize.height/documentSize.height;
    }
    else
    {
        fittedScaling = maximumSize.width/documentSize.width;
    }
    
    CGFloat scaledWidth = floor(documentSize.width*fittedScaling);
    CGFloat scaleHeight = floor(documentSize.height*fittedScaling);
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(scaledWidth, scaleHeight), NO, scale);
    CGContextRef quartzContext = UIGraphicsGetCurrentContext();
    CGContextClearRect(quartzContext, CGRectMake(0, 0, scaledWidth, scaleHeight));
    CGContextSetFillColorWithColor(quartzContext, [UIColor whiteColor].CGColor);
    CGContextFillRect(quartzContext, CGRectMake(0, 0, scaledWidth, scaleHeight));
    CGContextSaveGState(quartzContext);
    CGContextTranslateCTM(quartzContext, 0, (maximumSize.height-scaleHeight)/2.0);
    CGContextScaleCTM(quartzContext, fittedScaling, fittedScaling);
    
    // tell the renderer to draw into my context
    [renderer renderIntoContext:quartzContext];
    CGContextRestoreGState(quartzContext);
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

@end
