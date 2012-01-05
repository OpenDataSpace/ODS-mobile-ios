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
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  DowloadQueueProgressBar.h
//

#import <Foundation/Foundation.h>
#import "ASIProgressDelegate.h"
@class DownloadQueueProgressBar;
@class ASINetworkQueue;

@protocol DownloadQueueDelegate <NSObject>

- (void)downloadQueue:(DownloadQueueProgressBar *)down completeDownloads:(NSArray *)downloads;

@optional
- (void)downloadQueueWasCancelled:(DownloadQueueProgressBar *)down;

@end

@interface DownloadQueueProgressBar : NSObject <UIAlertViewDelegate, ASIProgressDelegate> {
    ASINetworkQueue *_requestQueue;
    NSArray *_nodesToDowload;
    id<DownloadQueueDelegate> _delegate;
    
    UIAlertView *_progressAlert;
    UIProgressView *_progressView;
    NSMutableArray *_downloadedInfo;
    NSString *_selectedUUID;
    NSString *_tenantID;
}

@property (nonatomic, retain) ASINetworkQueue *requestQueue;
@property (nonatomic, retain) NSArray *nodesToDownload;
@property (nonatomic, retain) UIAlertView *progressAlert;
@property (nonatomic, assign) id<DownloadQueueDelegate> delegate;
@property (nonatomic, readonly) NSArray *downloadedInfo;
@property (nonatomic, copy) NSString *progressTitle;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, copy) NSString *selectedUUID;
@property (nonatomic, copy) NSString *tenantID;

- (void)startDownloads;
- (void)cancel;
+ (DownloadQueueProgressBar *)createWithNodes:(NSArray*)nodesToDownload delegate:(id <DownloadQueueDelegate>)del andMessage: (NSString *) mesage;

@end
