//
//  SCRMediaItem.h
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "MTLModel.h"

#import "SCRYapObject.h"

@interface SCRMediaItem : MTLModel <SCRYapObject>

//The key for the 'parent' SCRItem (required)
@property (nonatomic, strong) NSString *itemYapKey;

@property (nonatomic, strong) NSURL *remoteURL;

- (NSString *)localPath;
- (NSURL *)localURLWithPort:(NSUInteger)port;

@end
