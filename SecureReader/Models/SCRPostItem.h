//
//  SCRPostItem.h
//  SecureReader
//
//  Created by N-Pex on 2015-04-01.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRItem.h"
#import "SCRYapObject.h"

@interface SCRPostItem : SCRItem

@property (nonatomic) NSString *uuid;
@property (nonatomic) NSDate *lastEdited;
@property (nonatomic) BOOL isSent;

@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSString *itemDescription;
@property (nonatomic, strong, readwrite) NSDate *publicationDate;
@property (nonatomic) NSArray *tags;

@end
