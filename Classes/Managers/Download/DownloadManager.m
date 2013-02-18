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
#import "FileDownloadManager.h"
#import "NSNotificationCenter+CustomNotification.h"

@implementation DownloadManager

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

- (void)queueDownloadInfo:(DownloadInfo *)downloadInfo
{
    if (![self isManagedDownload:downloadInfo.cmisObjectId])
    {
        [super queueDownloadInfo:downloadInfo];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
        AlfrescoLogTrace(@"Download Info: %@", userInfo);

        [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:userInfo];
    }
}

- (void)clearDownload:(NSString *)cmisObjectId
{
    DownloadInfo *downloadInfo = [_allDownloads objectForKey:cmisObjectId];
    
    [super clearDownload:cmisObjectId];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
    [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:userInfo];
}

- (void)clearDownloads:(NSArray *)cmisObjectIds
{
    if ([[cmisObjectIds lastObject] isKindOfClass:[NSString class]])
    {
        [super clearDownloads:cmisObjectIds];
        
        [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:nil];
    }
}

- (void)cancelActiveDownloads
{
    [super cancelActiveDownloads];
    
    [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:nil];
}

- (void)cancelActiveDownloadsForAccountUUID:(NSString *)accountUUID
{
    [super cancelActiveDownloadsForAccountUUID:accountUUID];
    [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:nil];
}

#pragma mark - ASINetworkQueueDelegateMethod

- (void)requestStarted:(CMISDownloadFileHTTPRequest *)request
{
    [super requestStarted:request];
    DownloadInfo *downloadInfo = request.downloadInfo;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
    [[NSNotificationCenter defaultCenter] postDownloadStartedNotificationWithUserInfo:userInfo];
}

- (void)requestFinished:(CMISDownloadFileHTTPRequest *)request 
{
    DownloadInfo *downloadInfo = request.downloadInfo;
    
    [super requestFinished:request];
    
    // We'll bail out after kFileSuffixMaxAttempts attempts
    FileDownloadManager *manager = [FileDownloadManager sharedInstance];
    unsigned int suffix = 0;
    NSMutableString *filename = [NSMutableString stringWithString:downloadInfo.repositoryItem.title];
    NSString *filenameWithoutExtension = [filename.lastPathComponent stringByDeletingPathExtension];
    NSString *fileExtension = [filename pathExtension];
    while ([manager downloadExistsForKey:filename] && (++suffix < kFileSuffixMaxAttempts))
    {
        if (fileExtension == nil || [fileExtension isEqualToString:@""])
        {
            filename = [NSMutableString stringWithFormat:@"%@-%u", filenameWithoutExtension, suffix];
        }
        else
        {
            filename = [NSMutableString stringWithFormat:@"%@-%u.%@", filenameWithoutExtension, suffix, fileExtension];
        }
    }
    
    // Did we hit the max suffix number?
    if (suffix == kFileSuffixMaxAttempts)
    {
        NSLog(@"ERROR: Couldn't save downloaded file as kFileSuffixMaxAttempts (%u) reached", kFileSuffixMaxAttempts);
        return [self requestFailed:request];
    }
    
    [[FileDownloadManager sharedInstance] setDownload:downloadInfo.downloadMetadata.downloadInfo forKey:filename withFilePath:[request.downloadDestinationPath lastPathComponent]];

    AlfrescoLogTrace(@"Successful download for file %@ with cmisObjectId %@", downloadInfo.repositoryItem.title, downloadInfo.cmisObjectId);

    [self successDownload:downloadInfo];
}

- (void)requestFailed:(CMISDownloadFileHTTPRequest *)request 
{
    [super requestFailed:request];
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    [super queueFinished:queue];
    
    [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:nil];

}

#pragma mark - Private Methods

- (void)successDownload:(DownloadInfo *)downloadInfo
{
    if ([_allDownloads objectForKey:downloadInfo.cmisObjectId])
    {
        [super successDownload:downloadInfo];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", nil];
        [[NSNotificationCenter defaultCenter] postDownloadFinishedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:userInfo];
        
    }
    else
    {
        AlfrescoLogTrace(@"The success download %@ is no longer managed by the DownloadManager, ignoring", downloadInfo.repositoryItem.title);
    }
}
- (void)failedDownload:(DownloadInfo *)downloadInfo withError:(NSError *)error
{
    if ([_allDownloads objectForKey:downloadInfo.cmisObjectId])
    {
        [super failedDownload:downloadInfo withError:error];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:downloadInfo, @"downloadInfo", downloadInfo.cmisObjectId, @"downloadObjectId", error, @"downloadError", nil];
        [[NSNotificationCenter defaultCenter] postDownloadFailedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postDownloadQueueChangedNotificationWithUserInfo:userInfo];
    }
    else 
    {
        AlfrescoLogTrace(@"The failed download %@ is no longer managed by the DownloadManager, ignoring", downloadInfo.repositoryItem.title);
    }
}

@end
