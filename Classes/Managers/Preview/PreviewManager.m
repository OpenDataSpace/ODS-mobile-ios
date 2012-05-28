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
//  PreviewManager.m
//

#import "PreviewManager.h"
#import "DownloadManager.h"
#import "AccountManager.h"
#import "ASIHTTPRequest.h"
#import "BaseHTTPRequest.h"
#import "FileProtectionManager.h"
#import "FileUtils.h"


@interface PreviewManager ()
@property (nonatomic, retain) DownloadInfo *currentDownload;
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain, readwrite) NSString *lastPreviewedGuid;
@end

@implementation PreviewManager

@synthesize delegate = _delegate;
@synthesize currentDownload = _currentDownload;
@synthesize queue = _queue;
@synthesize lastPreviewedGuid = _lastPreviewedGuid;


#pragma mark - Shared Instance

static PreviewManager *sharedPreviewManager = nil;

+ (PreviewManager *)sharedManager
{
    if (sharedPreviewManager == nil)
    {
        sharedPreviewManager = [[PreviewManager alloc] init];
    }
    return sharedPreviewManager;
}

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [self setQueue:queue];
        [queue release];
    }
    
    return self;
}

- (void)dealloc
{
    // This object lives for the entire life of the application, so we don't even attempt to dealloc.
    assert(NO);
    [super dealloc];
}


#pragma mark - Public Methods

- (DownloadInfo *)downloadInfoForItem:(RepositoryItem *)item
{
    // Check if the item is currently being downloaded by the DownloadManager
    DownloadInfo *downloadInfo = [[DownloadManager sharedManager] downloadInfoForItem:item];
    
    // TODO: Something!
    return downloadInfo;
}

- (void)previewItem:(RepositoryItem *)item delegate:(id<PreviewManagerDelegate>)aDelegate accountUUID:(NSString *)anAccountUUID tenantID:(NSString *)aTenantID
{
    NSURL *url = [NSURL URLWithString:item.contentLocation];
    NSString *tempPath = [FileUtils pathToTempFile:item.title];
    
    DownloadInfo *downloadInfo = [[DownloadInfo alloc] initWithRepositoryItem:item];
    [downloadInfo setDownloadDestinationPath:tempPath];
    [downloadInfo setSelectedAccountUUID:anAccountUUID];
    [downloadInfo setTenantID:aTenantID];
    
    [self setCurrentDownload:downloadInfo];
    [downloadInfo release];
    
    [self setDelegate:aDelegate];
    
    BaseHTTPRequest *request = [BaseHTTPRequest requestWithURL:url accountUUID:anAccountUUID];
    [request setDelegate:self];
    [request setShowAccurateProgress:YES];
    [request setDownloadProgressDelegate:self];
    [request setDownloadDestinationPath:tempPath];
    [request setTenantID:aTenantID];

    [[self queue] addOperation:request];
}

- (void)cancelDownload
{
    [[self queue] cancelAllOperations];
}

#pragma mark - ASINetworkQueue Delegate

- (void)requestStarted:(ASIHTTPRequest *)request
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(previewManager:willStartDownloading:toPath:)])
    {
        [self.delegate previewManager:self willStartDownloading:self.currentDownload toPath:request.downloadDestinationPath];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:request.downloadDestinationPath];
    [self.currentDownload setDownloadStatus:DownloadInfoStatusDownloaded];
    [self setLastPreviewedGuid:self.currentDownload.repositoryItem.guid];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(previewManager:didFinishDownloading:toPath:)])
    {
        [self.delegate previewManager:self didFinishDownloading:self.currentDownload toPath:request.downloadDestinationPath];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self.currentDownload setDownloadStatus:DownloadInfoStatusFailed];
}

#pragma mark - ASIProgressDelegate

- (void)setProgress:(float)newProgress
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(previewManager:downloadProgress:withProgress:)])
    {
        [self.delegate previewManager:self downloadProgress:self.currentDownload withProgress:newProgress];
    }
}

@end
