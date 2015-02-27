//
//  SCRYapDatabaseTableDelegate.h
//  SecureReader
//
//  Created by N-Pex on 2015-02-24.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YapDatabase.h>
#import <YapDatabaseView.h>

@protocol SCRYapDatabaseTableDelegateDelegate;

@interface SCRYapDatabaseTableDelegate : NSObject<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<SCRYapDatabaseTableDelegateDelegate> delegate;

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSString *yapViewName;
@property (nonatomic, strong) YapDatabaseViewMappings *yapMappings;

- (id)initWithTableView:(UITableView *)tableView viewName:(NSString *)viewName delegate:(id<SCRYapDatabaseTableDelegateDelegate>)delegate;
- (NSObject *) itemForIndexPath:(NSIndexPath *)indexPath;
- (void)setActive:(BOOL)active;

@end

@protocol SCRYapDatabaseTableDelegateDelegate <NSObject>
@optional
- (void) configureCell:(UITableViewCell *)cell item:(NSObject *)item delegate:(SCRYapDatabaseTableDelegate *)delegate;
- (void) didSelectRowAtIndexPath:(NSIndexPath *)indexPath delegate:(SCRYapDatabaseTableDelegate *)delegate;
@end
