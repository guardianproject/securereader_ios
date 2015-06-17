//
//  SCRReadablityViewController.m
//  SecureReader
//
//  Created by David Chiles on 6/15/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRReadabilityViewController.h"
#import "PureLayout.h"
#import "SCRItem.h"
#import "SCRFileManager.h"
#import "SCRHTMLFetcher.h"
#import "DZReadability.h"
#import "SCRAppDelegate.h"
#import "IOCipher.h"

@interface SCRReadabilityViewController ()

@property (nonatomic, strong) SCRHTMLFetcher *htmlFetcher;
@property (nonatomic, strong) DZReadability *readability;
@property (nonatomic, strong) SCRFileManager *fileManager;

@end

@implementation SCRReadabilityViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadNewFile];
}

- (void)setItem:(SCRItem *)item
{
    if (![_item isEqual:item]) {
        _item = item;
        [self loadNewFile];
    }
}

- (void)loadNewFile
{
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

- (IBAction)doneButtonPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:self completion:nil];
}

- (void)loadHTMLFile:(NSData *)data
{
    NSString *string = [self htmlStringFromData:data];
    NSNumber *options = @([DZReadability defaultOptions]);
    self.readability = [[DZReadability alloc] initWithURL:nil rawDocumentContent:string options:options completionHandler:^(DZReadability *sender, NSString *content, NSError *error) {
        [self.webView loadHTMLString:content baseURL:nil];
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
