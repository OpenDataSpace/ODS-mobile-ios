//
//  FavoriteFailedItemsViewController.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 10/09/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "FavoriteFailedItemsViewController.h"
#import "FavoritesUploadManager.h"
#import "FavoriteDownloadManager.h"
#import "FavoriteManager.h"

@interface FavoriteFailedItemsViewController ()

@end

@implementation FavoriteFailedItemsViewController

#pragma mark - Button actions
- (void)retryButtonAction:(id)sender
{
    for(id item in self.failedUploadsAndDownloads)
    {
        if([item isKindOfClass:[UploadInfo class]])
        {
            UploadInfo *uploadInfo = (UploadInfo *) item;
            
            [[FavoritesUploadManager sharedManager] retryUpload:uploadInfo.uuid];
        }
        else if([item isKindOfClass:[DownloadInfo class]])
        {
            DownloadInfo *downloadInfo = (DownloadInfo *) item;
            
            [[FavoriteDownloadManager sharedManager] retryDownload:downloadInfo.repositoryItem.guid];
            
        }
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)closeButtonAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)clearButtonAction:(id)sender
{
    for(id item in self.failedUploadsAndDownloads)
    {
        if([item isKindOfClass:[UploadInfo class]])
        {
            UploadInfo *uploadInfo = (UploadInfo *) item;
            [[FavoritesUploadManager sharedManager] clearUpload:uploadInfo.uuid];
        }
        else if([item isKindOfClass:[DownloadInfo class]])
        {
            DownloadInfo * downloadInfo = (DownloadInfo *) item;
            
            RepositoryItem * item = downloadInfo.repositoryItem;
            [[FavoriteDownloadManager sharedManager] clearDownload:item.guid];
            
        }
        
    }
    
    [self dismissModalViewControllerAnimated:YES];
}


@end
