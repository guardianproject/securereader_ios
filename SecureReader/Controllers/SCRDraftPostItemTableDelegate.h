//
//  SCRDraftPostItemTableDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRYapDatabaseTableDelegate.h"
#import "SCRPostItem.h"

@protocol SCRDraftPostItemTableDelegateDelegate <SCRYapDatabaseTableDelegateDelegate>
@optional
-(void) editDraftItem:(SCRPostItem *)item;
-(void) deleteDraftItem:(SCRPostItem *)item;
@end

@interface SCRDraftPostItemTableDelegate : SCRYapDatabaseTableDelegate

@end
