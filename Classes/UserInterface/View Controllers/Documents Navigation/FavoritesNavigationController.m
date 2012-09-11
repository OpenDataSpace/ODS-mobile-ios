//
//  FavoritesNavigationController.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 07/09/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "FavoritesNavigationController.h"
#import "FavoritesUploadManager.h"
#import "FavoriteDownloadManager.h"
#import "FavoriteFailedItemsViewController.h"

@interface FavoritesNavigationController ()

@property (nonatomic) NSInteger activeUploadsCount;
@property (nonatomic) NSInteger activeDownloadsCount;

@property (nonatomic) NSInteger failedUploadsCount;
@property (nonatomic) NSInteger failedDownloadsCount;

@end

@implementation FavoritesNavigationController
@synthesize activeDownloadsCount = _activeDownloadsCount;
@synthesize activeUploadsCount = _activeUploadsCount;
@synthesize failedUploadsCount = _failedUploadsCount;
@synthesize failedDownloadsCount = _failedDownloadsCount;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadQueueChanged:) name:kNotificationFavoriteUploadQueueChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationFavoriteDownloadQueueChanged object:nil];
        
    }
    return self;
}


#pragma mark - ASIProgressDelegate
- (void)setProgress:(float)newProgress
{
    FavoritesUploadManager *uploadManager = [FavoritesUploadManager sharedManager];
    NSInteger uploadCount = [[[FavoritesUploadManager sharedManager] activeUploads] count];
    
    FavoriteDownloadManager * downloadManager = [FavoriteDownloadManager sharedManager];
    NSInteger downloadCount = [[[FavoriteDownloadManager sharedManager] activeDownloads] count];
    
    NSInteger totalCount = uploadCount + downloadCount;
    
    float uploadBytesLeft = uploadManager.uploadsQueue.totalBytesToUpload;
    float downloadBytesLeft = downloadManager.downloadQueue.totalBytesToDownload;
    float uploadedBytes = uploadManager.uploadsQueue.bytesUploadedSoFar;
    float downloadedBytes = downloadManager.downloadQueue.bytesDownloadedSoFar;
    
    float totalBytesToSync = uploadBytesLeft + downloadBytesLeft + uploadedBytes + downloadedBytes;
    
    float progress = uploadedBytes + downloadedBytes;
    float percentUploaded = 100 * progress / totalBytesToSync;
    percentUploaded = (percentUploaded / 100) * 2;
    [self.progressPanel.progressBar setProgress:percentUploaded];
    float progressLeft = 1 - percentUploaded;
    
    float totalBytesLeft = uploadBytesLeft + downloadBytesLeft;
    
    float bytesLeft = (progressLeft * totalBytesLeft);
    bytesLeft = MAX(0, bytesLeft);
    
    NSString *leftToUpload = [FileUtils stringForLongFileSize:bytesLeft];
    NSString *itemText = [self itemText:totalCount];
    [self.progressPanel.progressLabel setText:[NSString stringWithFormat:NSLocalizedString(@"sync.progress.label", @"Syncing %d %@, %@ left"), totalCount, itemText, leftToUpload]];
}


#pragma mark - Button actions
- (void)cancelUploadsAction:(id)sender
{
    UIAlertView *confirmAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sync.cancelAll.title", @"Sync") message:NSLocalizedString(@"sync.cancelAll.body", @"Would you like to...") delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"No") otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
    
    [confirmAlert show];
}

- (void)failedUploadsAction:(id)sender
{
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableArray* failedItems = [[NSMutableArray alloc] init];
    [failedItems addObjectsFromArray:[[FavoritesUploadManager sharedManager] failedUploads]];
    [failedItems addObjectsFromArray:[[FavoriteDownloadManager sharedManager] failedDownloads]];
    
    FavoriteFailedItemsViewController *failedItemsController = [[FavoriteFailedItemsViewController alloc] initWithFailedUploads:failedItems];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:failedItemsController];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    //Have to use the app delegate since it seems to be a bug when presenting from a popover
    //and no black overlay was added behind the presented view controller
    [appDelegate presentModalViewController:navController animated:YES];
    [failedItemsController release];
    [navController release];
    [failedItems release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 0 && buttonIndex != alertView.cancelButtonIndex)
    {
        _GTMDevLog(@"Cancelling all active uploads!");
       // [[FavoritesUploadManager sharedManager] cancelActiveUploads];
        
        NSArray *activeUploads = [[FavoritesUploadManager sharedManager] activeUploads];
        for(UploadInfo *uploadInfo in activeUploads)
        {
            [[FavoritesUploadManager sharedManager] clearUpload:uploadInfo.uuid];
        }
        
        NSArray *activeDownloads = [[FavoriteDownloadManager sharedManager] activeDownloads];
        for(DownloadInfo *downloadInfo in activeDownloads)
        {
            RepositoryItem * item = downloadInfo.repositoryItem;
            [[FavoriteDownloadManager sharedManager] clearDownload:item.guid];
        }
    }
    
    if(alertView.tag == 1 && buttonIndex != alertView.cancelButtonIndex)
    {
        NSArray *failedUploads = [[FavoritesUploadManager sharedManager] failedUploads];
        NSMutableArray *failedUUIDs = [NSMutableArray arrayWithCapacity:[failedUploads count]];
        for(UploadInfo *uploadInfo in failedUploads)
        {
            [failedUUIDs addObject:uploadInfo.uuid];
        }
        
        _GTMDevLog(@"Clearing all failed uploads!");
        [[FavoritesUploadManager sharedManager] clearUploads:failedUUIDs];
        
        
    }
}

