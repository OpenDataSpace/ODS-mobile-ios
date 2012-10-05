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
//  AbstractDownloadManager.m
//

#import "AbstractDownloadManager.h"

@interface AbstractDownloadManager ()
@property (nonatomic, retain, readwrite) DownloadNetworkQueue *downloadQueue;

@end


@implementation AbstractDownloadManager

@synthesize downloadQueue = _downloadQueue;

#pragma mark - Lifecycle

- (void)dealloc
{
    // This singleton object lives for the entire life of the application, so we don't even attempt to dealloc.
    assert(NO);
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setDownloadQueue:[DownloadNetworkQueue queue]];
        [self.downloadQueue setMaxConcurrentOperationCount:2];
        [self.downloadQueue setDelegate:self];
        [self.downloadQueue setShowAccurateProgress:YES];
        [self.downloadQueue setShouldCancelAllRequestsOnFailure:NO];
        [self.downloadQueue setRequestDidFailSelector:@selector(requestFailed:)];
        [self.downloadQueue setQueueDidFinishSelector:@selector(queueFinished:)];
        [self.downloadQueue setRequestDidStartSelector:@selector(requestStarted:)];
        [self.downloadQueue setRequestDidFinishSelector:@selector(requestFinished:)];
        
        _allDownloads = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}


#pragma mark - Public Methods

- (NSArray *)allDownloads
{
    return [_allDownloads allValues];
}

- (NSArray *)filterDownloadsWithPredicate:(NSPredicate *)predicate
{
    NSArray *allDownloads = [self allDownloads];
    return [allDownloads filteredArrayUsingPredicate:predicate];
}

- (NSArray *)activeDownloads
{
    NSPredicate *activePredicate = [NSPredicate predicateWithFormat:@"downloadStatus == %@ OR downloadStatus == %@", [NSNumber numberWithInt:DownloadInfoStatusActive], [NSNumber numberWithInt:DownloadInfoStatusDownloading]];
    return [self filterDownloadsWithPredicate:activePredicate];
}

- (NSArray *)failedDownloads
{
    NSPredicate *failedPredicate = [NSPredicate predicateWithFormat:@"downloadStatus == %@", [NSNumber numberWithInt:DownloadInfoStatusFailed]];
    return [self filterDownloadsWithPredicate:failedPredicate];
}

- (BOOL)isManagedDownload:(NSString *)cmisObjectId
{
    return [_allDownloads objectForKey:cmisObjectId] != nil;
}

- (BOOL)isDownloading:(NSString *)cmisObjectId
{
    NSArray *activeDownloads = [self activeDownloads];
    
    __block BOOL exists = NO;
    [activeDownloads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
     {
         if ([cmisObjectId isEqualToString:[(DownloadInfo *)obj cmisObjectId]])
         {
             exists = YES;
             *stop = YES;
         }
     }];
    
    return exists;
}

- (DownloadInfo *)managedDownload:(NSString *)cmisObjectId
{
    return [_allDownloads objectForKey:cmisObjectId];
}

- (void)addDownloadToManaged:(DownloadInfo *)downloadInfo
{
    [_allDownloads setObject:downloadInfo forKey:downloadInfo.cmisObjectId];
    
    CMISDownloadFileHTTPRequest *request = [CMISDownloadFileHTTPRequest cmisDownloadRequestWithDownloadInfo:downloadInfo]; 
    [request setCancelledPromptPasswordSelector:@selector(cancelledPasswordPrompt:)];
    [request setPromptPasswordDelegate:self];
    [downloadInfo setDownloadStatus:DownloadInfoStatusActive];
    [downloadInfo setDownloadRequest:request];
    [self.downloadQueue addOperation:request withFileSize:downloadInfo.repositoryItem.contentStreamLength];
}

- (void)queueRepositoryItem:(RepositoryItem *)repositoryItem withAccountUUID:(NSString *)accountUUID andTenantId:(NSString *)tenantId
{
    DownloadInfo *downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:repositoryItem] autorelease];
    [downloadInfo setSelectedAccountUUID:accountUUID];
    [downloadInfo setTenantID:tenantId];
    [self queueDownloadInfo:downloadInfo];
}

- (void)queueRepositoryItems:(NSArray *)repositoryItems withAccountUUID:(NSString *)accountUUID andTenantId:(NSString *)tenantId
{
    for (RepositoryItem *repositoryItem in repositoryItems)
    {
        [self queueRepositoryItem:repositoryItem withAccountUUID:accountUUID andTenantId:tenantId];
    }
}

- (void)queueDownloadInfo:(DownloadInfo *)downloadInfo
{
    if (![self isManagedDownload:downloadInfo.cmisObjectId])
    {
        [self addDownloadToManaged:downloadInfo];
        [self.downloadQueue go];
        
    }
}

