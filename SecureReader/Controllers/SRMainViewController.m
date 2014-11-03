//
//  SRMainViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-27.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SRMainViewController.h"
#import "../Models/Item.h"
#import "../Views/ItemView.h"

@interface SRMainViewController ()

@property (strong,nonatomic) NSMutableArray *itemsArray;
@property (strong,nonatomic) NSMutableArray *filteredItemsArray;

// Prototype cells for height calculation
@property (nonatomic, strong) ItemView *prototypeCellNoPhotos;
@property (nonatomic, strong) ItemView *prototypeCellLandscapePhotos;
@property (nonatomic, strong) ItemView *prototypeCellPortraitPhotos;

@end

@implementation SRMainViewController

@synthesize itemsArray;
@synthesize filteredItemsArray;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    itemsArray = [NSMutableArray arrayWithObjects:
                  [Item createWithTitle:@"First\nTitle\nGoes here\nBut is more\nThan 4 lines!" text:@"First text\nThat has more lines"],
                  [Item createWithTitle:@"Second" text:@"Second text"],
                  [Item createWithTitle:@"Third" text:@"Third text"],
                  [Item createWithTitle:@"Fourth" text:@"Fourth text"],
                  nil];
    
    //UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
    //                                    init];
    //refreshControl.tintColor = [UIColor magentaColor];
    //self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO];    
}

- (NSString *) getCellIdentifierForItem:(Item *) item
{
    NSString *cellIdentifier = @"cellNoPhotos";
    if ([item.title hasPrefix:@"F"])
        cellIdentifier = @"cellLandscapePhotos";
    else if ([item.title hasPrefix:@"T"])
        cellIdentifier = @"cellPortraitPhotos";
    return cellIdentifier;
}

- (ItemView *) getPrototypeForItem:(Item *) item
{
    NSString *cellIdentifier = [self getCellIdentifierForItem:item];
    if ([cellIdentifier compare:@"cellLandscapePhotos"] == NSOrderedSame)
    {
        if (!self.prototypeCellLandscapePhotos)
            self.prototypeCellLandscapePhotos = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        return self.prototypeCellLandscapePhotos;
    }
    else if ([cellIdentifier compare:@"cellPortraitPhotos"] == NSOrderedSame)
    {
        if (!self.prototypeCellPortraitPhotos)
            self.prototypeCellPortraitPhotos = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        return self.prototypeCellPortraitPhotos;
    }
    else
    {
        // No photos
        if (!self.prototypeCellNoPhotos)
            self.prototypeCellNoPhotos = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        return self.prototypeCellNoPhotos;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.filteredItemsArray != nil)
        return self.filteredItemsArray.count;
    if (self.itemsArray != nil)
        return self.itemsArray.count;
    return 0;
}

- (Item *) getItemForIndexPath:(NSIndexPath *) indexPath
{
    Item *item = (self.filteredItemsArray != nil) ? self.filteredItemsArray[indexPath.row] : self.itemsArray[indexPath.row];
    return item;
}

- (void)configureCell:(ItemView *)cell forItem:(Item *)item
{
    cell.titleView.text = item.title;
    cell.sourceView.labelSource.text = @"The Guardian";
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    cell.sourceView.labelDate.text = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item *item = [self getItemForIndexPath:indexPath];
    
    NSString *cellIdentifier = [self getCellIdentifierForItem:item];
    
    ItemView *cell = [tableView
                      dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forItem:item];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item *item = [self getItemForIndexPath:indexPath];
    ItemView *prototype = [self getPrototypeForItem:item];
    [self configureCell:prototype forItem:item];
    [prototype layoutIfNeeded];
    
    CGSize size = [prototype.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height+1;
}

@end
