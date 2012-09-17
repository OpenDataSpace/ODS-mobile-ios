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
//  FavoriteDownloadManager.m
//

#import "FavoriteDownloadManager.h"
#import "FavoriteFileDownloadManager.h"
#import "NSNotificationCenter+CustomNotification.h"

@interface FavoriteDownloadManager ()
@property (nonatomic, retain, readwrite) DownloadNetworkQueue *downloadQueue;
@end


@implementation FavoriteDownloadManager
@synthesize progressBarsForRequests = _progressBarsForRequests;
@synthesize downloadQueue;

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

- (void)queueDownloadInfo:(DownloadInfo *)downloadInfo
{
    if (![self isManagedDownload:downloadInfo.cmisObjectId])
    {
        [super queueDownloadInfo:downloadInfo];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
#if MOBILE_DEBUG
        NSLog(@"Download Info: %@", userInfo);
#endif
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:userInfo];
    }
}

- (void)clearDownload:(NSString *)cmisObjectId
{
    DownloadInfo *downloadInfo = [[_allDownloads objectForKey:cmisObjectId] retain];
    
    [super clearDownload:cmisObjectId];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadCancelledNotificationWithUserInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:userInfo];
    
    [downloadInfo release];
}

- (void)clearDownloads:(NSArray *)cmisObjectIds
{
    if ([[cmisObjectIds lastObject] isKindOfClass:[NSString class]])
    {
        [super clearDownloads:cmisObjectIds];
        
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:nil];
    }
}

- (void)cancelActiveDownloads
{
    [super cancelActiveDownloads];
    
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:nil];
}

- (void)cancelActiveDownloadsForAccountUUID:(NSString *)accountUUID
{
    [super cancelActiveDownloadsForAccountUUID:accountUUID];
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:nil];
}

#pragma mark - ASINetworkQueueDelegateMethod

- (void)requestStarted:(CMISDownloadFileHTTPRequest *)request
{
    DownloadInfo *downloadInfo = request.downloadInfo;
    
    [super requestStarted:request];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadStartedNotificationWithUserInfo:userInfo];
}

- (void)requestFinished:(CMISDownloadFileHTTPRequest *)request 
{
    DownloadInfo *downloadInfo = request.downloadInfo;
    
    [super requestFinished:request];
    
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    NSString *filename = [fileManager generatedNameForFile:downloadInfo.repositoryItem.title withObjectID:downloadInfo.repositoryItem.guid];
    
    [fileManager setDownload:downloadInfo.downloadMetadata.downloadInfo forKey:filename withFilePath:[request.downloadDestinationPath lastPathComponent]];
    
    _GTMDevLog(@"Successful download for file %@ with cmisObjectId %@", downloadInfo.repositoryItem.title, downloadInfo.cmisObjectId);
    
    [self successDownload:downloadInfo];
    
}

- (void)requestFailed:(CMISDownloadFileHTTPRequest *)request 
{
    [super requestFailed:request];
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    [super queueFinished:queue];
    
    [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:nil];
}

- (void)setQueueProgressDelegate:(id<ASIProgressDelegate>)progressDelegate
{
    [self.downloadQueue setDownloadProgressDelegate:progressDelegate];
}

#pragma mark - Private Methods

- (void)successDownload:(DownloadInfo *)downloadInfo
{
    if ([_allDownloads objectForKey:downloadInfo.cmisObjectId])
    {
        [super successDownload:downloadInfo];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadFinishedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:userInfo];
        
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
        [super failedDownload:downloadInfo withError:error];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", error, @"downloadError", nil];
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadFailedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postFavoriteDownloadQueueChangedNotificationWithUserInfo:userInfo];
    }
    else 
    {
        _GTMDevLog(@"The failed download %@ is no longer managed by the DownloadManager, ignoring", downloadInfo.repositoryItem.title);
    }
}

#pragma mark - Progress Delegates

- (void)setProgressIndicator:(id)progressIndicator forObjectId:(NSString*)cmisObjectId
{
    if (progressIndicator)
    {
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
    DownloadInfo *downloadInfo = [_allDownloads objectForKey:cmisObjectId];
    
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
