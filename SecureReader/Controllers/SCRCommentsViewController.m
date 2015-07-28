//
//  SCRCommentsViewController.m
//  SecureReader
//
//  Created by Christopher Ballinger on 7/27/15.
//  Copyright (c) 2015 Guardian Project. All rights reserved.
//

#import "SCRCommentsViewController.h"
#import "JSQMessage.h"
#import "JSQMessagesBubbleImage.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesTimestampFormatter.h"
#import "SCRDatabaseManager.h"
#import "SCRCommentItem.h"
#import "SCRFeed.h"
#import "SCRAppDelegate.h"
#import "RSSPerson.h"
#import "NSString+HTML.h"
#import "SCRSettings.h"
#import "SCRWordpressClient.h"

static NSString * const kSCRCommentsURLFormat = @"http://securereader.guardianproject.info/wordpress/?feed=rss2&p=%@";

@interface SCRCommentsViewController()
@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic, strong) SCRItem *commentsItem;
@property (nonatomic, strong, readonly) JSQMessagesBubbleImage *outBubble;
@property (nonatomic, strong, readonly) JSQMessagesBubbleImage *inBubble;
@property (nonatomic, strong, readonly) SCRWordpressClient *wpClient;

@end

@implementation SCRCommentsViewController

- (NSURL*) commentsURLForPostId:(NSString*)postId {
    NSString *comments = [NSString stringWithFormat:kSCRCommentsURLFormat, postId];
    NSURL *url = [NSURL URLWithString:comments];
    return url;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSParameterAssert([SCRSettings wordpressUsername]);
    NSParameterAssert([SCRSettings wordpressPassword]);
    NSParameterAssert([SCRSettings userNickname]);
    
    self.title = NSLocalizedString(@"Paik Talk", @"title for paik talk comments");
    
    self.senderId = [SCRSettings userNickname];
    self.senderDisplayName = [SCRSettings userNickname];
    JSQMessagesBubbleImageFactory *bf = [[JSQMessagesBubbleImageFactory alloc] init];
    _outBubble = [bf outgoingMessagesBubbleImageWithColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    _inBubble = [bf incomingMessagesBubbleImageWithColor:[UIColor colorWithWhite:0.4 alpha:1.0]];
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    self.inputToolbar.contentView.leftBarButtonItem = nil;
    
    _wpClient = [SCRWordpressClient defaultClient];
    [self.wpClient setUsername:[SCRSettings wordpressUsername] password:[SCRSettings wordpressPassword]];
    
    [self populateComments];
}

- (void) populateComments {
    // populate with fake comments for now
    self.comments = [NSMutableArray array];
    NSParameterAssert(self.postId);
    NSURL *commentsURL = [self commentsURLForPostId:self.postId];
    
    SCRItem *commentsItem = [[SCRItem alloc] init];
    commentsItem.commentsURL = commentsURL;
    self.commentsItem = commentsItem;
    
    [self fetchCommentsFromDatabase];
    
    [[SCRAppDelegate sharedAppDelegate].feedFetcher fetchComments:commentsItem completionQueue:dispatch_get_main_queue() completion:^(NSError *error) {
        if (error) {
            NSLog(@"error fetching comments: %@", error);
            return;
        }
        [self fetchCommentsFromDatabase];
    }];
}

- (void) fetchCommentsFromDatabase {
    dispatch_async(dispatch_get_main_queue(), ^{
        // jankily load the comments one by one
        [self.comments removeAllObjects];
        
        NSString *postIdString = [NSString stringWithFormat:@"p=%@", self.postId];
        [[SCRDatabaseManager sharedInstance].readConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * __nonnull transaction) {
            [transaction enumerateKeysAndObjectsInCollection:[SCRCommentItem yapCollection] usingBlock:^(NSString *key, id object, BOOL *stop) {
                SCRCommentItem *item = object;
                NSURL *commentURL = item.linkURL;
                NSString *parameterString = commentURL.query;
                // this is not the best way to filter but whatever
                if ([parameterString containsString:postIdString]) {
                    RSSPerson *author = item.author;
                    NSString *desc = [item.itemDescription stringByConvertingHTMLToPlainText];
                    if (author.name && item.publicationDate && desc) {
                        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:author.name senderDisplayName:author.name date:item.publicationDate text:desc];
                        [self.comments addObject:message];
                    }
                }
            }];
        } completionBlock:^{
            [self.comments sortUsingComparator:^NSComparisonResult(JSQMessage *message1, JSQMessage *message2) {
                return [message1.date compare:message2.date];
            }];
            [self.collectionView reloadData];
        }];
    });
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    [self.comments addObject:message];
    
    [self finishSendingMessageAnimated:NO];
    
    [self.wpClient postNewCommentForPostId:self.postId parentCommentId:nil body:text author:self.senderDisplayName authorURL:nil authorEmail:nil completionBlock:^(NSString *commentId, NSError *error) {
        
        if (error) {
            NSLog(@"error posting comment: %@", error);
        } else {
            NSLog(@"comment posted to server: %@", commentId);
            NSURL *commentsURL = [self commentsURLForPostId:self.postId];
            NSString *commentIdString = [NSString stringWithFormat:@"#comment-%@", commentId];
            commentsURL = [commentsURL URLByAppendingPathComponent:commentIdString];
            RSSPerson *person = [[RSSPerson alloc] initWithDictionary:@{@"name": self.senderId} error:nil];
            SCRCommentItem *commentItem = [[SCRCommentItem alloc] initWithDictionary:@{@"linkURL": commentsURL,
                                                                                           @"author": person,
                                                                                       @"itemDescription": text,
                                                                                       @"publicationDate": date} error:nil];
            [[SCRDatabaseManager sharedInstance].readWriteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * transaction) {
                [transaction setObject:commentItem forKey:commentItem.yapKey inCollection:[[commentItem class] yapCollection]];
            } completionBlock:^{
                NSLog(@"comment saved to db: %@", commentItem);
                [self populateComments];
            }];
        }
    }];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.comments objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.comments objectAtIndex:indexPath.item];
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outBubble;
    }
    return self.inBubble;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // not showing avatars
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.comments objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.comments objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.comments objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.comments count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.comments objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.comments objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.comments objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

@end
