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
//  DownloadProgressBar.h
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest+Utils.h"
#import "DownloadMetadata.h"
#import "RepositoryItem.h"

@class DownloadProgressBar;
@class BaseHTTPRequest;

@protocol DownloadProgressBarDelegate <NSObject>

- (void)download:(DownloadProgressBar *)down completeWithPath:(NSString *)filePath;

@optional
- (void)downloadWasCancelled:(DownloadProgressBar *)down;

@end


// apparently, by convention, you don't retain delegates: 
//   http://www.cocoadev.com/index.pl?DelegationAndNotification

@interface DownloadProgressBar : NSObject <UIAlertViewDelegate, ASIHTTPRequestDelegate, ASIProgressDelegate> 
{
	NSMutableData *fileData;
	NSNumber *totalFileSize;
	UIAlertView *progressAlert;
	UIProgressView *progressView;
	id <DownloadProgressBarDelegate> delegate;
	NSString *filename;
	BOOL isBase64Encoded;
    NSString *cmisObjectId;
    NSString *cmisContentStreamMimeType;
    NSString *versionSeriesId;
    RepositoryItem *repositoryItem;
    BaseHTTPRequest *httpRequest;
    NSInteger tag;
    NSString *selectedAccountUUID;
    NSTimer *graceTimer;
    NSString *tenantID;
}

@property (nonatomic, retain) NSMutableData *fileData;
@property (nonatomic, retain) NSNumber *totalFileSize;
@property (nonatomic, retain) UIAlertView *progressAlert;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, assign) id <DownloadProgressBarDelegate> delegate;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *cmisObjectId;
@property (nonatomic, retain) NSString *cmisContentStreamMimeType;
@property (nonatomic, retain) NSString *versionSeriesId;
@property (nonatomic, retain) RepositoryItem *repositoryItem;
@property (nonatomic, retain) BaseHTTPRequest *httpRequest;
@property (readonly) DownloadMetadata *downloadMetadata;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;

- (void) cancel;
+ (DownloadProgressBar *)createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)filename accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantId;
+ (DownloadProgressBar *)createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)filename contentLength:(NSNumber *)contentLength accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantId;
+ (DownloadProgressBar *)createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)filename contentLength:(NSNumber *)contentLength shouldForceDownload:(BOOL)shouldForceDownload accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantId;

@end