- (void)queueDownloadInfoArray:(NSArray *)downloadInfos
{
    for (DownloadInfo *downloadInfo in downloadInfos)
    {
        [self addDownloadToManaged:downloadInfo];
    }
}

- (void)clearDownload:(NSString *)cmisObjectId
{
    DownloadInfo *downloadInfo = [[_allDownloads objectForKey:cmisObjectId] retain];
    [_allDownloads removeObjectForKey:cmisObjectId];
    
    if (downloadInfo.downloadRequest)
    {
        [downloadInfo.downloadRequest clearDelegatesAndCancel];
        CGFloat remainingBytes = [downloadInfo.downloadRequest contentLength] - [downloadInfo.downloadRequest totalBytesRead];
        [self.downloadQueue setTotalBytesToDownload:self.downloadQueue.totalBytesToDownload - remainingBytes];
        
        // If the last request was cancelled, we may not get the queueFinished delegate selector called
        if ([_allDownloads count] == 0)
        {
            [self.downloadQueue cancelAllOperations];
        }
    }
    
    [downloadInfo release];
}

- (void)clearDownloads:(NSArray *)cmisObjectIds
{
    [_allDownloads removeObjectsForKeys:cmisObjectIds];
}

- (void)cancelActiveDownloads
{
    NSArray *activeDownloads = [self activeDownloads];
    for (DownloadInfo *activeDownload in activeDownloads)
    {
        [_allDownloads removeObjectForKey:activeDownload.cmisObjectId];
    }
    
    [_downloadQueue cancelAllOperations];
}

- (void)cancelActiveDownloadsForAccountUUID:(NSString *)accountUUID
{
    [self.downloadQueue setSuspended:YES];
    NSArray *activeDownloads = [self activeDownloads];
    for (DownloadInfo *activeDownload in activeDownloads)
    {
        if ([activeDownload.selectedAccountUUID isEqualToString:accountUUID])
        {
            [activeDownload.downloadRequest cancel];
            [_allDownloads removeObjectForKey:activeDownload.cmisObjectId];
        }
    }
    
    [self.downloadQueue setSuspended:NO];
}


- (BOOL)retryDownload:(NSString *)cmisObjectId
{
    DownloadInfo *downloadInfo = [_allDownloads objectForKey:cmisObjectId];
    if (downloadInfo)
    {
        [self clearDownload:downloadInfo.cmisObjectId];
        [self queueDownloadInfo:downloadInfo];
        return YES;
    }
    return NO;
}

- (void)setQueueProgressDelegate:(id<ASIProgressDelegate>)progressDelegate
{
    [_downloadQueue setDownloadProgressDelegate:progressDelegate];
}

#pragma mark - ASINetworkQueueDelegateMethod

- (void)requestStarted:(CMISDownloadFileHTTPRequest *)request
{
    DownloadInfo *downloadInfo = request.downloadInfo;
    [downloadInfo setDownloadStatus:DownloadInfoStatusDownloading];
}

- (void)requestFinished:(CMISDownloadFileHTTPRequest *)request 
{
    DownloadInfo *downloadInfo = request.downloadInfo;
    [downloadInfo setDownloadRequest:nil];
    
    // Check whether ASI used a cached response
    if (request.didUseCachedResponse)
    {
        // Copy the file from cache to the temp directory
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:downloadInfo.repositoryItem.title];
        
        [fileManager removeItemAtPath:tempPath error:nil];
        [fileManager copyItemAtPath:request.downloadDestinationPath toPath:tempPath error:&error];
        [request setDownloadDestinationPath:tempPath];
    }
    
}

- (void)requestFailed:(CMISDownloadFileHTTPRequest *)request 
{
    // Do something different with the error if there's no connection available?
    if (([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
    }
    
    DownloadInfo *downloadInfo = request.downloadInfo;
    [downloadInfo setDownloadRequest:nil];
    [self failedDownload:downloadInfo withError:request.error];
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    [self.downloadQueue cancelAllOperations];
}

#pragma mark - Private Methods

- (void)successDownload:(DownloadInfo *)downloadInfo
{
    [downloadInfo setDownloadStatus:DownloadInfoStatusDownloaded];
    
    // We don't manage successful downloads
    [_allDownloads removeObjectForKey:downloadInfo.cmisObjectId];
    
}
- (void)failedDownload:(DownloadInfo *)downloadInfo withError:(NSError *)error
{
    _GTMDevLog(@"Download Failed for file %@ and cmisObjectId %@ with error: %@", downloadInfo.repositoryItem.title, downloadInfo.cmisObjectId, error);
    [downloadInfo setDownloadStatus:DownloadInfoStatusFailed];
    [downloadInfo setError:error];
}

#pragma mark - PasswordPromptQueue callbacks

- (void)cancelledPasswordPrompt:(CMISDownloadFileHTTPRequest *)request
{
    [self cancelActiveDownloadsForAccountUUID:request.accountUUID];
}

@end

