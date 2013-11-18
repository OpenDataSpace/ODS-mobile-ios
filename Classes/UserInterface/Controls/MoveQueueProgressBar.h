//
//  MoveQueueProgressBar.h
//  FreshDocs
//
//  Created by bdt on 11/14/13.
//
//

#import <Foundation/Foundation.h>
#import "ASIProgressDelegate.h"
@class MoveQueueProgressBar;
@class ASINetworkQueue;
@class RepositoryItem;

@protocol MoveQueueDelegate <NSObject>

- (void)moveQueue:(MoveQueueProgressBar *)moveQueueProgressBar completedMoves:(NSArray *)movedItems;

@optional
- (void)moveQueueWasCancelled:(MoveQueueProgressBar *)moveQueueProgressBar;

@end

@interface MoveQueueProgressBar : NSObject <UIAlertViewDelegate, ASIProgressDelegate>

@property (nonatomic, strong) ASINetworkQueue *requestQueue;
@property (nonatomic, strong) NSArray *itemsToMove;
@property (nonatomic, strong) UIAlertView *progressAlert;
@property (nonatomic, assign) id<MoveQueueDelegate> delegate;
@property (nonatomic, copy) NSString *progressTitle;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, copy) NSString *selectedUUID;
@property (nonatomic, copy) NSString *tenantID;
@property (nonatomic, strong) RepositoryItem *targetFolder;
@property (nonatomic, copy) NSString *sourceFolderId;

- (void)startMoving;
- (void)cancel;
+ (MoveQueueProgressBar *)createWithItems:(NSArray*)itemsToMove targetFolder:(RepositoryItem*)targetFolder delegate:(id <MoveQueueDelegate>)del andMessage:(NSString *)message;
@end
