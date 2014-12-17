//
//  SCRItemViewController.m
//  SecureReader
//
//  Created by N-Pex on 2014-11-24.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRItemViewController.h"
#import "SCRItemPageViewController.h"

#define kAnimationDurationRearrange 1.0

@interface SCRItemViewController ()

@property BOOL isInitialized;
@property (weak, nonatomic) IBOutlet UIPageViewController *pageViewController;
@property NSMutableArray *pages;
@property NSLayoutManager *layoutManager;
@property NSTextStorage *textStorage;
@property int nextColumnTagNumber;
@property SCRItemPageViewController *currentPage;
@property SCRItemView *collapsedView;
@end

@implementation SCRItemViewController

@synthesize pageViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isInitialized = NO;
    self.nextColumnTagNumber = 0;
    
    NSURL *contentURL = [[NSBundle mainBundle] URLForResource:@"content" withExtension:@"txt"];
    _textStorage = [[NSTextStorage alloc] initWithFileURL:contentURL
                                                  options:nil
                                       documentAttributes:NULL
                                                    error:NULL];
    _layoutManager = [[NSLayoutManager alloc] init];
    [_textStorage addLayoutManager:_layoutManager];
    
    self.pages = [[NSMutableArray alloc] init];
    pageViewController = [[self childViewControllers] objectAtIndex:0];
}

- (void) viewDidLayoutSubviews
{
    if (!self.isInitialized)
    {
        self.isInitialized = YES;
        [self reflowText];
    }
}

- (void) reflowText
{
    [pageViewController setDataSource:nil];
    [self.pages removeAllObjects];
    [self layoutTextContainers];

    if (self.pages.count > 0)
    {
        [pageViewController setDataSource:self];
        UIViewController *initialViewController = [self viewControllerAtIndex:0];
        NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Page View Controller data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [self.pages indexOfObject:viewController];
    if (index == 0) {
        return nil;
    }
    index--;
    return [self.pages objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [self.pages indexOfObject:viewController];
    index++;
    if (index >= self.pages.count) {
        return nil;
    }
    return [self.pages objectAtIndex:index];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    return [self.pages objectAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    // The number of items reflected in the page indicator.
    return self.pages.count;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    // The selected item reflected in the page indicator.
    return 0;
}


- (UITextView *)getNextColumn
{
    UIView *textView = nil;
    if (self.currentPage != nil)
    {
        if (self.nextColumnTagNumber == 0)
            textView = self.currentPage.column1;
        else if (self.nextColumnTagNumber == 1)
            textView = self.currentPage.column2;
    }
    if (textView == nil)
    {
        if (self.currentPage == nil)
            self.currentPage = [self.storyboard instantiateViewControllerWithIdentifier:@"itemViewPage1"];
        else
            self.currentPage = [self.storyboard instantiateViewControllerWithIdentifier:@"itemViewPageN"];
        [self.currentPage loadView];
        
        if (self.item != nil)
        {
            if (self.currentPage.titleView != nil)
            {
                self.currentPage.titleView.text =  self.item.title;
            }
        }

        // Force some layouting to get correct values
        [self.pageViewController.view addSubview:self.currentPage.view];
        [self.pageViewController.view layoutIfNeeded];
        [self.currentPage.view removeFromSuperview];
        
        self.nextColumnTagNumber = 0;
        [self.pages addObject:self.currentPage];
        return [self getNextColumn];
    }
    self.nextColumnTagNumber += 1;
    return (UITextView *)textView;
}

- (void)layoutTextContainers
{
    self.nextColumnTagNumber = 0;
    self.currentPage = nil;
    while (_layoutManager.textContainers.count > 0)
        [_layoutManager removeTextContainerAtIndex:0];
    
    NSUInteger lastRenderedGlyph = 0;
    while (lastRenderedGlyph < _layoutManager.numberOfGlyphs) {
        
        UITextView *placeholder = [self getNextColumn];

        CGRect textViewFrame = placeholder.frame;
        [placeholder removeFromSuperview];
        CGSize columnSize = CGSizeMake(CGRectGetWidth(textViewFrame),
                                       CGRectGetHeight(textViewFrame));
        
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:columnSize];
        [_layoutManager addTextContainer:textContainer];
        
        // And a text view to render it
        UITextView *textView = [[UITextView alloc] initWithFrame:textViewFrame
                                                   textContainer:textContainer];
        
        textView.scrollEnabled = NO;
        [self.currentPage.view addSubview:textView];
        
        
        // And find the index of the glyph we've just rendered
        lastRenderedGlyph = NSMaxRange([_layoutManager glyphRangeForTextContainer:textContainer]);
    }
}

- (void) setItem:(SCRItem *)item
{
    _item = item;
    if (self.isInitialized)
        [self reflowText];
}

@end
