//
//  SCRMediaItem.h
//  SecureReader
//
//  Created by David Chiles on 2/26/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "RSSMediaItem.h"

#import "SCRYapObject.h"

@interface SCRMediaItem : RSSMediaItem <SCRYapObject>

/** Local path for used in IOCipher */
- (NSString *)localPath;

/** Local URL to be used with SCRMediaServer */
- (NSURL *)localURLWithPort:(NSUInteger)port;

/** Hashes the URL to be used as a Yap key */
+ (NSString *)mediaItemKeyForURL:(NSURL *)url;

@end
