//
//  SCRReader.m
//  SecureReader
//
//  Created by N-Pex on 2015-01-19.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRReader.h"

@implementation SCRReader

#pragma mark Singleton Methods

+ (id)sharedInstance {
    static SCRReader *sharedReader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedReader = [[self alloc] init];
    });
    return sharedReader;
}

- (id)init {
    if (self = [super init]) {
    }
    return self;
}

-(void) markItem:(SCRItem *)item asFavorite:(BOOL)favorite
{
    //TODO
}

@end
