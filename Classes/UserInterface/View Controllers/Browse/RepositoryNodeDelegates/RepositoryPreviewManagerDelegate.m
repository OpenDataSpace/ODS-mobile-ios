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
//  RepositoryPreviewManagerDelegate.m
//

#import "RepositoryPreviewManagerDelegate.h"
#import "RepositoryItemCellWrapper.h"
#import "RepositoryItemTableViewCell.h"
#import "RepositoryItem.h"
#import "DownloadInfo.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"

@implementation RepositoryPreviewManagerDelegate
@synthesize repositoryItems = _repositoryItems;
@synthesize tableView = _tableView;
@synthesize navigationController = _navigationController;
@synthesize presentNewDocumentPopover = _presentNewDocumentPopover;
@synthesize presentEditMode = _presentEditMode;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [_repositoryItems release];
    [_tableView release];
    [_navigationController release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [super dealloc];
}

#pragma mark - PreviewManagerDelegate Methods

- (void)previewManager:(PreviewManager *)manager downloadCancelled:(DownloadInfo *)info
{
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    
    [manager setProgressIndicator:nil];
    [cell.progressBar setHidden:YES];
    [cell.details setHidden:NO];
    [cellWrapper setIsDownloadingPreview:NO];
    
    [self.tableView setAllowsSelection:YES];
    [self setPresentNewDocumentPopover:NO];
}

- (void)previewManager:(PreviewManager *)manager downloadFailed:(DownloadInfo *)info withError:(NSError *)error
{
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    
    [manager setProgressIndicator:nil];
    [cell.progressBar setHidden:YES];
    [cell.details setHidden:NO];
    [cellWrapper setIsDownloadingPreview:NO];
    
    [self.tableView setAllowsSelection:YES];
    [self setPresentNewDocumentPopover:NO];
}

- (void)previewManager:(PreviewManager *)manager downloadFinished:(DownloadInfo *)info
{
    UITableView *tableView = [self tableView];
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    
    [manager setProgressIndicator:nil];
    [cell.progressBar setHidden:YES];
    [cell.details setHidden:NO];
    [cellWrapper setIsDownloadingPreview:NO];
    
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
	[doc setCmisObjectId:info.repositoryItem.guid];
    [doc setContentMimeType:info.repositoryItem.contentStreamMimeType];
    [doc setHidesBottomBarWhenPushed:YES];
    [doc setPresentNewDocumentPopover:self.presentNewDocumentPopover];
    [doc setPresentEditMode:self.presentEditMode];
    [doc setSelectedAccountUUID:self.selectedAccountUUID];
    [doc setTenantID:self.tenantID];
    
    DownloadMetadata *fileMetadata = info.downloadMetadata;
    NSString *filename = fileMetadata.key;
    [doc setFileMetadata:fileMetadata];
    [doc setFileName:filename];
    [doc setFilePath:info.tempFilePath];
    
	[IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
	[doc release];
    [tableView setAllowsSelection:YES];
    [self setPresentNewDocumentPopover:NO];
    [self setPresentEditMode:NO];
}

- (void)previewManager:(PreviewManager *)manager downloadStarted:(DownloadInfo *)info
{
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    
    [manager setProgressIndicator:cell.progressBar];
    [cell.progressBar setProgress:manager.currentProgress];
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
        BOOL (^matchesRepostoryItem)(RepositoryItemCellWrapper *, NSUInteger, BOOL *) = ^ (RepositoryItemCellWrapper *cellWrapper, NSUInteger idx, BOOL *stop)
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


@end
