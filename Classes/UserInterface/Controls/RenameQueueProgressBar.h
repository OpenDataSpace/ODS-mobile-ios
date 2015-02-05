//
//  RenameQueueProgressBar.h
//  FreshDocs
//
//  Created by bdt on 11/8/13.
//
//

#import <Foundation/Foundation.h>
#import "ASIProgressDelegate.h"
@class RenameQueueProgressBar;
@class ASINetworkQueue;

@protocol RenameQueueDelegate <NSObject>

- (void)renameQueue:(RenameQueueProgressBar *)renameQueueProgressBar completedRename:(id)renamedItem;

@optional
- (void)renameQueueWasCancelled:(RenameQueueProgressBar *)renameQueueProgressBar;

@end

@interface RenameQueueProgressBar : NSObject <UIAlertViewDelegate, ASIProgressDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) ASINetworkQueue *requestQueue;
@property (nonatomic, strong) NSDictionary *itemToRename;
@property (nonatomic, strong) UIAlertView *progressAlert;
@property (nonatomic, assign) id<RenameQueueDelegate> delegate;
@property (nonatomic, copy) NSString *progressTitle;
@property (nonatomic, strong) UIActivityIndicatorView *progressView;
@property (nonatomic, copy) NSString *selectedUUID;
@property (nonatomic, copy) NSString *tenantID;

- (void)startRenaming;
- (void)cancel;
+ (RenameQueueProgressBar *)createWithItem:(NSDictionary*) itemInfo delegate:(id <RenameQueueDelegate>)del andMessage:(NSString *)message;

@end
