//
//  SCRMediaItem.m
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaItem.h"
#import "YapDatabaseTransaction.h"
#import "NSData+SecureReader.h"

@interface SCRMediaItem ()

@property (nonatomic, strong) NSString *yapKey;

@end

@implementation SCRMediaItem

- (instancetype)initWithURL:(NSURL *)url
{
    if (self = [super initWithURL:url]) {
        self.yapKey = [[self class] mediaItemKeyForURL:self.url];
    }
    return self;
}

- (instancetype)initWithFeedType:(RSSFeedType)feedType xmlElement:(ONOXMLElement *)xmlElement
{
    if (self = [super initWithFeedType:feedType xmlElement:xmlElement]) {
        self.yapKey = [[self class] mediaItemKeyForURL:self.url];
    }
    return self;
}

- (NSString *)localPath
{
    return [NSString pathWithComponents:@[@"/media",self.yapKey,self.url.lastPathComponent]];
}

- (NSURL *)localURLWithPort:(NSUInteger)port
{
    return [NSURL URLWithString:[[NSString stringWithFormat:@"http://localhost:%lu",port] stringByAppendingPathComponent:[self localPath]]];
}

 #pragma - mark Class Methods

+ (NSString *)mediaItemKeyForURL:(NSURL *)url
{
    return [[url.absoluteString dataUsingEncoding:NSUTF8StringEncoding] scr_sha1];
}

#pragma - mark YapObjectProtocol

- (NSString *)yapGroup
{
    return self.yapKey;
}

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction setObject:self forKey:self.yapKey inCollection:[[self class] yapCollection]];
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [transaction removeObjectForKey:self.yapKey inCollection:[[self class] yapCollection]];
    
}

+ (NSString *)yapCollection
{
    return NSStringFromClass([self class]);
}


@end
