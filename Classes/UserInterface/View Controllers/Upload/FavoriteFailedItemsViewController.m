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
//  FavoriteFailedItemsViewController.m
//

#import "FavoriteFailedItemsViewController.h"
#import "FavoritesUploadManager.h"
#import "FavoriteDownloadManager.h"

@implementation FavoriteFailedItemsViewController

#pragma mark - Button actions

- (void)retryButtonAction:(id)sender
{
    for (id item in self.failedUploadsAndDownloads)
    {
        if ([item isKindOfClass:[UploadInfo class]])
        {
            UploadInfo *uploadInfo = (UploadInfo *)item;
            [[FavoritesUploadManager sharedManager] retryUpload:uploadInfo.uuid];
        }
        else if([item isKindOfClass:[DownloadInfo class]])
        {
            DownloadInfo *downloadInfo = (DownloadInfo *)item;
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
    for (id item in self.failedUploadsAndDownloads)
    {
        if ([item isKindOfClass:[UploadInfo class]])
        {
            UploadInfo *uploadInfo = (UploadInfo *)item;
            [[FavoritesUploadManager sharedManager] clearUpload:uploadInfo.uuid];
        }
        else if ([item isKindOfClass:[DownloadInfo class]])
        {
            DownloadInfo *downloadInfo = (DownloadInfo *)item;
            RepositoryItem *repositoryItem = downloadInfo.repositoryItem;
            [[FavoriteDownloadManager sharedManager] clearDownload:repositoryItem.guid];
        }
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

@end
