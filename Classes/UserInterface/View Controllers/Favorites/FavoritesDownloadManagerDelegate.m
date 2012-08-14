//
//  FavoritesDownloadManagerDelegate.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 13/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "FavoritesDownloadManagerDelegate.h"
#import "FavoriteTableCellWrapper.h"
#import "FavoriteTableViewCell.h"
#import "RepositoryItem.h"
#import "DownloadInfo.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"

@implementation FavoritesDownloadManagerDelegate

@synthesize repositoryItems = _repositoryItems;
@synthesize tableView = _tableView;
@synthesize navigationController = _navigationController;
@synthesize presentNewDocumentPopover = _presentNewDocumentPopover;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_repositoryItems release];
    [_tableView release];
    [_navigationController release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [super dealloc];
}


-(id) init
{
    self = [super init];
    
    if(self != nil)
    {
        // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationFavoriteDownloadQueueChanged object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:kNotificationFavoriteDownloadStarted object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFinished:) name:kNotificationFavoriteDownloadFinished object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFailed:) name:kNotificationFavoriteDownloadFailed object:nil];
        
        
    }
    
    return self;
}

#pragma mark - PreviewManagerDelegate Methods


- (void) downloadCancelled:(NSNotification *)notification
{
    /*
     NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
     RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
     RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
     
     [manager setProgressIndicator:nil];
     [cell.progressBar setHidden:YES];
     [cell.details setHidden:NO];
     [cellWrapper setIsDownloadingPreview:NO];
     
     [self.tableView setAllowsSelection:YES];
     [self setPresentNewDocumentPopover:NO];
     
     */
}

- (void) downloadFailed:(NSNotification *)notification
{
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:[notification.userInfo objectForKey:@"downloadObjectId"]];
    FavoriteTableViewCell *cell = (FavoriteTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    FavoriteTableCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    
    [[FavoriteDownloadManager sharedManager] setProgressIndicator:nil forObjectId:[notification.userInfo objectForKey:@"downloadObjectId"]];
    [cell.progressBar setHidden:YES];
    [cell.details setHidden:NO];
    [cellWrapper setIsDownloadingPreview:NO];
    
    [self.tableView setAllowsSelection:YES];
    [self setPresentNewDocumentPopover:NO];
}

- (void) downloadFinished:(NSNotification *)notification
{
    UITableView *tableView = [self tableView];
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:[notification.userInfo objectForKey:@"downloadObjectId"]];
    FavoriteTableViewCell *cell = (FavoriteTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    FavoriteTableCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    
    [[FavoriteDownloadManager sharedManager] setProgressIndicator:nil forObjectId:[notification.userInfo objectForKey:@"downloadObjectId"]];
    [cell.progressBar setHidden:YES];
    [cell.details setHidden:NO];
    [cellWrapper setIsDownloadingPreview:NO];
    
    if([[notification.userInfo objectForKey:@"showDoc"] isEqualToString:@"Yes"])
    {
        
        DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
        [doc setCmisObjectId:[notification.userInfo objectForKey:@"downloadObjectId"]];
        
        DownloadInfo *info = [notification.userInfo objectForKey:@"downloadInfo"];
        [doc setContentMimeType:info.repositoryItem.contentStreamMimeType];
        [doc setHidesBottomBarWhenPushed:YES];
        [doc setPresentNewDocumentPopover:self.presentNewDocumentPopover];
        [doc setSelectedAccountUUID:self.selectedAccountUUID];
        [doc setTenantID:self.tenantID];
        
        DownloadMetadata *fileMetadata = info.downloadMetadata;
        NSString *filename = fileMetadata.key;
        [doc setFileMetadata:fileMetadata];
        [doc setFileName:filename];
        [doc setFilePath:info.tempFilePath];
        
        [IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
        [doc release];
        
    }
    
    [tableView setAllowsSelection:YES];
    [self setPresentNewDocumentPopover:NO];
}

- (void) downloadStarted:(NSNotification *)notification
{
    NSLog(@"Notification : %@", notification.userInfo);
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:[notification.userInfo objectForKey:@"downloadObjectId"]];
    FavoriteTableViewCell *cell = (FavoriteTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    FavoriteTableCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    
    [[FavoriteDownloadManager sharedManager] setProgressIndicator:cell.progressBar forObjectId:[notification.userInfo objectForKey:@"downloadObjectId"]];
    
    [cell.progressBar setProgress:[[FavoriteDownloadManager sharedManager] currentProgressForObjectId:[notification.userInfo objectForKey:@"downloadObjectId"]]];
    
    [cell.details setHidden:YES];
    [cell.progressBar setHidden:NO];
    [cellWrapper setIsDownloadingPreview:YES];
}

- (NSIndexPath *)indexPathForNodeWithGuid:(NSString *)itemGuid
{
    NSIndexPath *indexPath = nil;
    NSMutableArray *items = [self repositoryItems];
    
    if (itemGuid != nil && items != nil)
    {
        // Define a block predicate to search for the item being viewed
        BOOL (^matchesRepostoryItem)(FavoriteTableCellWrapper *, NSUInteger, BOOL *) = ^ (FavoriteTableCellWrapper *cellWrapper, NSUInteger idx, BOOL *stop)
        {
            BOOL matched = NO;
            RepositoryItem *repositoryItem = [cellWrapper anyRepositoryItem];
            if ([[repositoryItem guid] isEqualToString:itemGuid] == YES)
            {
                matched = YES;
                *stop = YES;
            }
            return matched;
        };
        
        // See if there's an item in the list with a matching guid, using the block defined above
        NSUInteger matchingIndex = [items indexOfObjectPassingTest:matchesRepostoryItem];
        if (matchingIndex != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:matchingIndex inSection:0];
        }
    }
    
    return indexPath;
}


- (void)previewManager:(PreviewManager *)manager downloadCancelled:(DownloadInfo *)info
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:info, @"downloadInfo", info.cmisObjectId, @"downloadObjectId", nil];
    
    [self downloadCancelled: [NSNotification notificationWithName:@"" object:nil userInfo:userInfo]];
}
- (void)previewManager:(PreviewManager *)manager downloadStarted:(DownloadInfo *)info
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:info, @"downloadInfo",info.cmisObjectId, @"downloadObjectId", nil];
    [self downloadStarted: [NSNotification notificationWithName:@"" object:nil userInfo:userInfo]];
}
- (void)previewManager:(PreviewManager *)manager downloadFinished:(DownloadInfo *)info
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:info, @"downloadInfo", info.cmisObjectId, @"downloadObjectId", @"Yes", @"showDoc", nil];
    [self downloadFinished: [NSNotification notificationWithName:@"" object:nil userInfo:userInfo]];
}
- (void)previewManager:(PreviewManager *)manager downloadFailed:(DownloadInfo *)info withError:(NSError *)error
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:info, @"downloadInfo", info.cmisObjectId, @"downloadObjectId", error, @"downloadError", nil];
    [self downloadFailed: [NSNotification notificationWithName:@"" object:nil userInfo:userInfo]];
}

@end