- (void)updateTabItemBadge
{
    NSArray *failedUploads = [[FavoritesUploadManager sharedManager] failedUploads];
    NSInteger activeUploadCount = [[[FavoritesUploadManager sharedManager] uploadsQueue] operationCount];
    
    NSArray *failedDownloads = [[FavoriteDownloadManager sharedManager] failedDownloads];
    NSInteger activeDownloadCount = [[[FavoriteDownloadManager sharedManager] downloadQueue] operationCount];
    
    NSInteger totalActiveCount = activeUploadCount + activeDownloadCount;
    
    if(([failedUploads count] + [failedDownloads count]) > 0)
    {
        [self.tabBarItem setBadgeValue:@"!"];
    }
    else if (totalActiveCount > 0) {
        [self.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%d", totalActiveCount]];
    }
    else 
    {
        [self.tabBarItem setBadgeValue:nil];
    }
    
    
}

#pragma mark - Notification handlers
- (void)updateFailedUploads
{
    NSArray *failedUploads = [[FavoritesUploadManager sharedManager] failedUploads];
    NSArray *failedDownloads = [[FavoriteDownloadManager sharedManager] failedDownloads];
    
    NSInteger totalFailed = [failedUploads count] + [failedDownloads count];
    
    if(totalFailed > 0)
    {
        NSString *itemText = [self itemText:totalFailed];
        [self.failurePanel.badge autoBadgeSizeWithString:@"!"];
        [self.failurePanel.badge setNeedsDisplay];
        [self.failurePanel.failureLabel setText:[NSString stringWithFormat:NSLocalizedString(@"sync.failed.label", @"%d %@ failed to upload"), totalFailed, itemText]];
        [self showFailurePanel];
    }
    else 
    {
        [self hideFailurePanel];
    }
}

- (void)uploadQueueChanged:(NSNotification *)notification
{
    NSArray *activeUploads = [[FavoritesUploadManager sharedManager] activeUploads];
    
    _activeUploadsCount = [activeUploads count];
    
    //This may be called from a background thread
    //making sure the UI updates are performed in the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updateProgressPanelLabel];
        
        [self updateFailedUploads];
        [self updateTabItemBadge];
    });
}

- (void)downloadQueueChanged:(NSNotification *)notification
{
    NSArray *activeDownloads = [[FavoriteDownloadManager sharedManager] activeDownloads];
    
    _activeDownloadsCount = [activeDownloads count];
    
    //This may be called from a background thread
    //making sure the UI updates are performed in the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updateProgressPanelLabel];
        
        [self updateFailedUploads];
        [self updateTabItemBadge];
    });
}

-(void) updateProgressPanelLabel
{
    NSInteger totalActiveCount = _activeUploadsCount + _activeDownloadsCount;
    
    
    if(totalActiveCount > 0)
    {
        NSString *itemText = [self itemText:totalActiveCount];
        
        [self.progressPanel.progressLabel setText:[NSString stringWithFormat:NSLocalizedString(@"sync.progress.label", @"Syncing %d %@, %@ left"), 
                                                   totalActiveCount, itemText, @"0"]];
        
        if(_activeUploadsCount > 0)
        {
            [[FavoritesUploadManager sharedManager] setQueueProgressDelegate:self];
        }
        if(_activeDownloadsCount > 0)
        {
            [[FavoriteDownloadManager sharedManager] setQueueProgressDelegate:self];
        }
        
        if(_isProgressPanelHidden)
        {
           [self showProgressPanel];
        }
    }
    else if(!_isProgressPanelHidden)
    {
        if(totalActiveCount == 0)
        {
            [self hideProgressPanel];
        }
        
        if(_activeUploadsCount == 0)
        {
            [[FavoritesUploadManager sharedManager] setQueueProgressDelegate:nil];
        }
        if(_activeDownloadsCount == 0)
        {
            [[FavoriteDownloadManager sharedManager] setQueueProgressDelegate:nil];
        }
    }
}

@end
