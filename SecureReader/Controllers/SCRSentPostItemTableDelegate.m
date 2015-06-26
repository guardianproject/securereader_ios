//
//  SCRSentPostItemTableDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2015-04-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRSentPostItemTableDelegate.h"
#import "SCRItemView.h"
#import "SCRPostItem.h"
#import "NSFormatter+SecureReader.h"

@implementation SCRSentPostItemTableDelegate

- (void)createMappings
{
    self.yapMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        if ([group isEqualToString:@"Sent"])
            return YES;
        return NO;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return [group1 compare:group2];
    } view:self.yapViewName];
}

@end
