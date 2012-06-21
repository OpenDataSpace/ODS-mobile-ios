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
//  DownloadManager.m
//

#import "DownloadManager.h"
#import "DownloadNetworkQueue.h"
#import "DownloadInfo.h"
#import "DownloadMetadata.h"
#import "CMISDownloadFileHTTPRequest.h"
#import "FileDownloadManager.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "RepositoryItem.h"

unsigned int const FILE_SUFFIX_MAX = 1000;

@interface DownloadManager ()
@property (nonatomic, retain, readwrite) DownloadNetworkQueue *downloadQueue;
@end

@implementation DownloadManager

@synthesize downloadQueue = _downloadQueue;

#pragma mark - Shared Instance

+ (DownloadManager *)sharedManager
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
        [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:userInfo];
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
    [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:userInfo];
}

- (void)clearDownloads:(NSArray *)cmisObjectIds
{
    if ([[cmisObjectIds lastObject] isKindOfClass:[NSString class]])
    {
        [_allDownloads removeObjectsForKeys:cmisObjectIds];
        
        [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:nil];
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
    [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:nil];
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
    [[NSNotificationCenter defaultCenter] postDownloadStartedNotificationWithUserInfo:userInfo];
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
    
    // We'll bail out after FILE_SUFFIX_MAX attempts
    FileDownloadManager *manager = [FileDownloadManager sharedInstance];
    unsigned int suffix = 0;
    NSMutableString *filename = [NSMutableString stringWithString:downloadInfo.repositoryItem.title];
    NSString *filenameWithoutExtension = [filename.lastPathComponent stringByDeletingPathExtension];
    NSString *fileExtension = [filename pathExtension];
    while ([manager downloadExistsForKey:filename] && (++suffix < FILE_SUFFIX_MAX))
    {
        filename = [NSMutableString stringWithFormat:@"%@-%u.%@", filenameWithoutExtension, suffix, fileExtension];
    }
    
    // Did we hit the max suffix number?
    if (suffix == FILE_SUFFIX_MAX)
    {
        NSLog(@"ERROR: Couldn't save downloaded file as FILE_SUFFIX_MAX (%u) reached", FILE_SUFFIX_MAX);
        return [self requestFailed:request];
    }
    
    [[FileDownloadManager sharedInstance] setDownload:downloadInfo.downloadMetadata.downloadInfo forKey:filename withFilePath:[request.downloadDestinationPath lastPathComponent]];

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
    [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:nil];
    [self.downloadQueue cancelAllOperations];
}

#pragma mark - Private Methods

- (void)successDownload:(DownloadInfo *)downloadInfo
{
    if ([_allDownloads objectForKey:downloadInfo.cmisObjectId])
    {
        [downloadInfo setDownloadStatus:DownloadInfoStatusDownloaded];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
        [[NSNotificationCenter defaultCenter] postDownloadFinishedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:userInfo];
        
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
        [[NSNotificationCenter defaultCenter] postDownloadFailedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:userInfo];
    }
    else 
    {
        _GTMDevLog(@"The failed download %@ is no longer managed by the DownloadManager, ignoring", downloadInfo.repositoryItem.title);
    }
}

@end
