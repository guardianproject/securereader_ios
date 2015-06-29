//
//  SCRFeedSearchTableDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2015-02-25.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFeedSearchTableDelegate.h"
#import <AFNetworking.h>
#import "Ono.h"
#import "YapDatabase.h"
#import "YapDatabaseFullTextSearch.h"
#import "YapDatabaseSearchQueue.h"
#import <YapDatabaseSearchResultsViewTransaction.h>
#import "SCRSettings.h"
#import "SCRFeed.h"
#import "SCRDatabaseManager.h"
#import "SCRAppDelegate.h"

#define WEB_SEARCH_URL_FORMAT @"http://securereader.guardianproject.info/opml/find.php?lang=%1$@&term=%2$@&desc=1"

@interface SCRFeedSearchTableDelegate()
@property AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) YapDatabaseSearchQueue *searchQueue;
@property NSArray *searchResults;
@property (nonatomic, strong) YapDatabaseConnection *searchReadConnection;
@end

@implementation SCRFeedSearchTableDelegate

- (id)initWithTableView:(UITableView *)tableView viewName:(NSString *)viewName delegate:(id<SCRYapDatabaseTableDelegateDelegate>)delegate
{
    self = [super initWithTableView:tableView viewName:viewName delegate:delegate];
    if (self != nil)
    {
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
        serializer.acceptableContentTypes  = [NSSet setWithObjects:@"application/opml",
                                              nil];
        self.sessionManager.responseSerializer = serializer;
        [self.sessionManager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
            return request;
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeYapConnections:) name:SCRRemoveYapConnectionsNotification object:[SCRDatabaseManager sharedInstance]];
    }
    return self;
}

- (void) removeYapConnections:(NSNotification*)notification {
    self.searchReadConnection = nil;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCRRemoveYapConnectionsNotification object:[SCRDatabaseManager sharedInstance]];
}

- (void)clearSearchResults
{
    self.searchResults = nil;    
}

- (void)performSearchWithString:(NSString *)searchString
{
    [self searchLocalFeeds:searchString];
    [self searchWebFeeds:searchString];
}

- (void)searchWebFeeds:(NSString *)searchString
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate != nil && [self.delegate conformsToProtocol:@protocol(SCRFeedSearchTableDelegateDelegate)])
        {
            id<SCRFeedSearchTableDelegateDelegate> delegate = (id<SCRFeedSearchTableDelegateDelegate>)self.delegate;
            if ([delegate respondsToSelector:@selector(didStartSearch)])
                [delegate didStartSearch];
        }
    });
    
    NSString *encodedSearchString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                  NULL,
                                                                                  (CFStringRef)searchString,
                                                                                  NULL,
                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8 ));
    
    NSString *urlString = [NSString stringWithFormat:WEB_SEARCH_URL_FORMAT, [SCRSettings getUiLanguage], encodedSearchString];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    
    [[SCRAppDelegate sharedAppDelegate].feedFetcher fetchFeedsFromOPMLURL:url
                                                          completionBlock:^(NSArray *feeds, NSError *error) {
                                                              
                                                              if (self.delegate != nil && [self.delegate conformsToProtocol:@protocol(SCRFeedSearchTableDelegateDelegate)])
                                                              {
                                                                  id<SCRFeedSearchTableDelegateDelegate> delegate = (id<SCRFeedSearchTableDelegateDelegate>)self.delegate;
                                                                  if ([delegate respondsToSelector:@selector(didFinishSearch)])
                                                                      [delegate didFinishSearch];
                                                              }
                                                              
                                                              if (error == nil)
                                                              {
                                                                  self.searchResults = feeds;
                                                                  for (SCRFeed *feed in self.searchResults)
                                                                  {
                                                                      feed.userAdded = YES;
                                                                  }
                                                                  [self.tableView reloadData];
                                                              }
                                                              
                                                          } completionQueue:nil];
}

- (void)searchLocalFeeds:(NSString *)searchString
{
    if (self.searchReadConnection == nil)
        self.searchReadConnection = [[SCRDatabaseManager sharedInstance].database newConnection];
    
    if (self.searchQueue == nil)
        self.searchQueue = [[YapDatabaseSearchQueue alloc] init];
    
    // Parse the text into a proper search query
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    
    NSArray *searchComponents = [searchString componentsSeparatedByCharactersInSet:whitespace];
    NSMutableString *query = [NSMutableString string];
    
    for (NSString *term in searchComponents)
    {
        if ([term length] > 0)
            [query appendString:@""];
        
        [query appendFormat:@"%@*", term];
    }
    
    NSLog(@"searchString(%@) -> query(%@)", searchString, query);
    [self.searchQueue enqueueQuery:query];
    
    [self.searchReadConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction)
     {
         [[transaction ext:self.yapViewName] performSearchWithQueue:self.searchQueue];
     }];
}

- (int) tableSectionIndexOffset
{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return 1 + [self.yapMappings numberOfSections];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
    {
        // Local search results in first section
        if (self.searchResults == nil)
            return 0;
        return self.searchResults.count;
    }
    else
    {
        NSInteger numberOfRows = [self.yapMappings numberOfItemsInSection:(section - 1)];
        return numberOfRows;
    }
}

- (NSObject *) itemForIndexPath:(NSIndexPath *)indexPath
{
    NSObject *feed = nil;
    if (indexPath.section == 0)
    {
        // Local search results in first section
        feed = [self.searchResults objectAtIndex:indexPath.row];
    }
    else
    {
        // Search my feeds
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:(indexPath.section - 1)];
        feed = [super itemForIndexPath:newIndexPath];
    }
    return feed;
}

@end
