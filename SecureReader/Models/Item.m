//
//  Item.m
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "Item.h"

@implementation Item

@synthesize title;
@synthesize text;

+ (id)createWithTitle:(NSString*)title text:(NSString*)text
{
    Item *newItem = [[self alloc] init];
    newItem.title = title;
    newItem.text = text;
    return newItem;
}

@end
