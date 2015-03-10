//
//  SCRFeedSearchTableDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2015-02-25.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRFeedTableDelegate.h"
#import "SCRYapDatabaseTableDelegate.h"

@protocol SCRFeedSearchTableDelegateDelegate <SCRYapDatabaseTableDelegateDelegate>
@optional
-(void) didStartSearch;
-(void) didFinishSearch;
@end

@interface SCRFeedSearchTableDelegate : SCRFeedTableDelegate

- (void) clearSearchResults;
- (void) performSearchWithString:(NSString *)searchString;

@end
