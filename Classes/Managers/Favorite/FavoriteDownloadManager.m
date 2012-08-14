//
//  FavoriteDownloadManager.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 03/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "FavoriteDownloadManager.h"
#import "DownloadNetworkQueue.h"
#import "DownloadInfo.h"
#import "DownloadMetadata.h"
#import "CMISDownloadFileHTTPRequest.h"
#import "FavoriteFileDownloadManager.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "RepositoryItem.h"

unsigned int const Favorite_FILE_SUFFIX_MAX = 1000;

@interface FavoriteDownloadManager ()
@property (nonatomic, retain, readwrite) DownloadNetworkQueue *downloadQueue;
@end

@implementation FavoriteDownloadManager
@synthesize downloadQueue = _downloadQueue;
@synthesize progressBarsForRequests = _progressBarsForRequests;

#pragma mark - Shared Instance

+ (FavoriteDownloadManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

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
        _progressBarsForRequests = [[NSMutableDictionary alloc] init];
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
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
        
        NSLog(@"Download Info: %@", userInfo);
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:userInfo];
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
    
    [downloadInfo autorelease];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:userInfo];
}

- (void)clearDownloads:(NSArray *)cmisObjectIds
{
    if ([[cmisObjectIds lastObject] isKindOfClass:[NSString class]])
    {
        [_allDownloads removeObjectsForKeys:cmisObjectIds];
        
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:nil];
    }
}

- (void)cancelActiveDownloads
{
    NSArray *activeDownloads = [self activeDownloads];
    for (DownloadInfo *activeDownload in activeDownloads)
    {
        [_allDownloads removeObjectForKey:activeDownload.cmisObjectId];
    }
    
    [_downloadQueue cancelAllOperations];
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:nil];
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
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:nil];
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
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadStartedNotificationWithUserInfo:userInfo];
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
    
    //unsigned int suffix = 0;
    NSMutableString *filename = [NSMutableString stringWithString:downloadInfo.repositoryItem.title];
    
    [[FavoriteFileDownloadManager sharedInstance] setDownload:downloadInfo.downloadMetadata.downloadInfo forKey:filename withFilePath:[request.downloadDestinationPath lastPathComponent]];
    
    _GTMDevLog(@"Successful download for file %@ with cmisObjectId %@", downloadInfo.repositoryItem.title, downloadInfo.cmisObjectId);
    
    [self successDownload:downloadInfo];
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
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:nil];
    [self.downloadQueue cancelAllOperations];
}

#pragma mark - Private Methods

- (void)successDownload:(DownloadInfo *)downloadInfo
{
    if ([_allDownloads objectForKey:downloadInfo.cmisObjectId])
    {
        [downloadInfo setDownloadStatus:DownloadInfoStatusDownloaded];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadFinishedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:userInfo];
        
        // We don't manage successfull downloads
        [_allDownloads removeObjectForKey:downloadInfo.cmisObjectId];
    }
    else
    {
        _GTMDevLog(@"The success download %@ is no longer managed by the DownloadManager, ignoring", downloadInfo.repositoryItem.title);
    }
}
- (void)failedDownload:(DownloadInfo *)downloadInfo withError:(NSError *)error
{
    if ([_allDownloads objectForKey:downloadInfo.cmisObjectId])
    {
        _GTMDevLog(@"Download Failed for file %@ and cmisObjectId %@ with error: %@", downloadInfo.repositoryItem.title, downloadInfo.cmisObjectId, error);
        [downloadInfo setDownloadStatus:DownloadInfoStatusFailed];
        [downloadInfo setError:error];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", error, @"downloadError", nil];
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadFailedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:userInfo];
    }
    else 
    {
        _GTMDevLog(@"The failed download %@ is no longer managed by the DownloadManager, ignoring", downloadInfo.repositoryItem.title);
    }
}

#pragma mark - PasswordPromptQueue callbacks

- (void)cancelledPasswordPrompt:(CMISDownloadFileHTTPRequest *)request
{
    [self cancelActiveDownloadsForAccountUUID:request.accountUUID];
}

#pragma mark - Progress Delegates

- (void)setProgressIndicator:(id)progressIndicator forObjectId:(NSString*)cmisObjectId
{
    if (progressIndicator) {
        
    [self.progressBarsForRequests setObject:progressIndicator forKey:cmisObjectId];  
        
    }
    
    DownloadInfo *downloadInfo = [[_allDownloads objectForKey:cmisObjectId] retain];
    
    if (downloadInfo.downloadRequest)
    {
        
        [downloadInfo.downloadRequest setDownloadProgressDelegate:progressIndicator];
    }
    
    [downloadInfo autorelease];
}

- (float)currentProgressForObjectId:(NSString*) cmisObjectId
{
    DownloadInfo *downloadInfo = [[_allDownloads objectForKey:cmisObjectId] retain];

    float progressAmount = 0;
    
    if (downloadInfo.downloadRequest)
    {
        CGFloat remainingBytes = [downloadInfo.downloadRequest contentLength] - [downloadInfo.downloadRequest totalBytesRead];
        [self.downloadQueue setTotalBytesToDownload:self.downloadQueue.totalBytesToDownload - remainingBytes];
        
        
        
        if (downloadInfo.downloadStatus == DownloadInfoStatusDownloading)
        {
            CMISDownloadFileHTTPRequest *request = downloadInfo.downloadRequest;
            if (request.contentLength + request.totalBytesRead > 0)
            {
                progressAmount = (float)(((request.totalBytesRead + request.partialDownloadSize) * 1.0) / ((request.contentLength + request.partialDownloadSize) * 1.0));
            }
        }
        
    }

    
    return MIN(0, progressAmount);
    
}


@end
