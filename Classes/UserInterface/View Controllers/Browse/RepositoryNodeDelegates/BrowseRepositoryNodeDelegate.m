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
//  BrowseRepositoryNodeDelegate.m
//

#import "BrowseRepositoryNodeDelegate.h"
#import "RepositoryItemCellWrapper.h"
#import "DownloadManager.h"
#import "RepositoryItem.h"
#import "MBProgressHUD.h"
#import "Utility.h"
#import "LinkRelationService.h"
#import "FolderItemsHTTPRequest.h"
#import "PreviewManager.h"
#import "RepositoryPreviewManagerDelegate.h"
#import "ObjectByIdRequest.h"
#import "UploadInfo.h"
#import "FailedTransferDetailViewController.h"
#import "UploadsManager.h"
#import "DeleteQueueProgressBar.h"
#import "DownloadInfo.h"
#import "FileDownloadManager.h"
#import "DownloadMetadata.h"
#import "MetaDataTableViewController.h"
#import "IpadSupport.h"
#import "RepositoryNodeViewController.h"
#import "DeleteObjectRequest.h"
#import "MultiSelectActionsToolbar.h"
#import "RepositoryNodeDataSource.h"
#import "RepositoryNodeUtils.h"
#import "FavoriteManager.h"

NSInteger const kCancelUploadPrompt = 2;
NSInteger const kDismissFailedUploadPrompt = 3;

UITableViewRowAnimation const kRepositoryTableViewRowAnimation = UITableViewRowAnimationFade;

@implementation BrowseRepositoryNodeDelegate
@synthesize multiSelectToolbar = _multiSelectToolbar;
@synthesize itemDownloader = _itemDownloader;
@synthesize metadataDownloader = _metadataDownloader;
@synthesize previewDelegate = _previewDelegate;
@synthesize uploadToDismiss = _uploadToDismiss;
@synthesize uploadToCancel = _uploadToCancel;
@synthesize tableView = _tableView;
@synthesize navigationController = _navigationController;
@synthesize actionsDelegate = _actionsDelegate;
@synthesize scrollViewDelegate = _scrollViewDelegate;
@synthesize popover = _popover;
@synthesize HUD = _HUD;
@synthesize uplinkRelation = _uplinkRelation;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_itemDownloader release];
    [_metadataDownloader release];
    [_previewDelegate release];
    [_uploadToDismiss release];
    [_uploadToCancel release];
    [_tableView release];
    [_navigationController release];
    [_popover release];
    [_HUD release];
    [_uplinkRelation release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [super dealloc];
}

- (id)init
{
    return [self initWithViewController:nil];
}


- (id)initWithViewController:(UIViewController *)viewController
{
    self = [super init];
    if(self)
    {
        [self setActionsDelegate:viewController];
        [self setNavigationController:[viewController navigationController]];
        if([viewController respondsToSelector:@selector(tableView)])
        {
            [self setTableView:[viewController performSelector:@selector(tableView)]];
        }
        if([viewController respondsToSelector:@selector(selectedAccountUUID)])
        {
            [self setSelectedAccountUUID:[viewController performSelector:@selector(selectedAccountUUID)]];
        }
        if([viewController respondsToSelector:@selector(tenantID)])
        {
            [self setTenantID:[viewController performSelector:@selector(tenantID)]];
        }
        if([viewController respondsToSelector:@selector(folderItems)])
        {
            FolderItemsHTTPRequest *folderItems = [viewController performSelector:@selector(folderItems)];
            [self setUplinkRelation:[[folderItems item] identLink]];
        }
        
        RepositoryPreviewManagerDelegate *previewDelegate = [[RepositoryPreviewManagerDelegate alloc] init];
        [previewDelegate setTableView:[self tableView]]; 
        [previewDelegate setSelectedAccountUUID:[self selectedAccountUUID]];
        [previewDelegate setTenantID:[self tenantID]];
        [previewDelegate setNavigationController:[self navigationController]];
        [[PreviewManager sharedManager] setDelegate:previewDelegate];
        [self setPreviewDelegate:previewDelegate];
        [previewDelegate release];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kNotificationUploadFinished object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUpdated:) name:kNotificationDocumentUpdated object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentFavoritedOrUnfavorited:) name:kNotificationDocumentFavoritedOrUnfavorited object:nil];
    }
    return self;
}


