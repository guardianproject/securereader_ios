//
//  Item.h
//  SecureReader
//
//  Created by N-Pex on 2014-09-11.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCRItem : NSObject
{
    NSString *title;
    NSString *text;
}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *text;

+ (id)createWithTitle:(NSString*)title text:(NSString*)text;

@end
