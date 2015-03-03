//
//  SCRItemTableDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2015-02-24.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRYapDatabaseTableDelegate.h"
#import "SCRFeed.h"

@interface SCRItemTableDelegate : SCRYapDatabaseTableDelegate<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

- (id)initWithTableView:(UITableView *)tableView viewName:(NSString*)viewName filter:(SCRFeed *)feed delegate:(id<SCRYapDatabaseTableDelegateDelegate>)delegate;

@end
