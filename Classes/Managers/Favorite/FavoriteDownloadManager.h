//
//  FavoriteDownloadManager.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 03/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"
#import "ASIProgressDelegate.h"

@class DownloadInfo;
@class DownloadNetworkQueue;
@class RepositoryItem;

@interface FavoriteDownloadManager : NSObject <ASIHTTPRequestDelegate>
{
    NSMutableDictionary *_allDownloads;
}

@property (nonatomic, retain, readonly) DownloadNetworkQueue *downloadQueue;

@property (nonatomic, retain) NSMutableDictionary * progressBarsForRequests;
- (void)setProgressIndicator:(id)progressIndicator forObjectId:(NSString*)cmisObjectId;

- (float)currentProgressForObjectId:(NSString*) cmisObjectId;

// Static selector to access DownloadManager singleton
+ (FavoriteDownloadManager *)sharedManager;

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

// Remove a download
- (void)clearDownload:(NSString *)cmisObjectId;

// Remove multiple downloads
- (void)clearDownloads:(NSArray *)cmisObjectIds;

// Stop all active downloads
- (void)cancelActiveDownloads;

// Retry a download
- (BOOL)retryDownload:(NSString *)cmisObjectId;

// Download summary progress delegate
- (void)setQueueProgressDelegate:(id<ASIProgressDelegate>)progressDelegate;

@end

