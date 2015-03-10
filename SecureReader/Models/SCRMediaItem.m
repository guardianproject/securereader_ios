//
//  SCRMediaItem.m
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRMediaItem.h"
#import "YapDatabaseTransaction.h"

@interface SCRMediaItem ()

@property (nonatomic, strong) NSString *yapKey;

@end

@implementation SCRMediaItem

- (instancetype)init
{
    if (self = [super init]) {
        self.yapKey = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (NSString *)localPath
{
    return [NSString pathWithComponents:@[@"/",self.itemYapKey,self.yapKey,self.remoteURL.lastPathComponent]];
}

- (NSURL *)localURLWithPort:(NSUInteger)port
{
    return [NSURL URLWithString:[[NSString stringWithFormat:@"http://localhost:%lu",port] stringByAppendingPathComponent:[self localPath]]];
}

#pragma - mark YapObjectProtocol

- (NSString *)yapGroup
{
    return self.itemYapKey;
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