#pragma mark Table view methods

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
// Row deselection - only interested when in edit mode
{
	RepositoryItem *child = nil;
    RepositoryItemCellWrapper *cellWrapper = nil;
    
    if ([tableView isEditing])
    {
        cellWrapper = [self.repositoryItems objectAtIndex:[indexPath row]];
        child = [cellWrapper anyRepositoryItem];
        [self.multiSelectToolbar userDidDeselectItem:child atIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
// Row selection (all modes)
{
	RepositoryItem *child = nil;
    RepositoryItemCellWrapper *cellWrapper = nil;
    
    cellWrapper = [self.repositoryItems objectAtIndex:[indexPath row]];
    child = [cellWrapper anyRepositoryItem];
    
    // Don't continue if there's nothing to highlight
    if (!child)
    {
        return;
    }
    
    if ([tableView isEditing])
    {
        [self.multiSelectToolbar userDidSelectItem:child atIndexPath:indexPath];
    }
    else
    {
        if ([child isFolder])
        {
            [self startHUDInTableView:tableView];
            [self.itemDownloader clearDelegatesAndCancel];
            
            NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];
            NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:child 
                                                                        withOptionalArguments:optionalArguments];
            FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:self.selectedAccountUUID];
            [down setDelegate:self];
            [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
            [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
            [self setItemDownloader:down];
            [down setItem:child];
            [down setParentTitle:child.title];
            [down startAsynchronous];
            [down release];
        }
        else
        {
            if (child.contentLocation)
            {
                [tableView setAllowsSelection:NO];
                //We fetch the current repository items from the DataSource
                [self.previewDelegate setRepositoryItems:[self repositoryItems]];
                [[PreviewManager sharedManager] previewItem:child delegate:self.previewDelegate accountUUID:self.selectedAccountUUID tenantID:self.tenantID];
            }
            else
            {
                displayErrorMessageWithTitle(NSLocalizedString(@"noContentWarningMessage", @"This document has no content."), NSLocalizedString(@"noContentWarningTitle", @"No content"));
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
	RepositoryItem *child = [cellWrapper anyRepositoryItem];
    UploadInfo *uploadInfo = cellWrapper.uploadInfo;
	
    if (child)
    {
        if (cellWrapper.isDownloadingPreview)
        {
            [[PreviewManager sharedManager] cancelPreview];
            [self deselectRowinTableView:self.tableView atIndexPath:[self.tableView indexPathForSelectedRow]];
        }
        else
        {
            [tableView setAllowsSelection:NO];
            [self startHUDInTableView:tableView];
            
            ObjectByIdRequest *object = [[ObjectByIdRequest defaultObjectById:child.guid accountUUID:self.selectedAccountUUID tenantID:self.tenantID] retain];
            [object setDelegate:self];
            [object startAsynchronous];
            [self setMetadataDownloader:object];
            [object release];
        }
    }
    else if (uploadInfo && [uploadInfo uploadStatus] != UploadInfoStatusFailed)
    {
        [self setUploadToCancel:cellWrapper];
        UIAlertView *confirmAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploads.cancelAll.title", @"Uploads")
                                                                message:NSLocalizedString(@"uploads.cancel.body", @"Would you like to...")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                      otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
        [confirmAlert setTag:kCancelUploadPrompt];
        [confirmAlert show];
    }
    else if (uploadInfo && [uploadInfo uploadStatus] == UploadInfoStatusFailed)
    {
        [self setUploadToDismiss:uploadInfo];
        if (IS_IPAD)
        {
            FailedTransferDetailViewController *viewController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"Upload Failed", @"Upload failed popover title")
                                                                                                                   message:[uploadInfo.error localizedDescription]];
            
            [viewController setUserInfo:uploadInfo];
            [viewController setCloseTarget:self];
            [viewController setCloseAction:@selector(closeFailedUpload:)];
            
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
            [self setPopover:popoverController];
            [popoverController setPopoverContentSize:viewController.view.frame.size];
            [popoverController setDelegate:self];
            [popoverController release];
            [viewController release];
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            if(cell.accessoryView.window != nil)
            {
                [self.popover presentPopoverFromRect:cell.accessoryView.frame inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
        }
        else
        {
            UIAlertView *uploadFailDetail = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Upload Failed", @"")
                                                                        message:[uploadInfo.error localizedDescription]
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
                                                              otherButtonTitles:NSLocalizedString(@"Retry", @"Retry"), nil] autorelease];
            [uploadFailDetail setTag:kDismissFailedUploadPrompt];
            [uploadFailDetail show];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RepositoryItemCellWrapper *cellWrapper = nil;
    cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    
    return [cellWrapper.anyRepositoryItem canDeleteObject] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

-( void) deselectRowinTableView:(UITableView *) tableView atIndexPath:(NSIndexPath *) indexPath
{
    [self tableView:tableView willDeselectRowAtIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - UIScrollViewDelegate Methods

/* The UIScrollViewDelegate (conformed by the UITableViewDelegate) is
 delegated to anyone who wants to delegate
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)])
    {
        [self.scrollViewDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if([self.scrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
    {
        [self.scrollViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

#pragma mark - properties
- (NSMutableArray *)repositoryItems
{
    if([[self.tableView dataSource] respondsToSelector:@selector(repositoryItems)])
    {
        return [self.tableView.dataSource performSelector:@selector(repositoryItems)];
    }
    return nil;
}

#pragma mark - HUD Delegate
- (void)startHUDInTableView:(UITableView *)tableView
{
    if(!self.HUD)
    {
        [self setHUD:createAndShowProgressHUDForView(tableView)];
    }
}

- (void)stopHUD
{
    if(self.HUD)
    {
        stopProgressHUD(self.HUD);
        [self setHUD:nil];
    }
}

#pragma mark UIAlertView delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (IS_IPAD)
    {
		if ([self.popover isPopoverVisible])
        {
			[self.popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
    
    if (alertView.tag == kCancelUploadPrompt) 
    {
        RepositoryItemCellWrapper *uploadToCancel = [self uploadToCancel];
        UploadInfo *uploadInfo = [uploadToCancel uploadInfo];
        
        if(buttonIndex != alertView.cancelButtonIndex && ([uploadInfo uploadStatus] == UploadInfoStatusActive || [uploadInfo uploadStatus] == UploadInfoStatusUploading))
        {
            // We MUST remove the cell before clearing the upload in the manager
            // since every time the queue changes we listen to the notification ploand also try to remove it there (see: uploadQueueChanged:)
            NSUInteger indexToCancel = [self.repositoryItems indexOfObject:uploadToCancel];
            [self.repositoryItems removeObjectAtIndex:indexToCancel];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexToCancel inSection:0];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:kRepositoryTableViewRowAnimation];
            
            [[UploadsManager sharedManager] clearUpload:uploadInfo.uuid];
        }
        
        return;
    }
    else if (alertView.tag == kDismissFailedUploadPrompt)
    {
        if (buttonIndex == alertView.cancelButtonIndex)
        {
            [[UploadsManager sharedManager] clearUpload:self.uploadToDismiss.uuid];
        }
        else {
            [[UploadsManager sharedManager] retryUpload:self.uploadToDismiss.uuid];
        }
    }
    
}

#pragma mark - UIPopoverController Delegate methods

// This is called when the popover was dismissed by the user by tapping in another part of the screen,
// We want to to clear the upload
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [[UploadsManager sharedManager] clearUpload:self.uploadToDismiss.uuid];
}

#pragma mark - FailedUploadDetailViewController Delegate

// This is called from the FailedTransferDetailViewController and it means the user wants to retry the failed upload
- (void)closeFailedUpload:(FailedTransferDetailViewController *)sender
{
    if (nil != self.popover && [self.popover isPopoverVisible]) 
    {
        // Removing us as the delegate so we don't get the dismiss call at this point the user retried the upload and 
        // we don't want to clear the upload
        [self.popover setDelegate:nil];
        [self.popover dismissPopoverAnimated:YES];
        [self setPopover:nil];
        
        UploadInfo *uploadInfo = (UploadInfo *)sender.userInfo;
        [[UploadsManager sharedManager] retryUpload:uploadInfo.uuid];
    }
}

#pragma mark - ASIHTTPRequest Delegate
- (void)requestFinished:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];
    if ([request isKindOfClass:[ObjectByIdRequest class]])
    {
        ObjectByIdRequest *object = (ObjectByIdRequest*) request;
        
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[object repositoryItem] 
                                                                                             accountUUID:[object accountUUID] 
                                                                                                tenantID:self.tenantID];
        [viewController setCmisObjectId:object.repositoryItem.guid];
        [viewController setMetadata:object.repositoryItem.metadata];
        [viewController setSelectedAccountUUID:self.selectedAccountUUID];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [viewController release];
    }
    if([self.actionsDelegate respondsToSelector:@selector(loadRightBarAnimated:)])
    {
        [self.actionsDelegate performSelector:@selector(loadRightBarAnimated:) withObject:[NSNumber numberWithBool:NO]];
    }
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];
    [self stopHUD];
}

#pragma mark - FolderItemsHTTPRequest Delegate

- (void)folderItemsRequestFinished:(ASIHTTPRequest *)request 
{
	if ([request isKindOfClass:[FolderItemsHTTPRequest class]]) 
    {
		// we're loading a child which needs to
		// be created and pushed onto the nav stack
        FolderItemsHTTPRequest *fid = (FolderItemsHTTPRequest *) request;
        
        // create a new view controller for the list of repository items (documents and folders)            
        RepositoryNodeViewController *viewController = [[RepositoryNodeViewController alloc] initWithNibName:nil bundle:nil];
        [viewController setSelectedAccountUUID:[self selectedAccountUUID]];
        [viewController setTenantID:[self tenantID]];
        [viewController setFolderItems:fid];
        [viewController setTitle:[fid parentTitle]];
        [viewController setGuid:fid.item.guid];
        
        // push that view onto the nav controller's stack
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
	} 
    
    [self stopHUD];
}

- (void)folderItemsRequestFailed:(ASIHTTPRequest *)request
{
	[self stopHUD];
}

#pragma mark - NSNotificationCenter methods
- (void)uploadFinished:(NSNotification *)notification
{
    UploadInfo *uploadInfo = [notification.userInfo objectForKey:@"uploadInfo"];
    NSLog(@"uploadinfo: %@",[uploadInfo upLinkRelation]);
    NSLog(@"self: %@",self.uplinkRelation);
    
    if (uploadInfo.uploadStatus == UploadInfoStatusUploaded 
        && [uploadInfo uploadType] == UploadFormTypeCreateDocument
        && [uploadInfo repositoryItem]
        && [self.uplinkRelation isEqualToString:[uploadInfo upLinkRelation]])
    {
        //Preview the new file and enter edit mode
        [self.previewDelegate setRepositoryItems:[self repositoryItems]];
        //We enter edit mode for created txt files and show a popover for the other kind of documents
        if([[uploadInfo extension] isEqualToString:kCreateDocumentTextExtension])
        {
            [self.previewDelegate setPresentEditMode:YES];
        }
        else 
        {
            [self.previewDelegate setPresentNewDocumentPopover:YES];
        }
        
        
        
        [self deselectRowinTableView:self.tableView atIndexPath:[self.tableView indexPathForSelectedRow]];
        [[PreviewManager sharedManager] previewItem:[uploadInfo repositoryItem] delegate:self.previewDelegate accountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    }
}

- (void)documentUpdated:(NSNotification *) notification
{
    NSString *objectId = [[notification userInfo] objectForKey:@"objectId"];
    NSIndexPath *indexPath = [RepositoryNodeUtils indexPathForNodeWithGuid:objectId inItems:self.repositoryItems];
    
    if(indexPath)
    {
        //Updating the repository item in the cell wrapper
        RepositoryItemCellWrapper *item = [self.repositoryItems objectAtIndex:indexPath.row];
        NSIndexPath *selectedIndex = [self.tableView indexPathForSelectedRow];
        [item setRepositoryItem:[[notification userInfo] objectForKey:@"repositoryItem"]];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
        //Reselecting the cell, because it will be deselected after the reload
        if([selectedIndex isEqual:indexPath])
        {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    else
    {
        [self deselectRowinTableView:self.tableView atIndexPath:self.tableView.indexPathForSelectedRow];
    }
}


#pragma mark NSNotificationCenter Method Favorite or Unfavorited a document
/**
 * Document is favorited or unfavorited notification
 */
- (void)documentFavoritedOrUnfavorited:(NSNotification *)notification
{
    // TODO: This seems awfully complicated. Can we just pass the objectId in the notification?
    NSString *accountID = [notification.userInfo objectForKey:@"accountUUID"];
    FavoriteManager *favoriteManager = [FavoriteManager sharedManager];
    
    if ([accountID isEqualToString:self.selectedAccountUUID])
    {
        for (RepositoryItemCellWrapper *item in self.repositoryItems)
        {
            NSIndexPath *indexPath = [RepositoryNodeUtils indexPathForNodeWithGuid:item.repositoryItem.guid inItems:self.repositoryItems];
            if(indexPath)
            {
                UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
                BOOL isFav = [favoriteManager isNodeFavorite:[item.repositoryItem guid]  inAccount:self.selectedAccountUUID];
                [item favoriteOrUnfavoriteDocument:(isFav? IsFavorite : IsNotFavorite) forCell:cell];
            }
        }
    }
    
}


@end
