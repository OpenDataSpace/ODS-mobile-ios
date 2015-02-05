/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  DeleteQueueProgressBar.h
//

#import <Foundation/Foundation.h>
#import "ASIProgressDelegate.h"
@class DeleteQueueProgressBar;
@class ASINetworkQueue;

@protocol DeleteQueueDelegate <NSObject>

- (void)deleteQueue:(DeleteQueueProgressBar *)deleteQueueProgressBar completedDeletes:(NSArray *)deletedItems;

@optional
- (void)deleteQueueWasCancelled:(DeleteQueueProgressBar *)deleteQueueProgressBar;

@end

@interface DeleteQueueProgressBar : NSObject <UIAlertViewDelegate, ASIProgressDelegate>
{
    ASINetworkQueue *_requestQueue;
    NSArray *_itemsToDelete;
    id<DeleteQueueDelegate> _delegate;
    
    UIAlertView *_progressAlert;
    UIProgressView *_progressView;
    NSMutableArray *_deletedItems;
    NSString *_selectedUUID;
    NSString *_tenantID;
}
@property (nonatomic, retain) UIView *containerView;
@property (nonatomic, retain) ASINetworkQueue *requestQueue;
@property (nonatomic, retain) NSArray *itemsToDelete;
@property (nonatomic, retain) UIAlertView *progressAlert;
@property (nonatomic, assign) id<DeleteQueueDelegate> delegate;
@property (nonatomic, copy) NSString *progressTitle;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, copy) NSString *selectedUUID;
@property (nonatomic, copy) NSString *tenantID;

- (void)startDeleting;
- (void)cancel;
+ (DeleteQueueProgressBar *)createWithItems:(NSArray*)itemsToDelete delegate:(id <DeleteQueueDelegate>)del andMessage:(NSString *)message;

@end
