//
//  SCRItemViewControllerSegue.m
//  SecureReader
//
//  Created by N-Pex on 2014-12-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemViewControllerSegue.h"

@implementation SCRItemViewControllerSegue

- (void) perform {
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    UIViewController *source = self.sourceViewController;
    source.navigationItem.backBarButtonItem = backItem;
    [source.navigationController pushViewController:self.destinationViewController animated:YES];
}

@end
