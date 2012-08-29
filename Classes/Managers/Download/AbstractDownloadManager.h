//
//  AbstractDownloadManager.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 29/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
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

// Is the CMIS Object in the managed downloads queue?
- (BOOL)isManagedDownload:(NSString *)cmisObjectId;

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
