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
//  AbstractDownloadManager.h
//

#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"
#import "ASIProgressDelegate.h"
#import "DownloadNetworkQueue.h"
#import "DownloadInfo.h"
#import "DownloadMetadata.h"
#import "CMISDownloadFileHTTPRequest.h"
#import "RepositoryItem.h"

@class DownloadInfo;
@class DownloadNetworkQueue;
@class RepositoryItem;

@interface AbstractDownloadManager : NSObject <ASIHTTPRequestDelegate>
{
    NSMutableDictionary *_allDownloads;
}

@property (nonatomic, retain, readonly) DownloadNetworkQueue *downloadQueue;

// Returns all the current downloads managed by this object
- (NSArray *)allDownloads;

// Returns all the active downloads managed by this object
- (NSArray *)activeDownloads;

// Returns all the failed downloads managed by this object
- (NSArray *)failedDownloads;
- (BOOL)isFailedDownload:(NSString *)cmisObjectId;

// Is the CMIS Object in the managed downloads queue?
- (BOOL)isManagedDownload:(NSString *)cmisObjectId;
- (BOOL)isDownloading:(NSString *)cmisObjectId;

// Return a managed download
- (DownloadInfo *)managedDownload:(NSString *)cmisObjectId;

// Queue a RepositoryItem
- (void)queueRepositoryItem:(RepositoryItem *)repositoryItem withAccountUUID:(NSString *)accountUUID andTenantId:(NSString *)tenantId;

// Queue multiple RepositoryItems
- (void)queueRepositoryItems:(NSArray *)repositoryItems withAccountUUID:(NSString *)accountUUID andTenantId:(NSString *)tenantId;

// Queue a single download
- (void)queueDownloadInfo:(DownloadInfo *)downloadInfo;

// Queue multiple downloads
- (void)queueDownloadInfoArray:(NSArray *)downloadInfos;

- (void)queueFinished:(ASINetworkQueue *)queue;

// Remove a download
- (void)clearDownload:(NSString *)cmisObjectId;

// Remove multiple downloads
- (void)clearDownloads:(NSArray *)cmisObjectIds;

// Stop all active downloads
- (void)cancelActiveDownloads;

- (void)cancelActiveDownloadsForAccountUUID:(NSString *)accountUUID;

// Retry a download
- (BOOL)retryDownload:(NSString *)cmisObjectId;

- (void)successDownload:(DownloadInfo *)downloadInfo;
- (void)failedDownload:(DownloadInfo *)downloadInfo withError:(NSError *)error;

// Download summary progress delegate
- (void)setQueueProgressDelegate:(id<ASIProgressDelegate>)progressDelegate;

@end
