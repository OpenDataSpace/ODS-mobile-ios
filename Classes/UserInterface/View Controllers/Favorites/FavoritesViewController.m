
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
//  FavoritesViewController.m
//

#import "FavoritesViewController.h"
#import "Theme.h"
#import "AlfrescoAppDelegate.h"
#import "RepositoryServices.h"
#import "ObjectByIdRequest.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"
#import "MetaDataTableViewController.h"
#import "WhiteGlossGradientView.h"
#import "ThemeProperties.h"
#import "AccountManager.h"
#import "FavoriteFileDownloadManager.h"
#import "PreviewManager.h"
#import "FavoritesTableViewDataSource.h"
#import "FavoritesDownloadManagerDelegate.h"
#import "FavoriteTableCellWrapper.h"
#import "RepositoryPreviewManagerDelegate.h"
#import "Reachability.h"
#import "ConnectivityManager.h"
#import "FailedTransferDetailViewController.h"
#import "FavoritesErrorsViewController.h"

static const NSInteger delayToShowErrors = 2.0f;

@interface FavoritesViewController ()

- (void)loadFavorites:(SyncType)syncType;
- (void)startHUDInTableView:(UITableView *)tableView;
- (void)stopHUD;

- (void)checkForSyncErrorsAndDisplay;

@end

@implementation FavoritesViewController

@synthesize HUD = _HUD;
@synthesize favoritesRequest = _favoritesRequest;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;
@synthesize folderDatasource = _folderDatasource;
@synthesize favoriteDownloadManagerDelegate = _favoriteDownloadManagerDelegate;

@synthesize wrapperToRetry = _wrapperToRetry;
@synthesize popover = _popover;

#pragma mark - View lifecycle

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_favoritesRequest clearDelegatesAndCancel];
    
    [_HUD release];
    [_favoritesRequest release];
    [_refreshHeaderView release];
    [_lastUpdated release];
    [_folderDatasource release];
    [_favoriteDownloadManagerDelegate release];
    [_wrapperToRetry release];
    [_popover release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self.HUD setTaskInProgress:NO];
    [self.HUD hide:YES];
    [_HUD release];
    _HUD = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkForSyncErrorsAndDisplay];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    
    if ([[FavoriteManager sharedManager] isFirstUse])
    {
        if ([[[AccountManager sharedManager] activeAccounts] count] > 0)
        {
            [self startHUDInTableView:self.tableView];
        }
        [[FavoriteManager sharedManager] showSyncPreferenceAlert];
    }
    else if (IS_IPAD)
    {
        NSIndexPath *indexPath = [self indexPathForNodeWithGuid:[IpadSupport getCurrentDetailViewControllerObjectID]];
        if (self.tableView)
        {
            if (indexPath)
            {
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
            else if (self.tableView.indexPathForSelectedRow)
            {
                [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
            }
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    if (IS_IPAD)
    {
        self.clearsSelectionOnViewWillAppear = NO;
    }
    
    FavoritesTableViewDataSource *dataSource = [[FavoritesTableViewDataSource alloc] init];
    [self setFolderDatasource:dataSource];
    [self.tableView setDataSource:dataSource];
    [dataSource release];
    
    FavoriteManager *favoriteManager = [FavoriteManager sharedManager];
    [self.folderDatasource setFavorites:[favoriteManager getLiveListIfAvailableElseLocal]];
    
    [self.folderDatasource refreshData];
    [self.tableView reloadData];
    
    [favoriteManager setDelegate:self];
    
    if (![favoriteManager isFirstUse])
    {
        [self startHUDInTableView:self.tableView];
        [self performSelector:@selector(loadFavorites:) withObject:nil afterDelay:0.5];
    }
    
	// Pull to Refresh
    self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                arrowImageName:@"pull-to-refresh.png"
                                                                     textColor:[ThemeProperties pullToRefreshTextColor]] autorelease];
    [self.refreshHeaderView setDelegate:self];
    [self setLastUpdated:[NSDate date]];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];
    
    FavoritesDownloadManagerDelegate *favoriteDownloaderDelegate = [[FavoritesDownloadManagerDelegate alloc] init];
    [favoriteDownloaderDelegate setTableView:self.tableView];
    [favoriteDownloaderDelegate setNavigationController:self.navigationController];
    [self setFavoriteDownloadManagerDelegate:favoriteDownloaderDelegate];
    [favoriteDownloaderDelegate release];
    
    [self updateTitle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncPreferenceChangedNotification:) name:kSyncPreferenceChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountsListChanged:) name:kNotificationAccountListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFilesExpired:) name:kNotificationExpiredFiles object:nil];
}

- (void)loadFavorites:(SyncType)syncType
{
    [self startHUDInTableView:self.tableView];
    [[FavoriteManager sharedManager] setDelegate:self];
    [[FavoriteManager sharedManager] startFavoritesRequest:syncType];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dataSourceFinishedLoadingWithSuccess:(BOOL)wasSuccessful
{
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];

    if (wasSuccessful)
    {
        [self setLastUpdated:[NSDate date]];
        [self.refreshHeaderView refreshLastUpdatedDate];
    
        if (IS_IPAD)
        {
            NSIndexPath *indexPath = [self indexPathForNodeWithGuid:[IpadSupport getCurrentDetailViewControllerObjectID]];
            if (indexPath && self.tableView)
            {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)tableView.dataSource;
    FavoriteTableCellWrapper *cellWrapper = [dataSource.favorites objectAtIndex:indexPath.row];
    RepositoryItem *child = [cellWrapper anyRepositoryItem];
    
    if (cellWrapper.isActivityInProgress == NO)
    {
        if (![fileManager downloadExistsForKey:[fileManager generatedNameForFile:child.title withObjectID:child.guid]])
        {
            if ([[AccountManager sharedManager] isAccountActive:cellWrapper.accountUUID])
            {
                [self.favoriteDownloadManagerDelegate setSelectedAccountUUID:cellWrapper.accountUUID];
                [self.favoriteDownloadManagerDelegate setTenantID:cellWrapper.tenantID];
                [[PreviewManager sharedManager] previewItem:child delegate:self.favoriteDownloadManagerDelegate accountUUID:cellWrapper.accountUUID tenantID:cellWrapper.tenantID];
            }
        }
        else
        {
            [self showDocument];
        }
    }
}

- (void)showDocument
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)self.tableView.dataSource;
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    RepositoryItem *repoItem = [[dataSource cellDataObjectForIndexPath:indexPath] anyRepositoryItem];
    NSString *fileName = [fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid];
    NSDictionary *downloadInfo = [fileManager downloadInfoForFilename:fileName];
    
    if (!downloadInfo)
    {
        // We can't do much without the downloadInfo
        displayErrorMessage(NSLocalizedString(@"docpreview.errorLoading", @"There was an issue with the preview please try again later"));
    }
    else
    {
        DownloadMetadata *downloadMetadata = [[[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo] autorelease];
        NSString *accountUUID = downloadMetadata.accountUUID;
        
        if ([[AlfrescoMDMLite sharedInstance] isSyncExpired:fileName withAccountUUID:accountUUID])
        {
            if ([[ConnectivityManager sharedManager] hasInternetConnection])
            {
                [[RepositoryServices shared] removeRepositoriesForAccountUuid:accountUUID];
                [[AlfrescoMDMLite sharedInstance] setServiceDelegate:self];
                [[AlfrescoMDMLite sharedInstance] loadRepositoryInfoForAccount:accountUUID];
            }
            else
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
        else
        {
            DocumentViewController *viewController = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
            
            if (downloadMetadata.key)
            {
                [viewController setFileName:downloadMetadata.key];
            }
            else
            {
                [viewController setFileName:fileName];
            }
            
            [viewController setFileMetadata:downloadMetadata];
            [viewController setCmisObjectId:downloadMetadata.objectId];
            NSString * pathToSyncedFile = [fileManager pathToFileDirectory:fileName];
            [viewController setFilePath:pathToSyncedFile];
            [viewController setHidesBottomBarWhenPushed:YES];
            
            [viewController setPresentNewDocumentPopover:NO];
            [viewController setSelectedAccountUUID:accountUUID];
            [viewController setTenantID:downloadMetadata.tenantID];
            
            [viewController setCanEditDocument:repoItem.canSetContentStream];
            [viewController setContentMimeType:repoItem.contentStreamMimeType];
            [viewController setShowReviewButton:NO];
            [viewController setIsRestrictedDocument:[[AlfrescoMDMLite sharedInstance] isRestrictedSync:fileName]];
            
            [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
            [viewController release];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[tableView dataSource];
    FavoriteTableCellWrapper *cellWrapper = [dataSource cellDataObjectForIndexPath:indexPath];
	RepositoryItem *child = [cellWrapper anyRepositoryItem];
	
    if (child)
    {
        if (cellWrapper.syncStatus != SyncStatusFailed && cellWrapper.syncStatus != SyncStatusCancelled)
        {
            if (cellWrapper.isActivityInProgress == YES)
            {
                if (cellWrapper.activityType == SyncActivityTypeDownload)
                {
                    if ([[FavoriteDownloadManager sharedManager] isManagedDownload:child.guid])
                    {
                        [[FavoriteDownloadManager sharedManager] clearDownload:child.guid];
                    }
                }
                else if (cellWrapper.activityType == SyncActivityTypeUpload)
                {
                    [[FavoritesUploadManager sharedManager] clearUpload:[[cellWrapper uploadInfo] uuid]];
                }
                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
            }
            else
            {
                BOOL connectionAvailable = [[ConnectivityManager sharedManager] hasInternetConnection];
                if (connectionAvailable && [[AccountManager sharedManager] isAccountActive:cellWrapper.accountUUID])
                {
                    [tableView setAllowsSelection:NO];
                    [self startHUDInTableView:tableView];
                    
                    ObjectByIdRequest *object = [[ObjectByIdRequest defaultObjectById:child.guid accountUUID:cellWrapper.accountUUID tenantID:cellWrapper.tenantID] retain];
                    [object setDelegate:self];
                    [object startAsynchronous];
                    //[self setMetadataDownloader:object];
                    [object release];
                    
                }
                else
                {
                    // TODO: MDMLite expiry check
                    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
                    NSString *fileName = [fileManager generatedNameForFile:child.title withObjectID:child.guid];
                    if (![[AlfrescoMDMLite sharedInstance] isSyncExpired:fileName withAccountUUID:cellWrapper.accountUUID])
                    {
                        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                                              cmisObject:child
                                                                                                             accountUUID:cellWrapper.accountUUID
                                                                                                                tenantID:cellWrapper.tenantID];
                        [viewController setCmisObjectId:child.guid];
                        [viewController setMetadata:child.metadata];
                        [viewController setSelectedAccountUUID:cellWrapper.accountUUID];
                        [viewController setTenantID:cellWrapper.tenantID];
                        
                        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
                        [viewController release];
                    }
                }
            }
        }
        
        if (cellWrapper.isPreviewInProgress == YES)
        {
            [[PreviewManager sharedManager] cancelPreview];
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }
        
        
        UploadInfo *uploadInfo = cellWrapper.uploadInfo;
        DownloadInfo *downloadInfo = nil;
        
        if ((cellWrapper.syncStatus == SyncStatusFailed || cellWrapper.syncStatus == SyncStatusCancelled) && cellWrapper.isPreviewInProgress == NO)
        {
            self.wrapperToRetry = cellWrapper;
            
            if (IS_IPAD)
            {
                FailedTransferDetailViewController *viewController = nil;
                
                if (cellWrapper.activityType == SyncActivityTypeUpload)
                {
                    viewController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"sync.failureDetail.title", @"Upload failed popover title")
                                                                                       message:[self.wrapperToRetry.uploadInfo.error localizedDescription]];
                    
                    [viewController setUserInfo:self.wrapperToRetry.uploadInfo];
                }
                else
                {
                    downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:cellWrapper.repositoryItem] autorelease];
                    viewController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"sync.failureDetail.title", @"Download failed popover title")
                                                                                       message:[downloadInfo.error localizedDescription]];
                    [viewController setUserInfo:downloadInfo];
                }
                
                [viewController setCloseTarget:self];
                [viewController setCloseAction:@selector(closeFailedUpload:)];
                
                UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
                [self setPopover:popoverController];
                [popoverController setPopoverContentSize:viewController.view.frame.size];
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
                NSError * syncError;
                
                if (cellWrapper.activityType == SyncActivityTypeUpload)
                {
                    syncError = uploadInfo.error;
                }
                else
                {
                    downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:cellWrapper.repositoryItem] autorelease];
                    syncError = downloadInfo.error;
                }
                [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sync.failureDetail.title", @"Upload Failed")
                                             message:[syncError localizedDescription]
                                            delegate:self
                                   cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
                                   otherButtonTitles:NSLocalizedString(@"Retry", @"Retry"), nil] autorelease] show];
                
            }
        }
    }
}


#pragma mark UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [[FavoriteManager sharedManager] retrySyncForItem:self.wrapperToRetry];
    }
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
    }
    
    [[FavoriteManager sharedManager] retrySyncForItem:self.wrapperToRetry];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[[AccountManager sharedManager] activeAccounts] count] < 2)
    {
        return 60.0f;
    }
    return 84.0;
}

#pragma mark - ASIHTTPRequestDelegate

- (void)favoriteManager:(FavoriteManager *)favoriteManager requestFinished:(NSArray *)favorites
{
    [self.favoriteDownloadManagerDelegate setRepositoryItems:favorites];
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    [dataSource setFavorites:favorites];
    [dataSource refreshData];
    [self.tableView reloadData];
    
    [self stopHUD];
    [self dataSourceFinishedLoadingWithSuccess:YES];
    self.favoritesRequest = nil;
    
    if (self.isViewLoaded && self.view.window)
    {
        [self performSelector:@selector(checkForSyncErrorsAndDisplay) withObject:nil afterDelay:delayToShowErrors];
    }
}

- (void)favoriteManagerRequestFailed:(FavoriteManager *)favoriteManager
{
    AlfrescoLogDebug(@"Request in FavoriteManager failed! %@", [favoriteManager.error description]);
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    NSArray *sortedFavorites = [[[FavoriteManager sharedManager] getFavoritesFromLocalIfAvailable] retain];
    [dataSource setFavorites:sortedFavorites];
    [sortedFavorites release];
    
    [dataSource refreshData];
    [self.tableView reloadData];
    
    [self stopHUD];
    [self performSelector:@selector(dataSourceFinishedLoadingWithSuccess:) withObject:nil afterDelay:2.0];
    self.favoritesRequest = nil;
}

- (void)favoriteManagerMDMInfoReceived
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];
    if ([request isKindOfClass:[ObjectByIdRequest class]])
    {
        ObjectByIdRequest *object = (ObjectByIdRequest*) request;
        
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                              cmisObject:[object repositoryItem]
                                                                                             accountUUID:[object accountUUID]
                                                                                                tenantID:nil];
        [viewController setCmisObjectId:object.repositoryItem.guid];
        [viewController setMetadata:object.repositoryItem.metadata];
        [viewController setSelectedAccountUUID:object.accountUUID];
        [viewController setTenantID:object.tenantID];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [viewController release];
    }
    
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];
    [self stopHUD];
}


#pragma mark - MBProgressHUD Helper Methods

- (void)startHUDInTableView:(UITableView *)tableView
{
    if(!self.HUD)
    {
        [self setHUD:createAndShowProgressHUDForView(tableView)];
    }
}

- (void)stopHUD
{
    if (self.HUD)
    {
        stopProgressHUD(self.HUD);
        self.HUD = nil;
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    if (![self.favoritesRequest isExecuting])
    {
        [self loadFavorites:SyncTypeManual];
    }
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
    return (self.HUD != nil);
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
    return [self lastUpdated];
}


#pragma mark - NotificationCenter methods

- (void)detailViewControllerChanged:(NSNotification *)notification
{
    id sender = [notification object];
    if (sender && ![sender isEqual:self])
    {
        [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)syncPreferenceChangedNotification:(NSNotification *)notification
{
    [self updateTitle];
}

#pragma mark - Private Class Functions

- (void)checkForSyncErrorsAndDisplay
{
    if ([[FavoriteManager sharedManager] didEncounterObstaclesDuringSync])
    {
        NSMutableDictionary *syncErrors = [[FavoriteManager sharedManager] syncObstacles];
        FavoritesErrorsViewController *errors = [[FavoritesErrorsViewController alloc] initWithErrors:syncErrors];
        errors.modalPresentationStyle = UIModalPresentationFormSheet;
        [IpadSupport presentModalViewController:errors withNavigation:nil];
        [errors release];
    }
}

- (NSIndexPath *)indexPathForNodeWithGuid:(NSString *)itemGuid
{
    NSIndexPath *indexPath = nil;
    NSMutableArray *items = self.folderDatasource.children;
    itemGuid = [itemGuid lastPathComponent];
    
    if (itemGuid != nil && items != nil)
    {
        // Define a block predicate to search for the item being viewed
        BOOL (^matchesRepostoryItem)(FavoriteTableCellWrapper *, NSUInteger, BOOL *) = ^ (FavoriteTableCellWrapper *cellWrapper, NSUInteger idx, BOOL *stop)
        {
            BOOL matched = NO;
            RepositoryItem *repositoryItem = [cellWrapper anyRepositoryItem];
            if ([[repositoryItem.guid lastPathComponent] isEqualToString:itemGuid] == YES)
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

- (void)updateTitle
{
    self.title = [FavoriteManager sharedManager].isSyncPreferenceEnabled ? NSLocalizedString(@"favorite-view.sync.title", @"Synced Documents") : NSLocalizedString(@"favorite-view.favorite.title", @"Favorite Documents");
}

/**
 * Accounts list changed Notification
 */
- (void)accountsListChanged:(NSNotification *)notification
{
    NSString *accountUUID = notification.userInfo[@"uuid"];
    NSString *changeType = notification.userInfo[@"type"];

    if (accountUUID != nil && ![accountUUID isEqualToString:@""] && changeType != kAccountUpdateNotificationDelete)
    {
        if (![self.favoritesRequest isExecuting])
        {
            [self loadFavorites:SyncTypeAutomatic];
        }
    }
}

- (void)mdmServiceManagerRequestFinishedForAccount:(NSString*)accountUUID withSuccess:(BOOL)success
{
    if (success)
    {
        NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
        
        [self showDocument];
        [self loadFavorites:SyncTypeManual];
        [self.tableView selectRowAtIndexPath:selectedRow animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (void)handleFilesExpired:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSArray *expiredSyncFiles = userInfo[@"expiredSyncFiles"];
    NSString *currentDetailViewControllerObjectID = [[IpadSupport getCurrentDetailViewControllerObjectID] lastPathComponent];
    
    for (NSString *docTitle in expiredSyncFiles)
    {
        NSString *docGuid = [docTitle stringByDeletingPathExtension];
        NSIndexPath *index = [self indexPathForNodeWithGuid:docGuid];
        
        [[self.tableView cellForRowAtIndexPath:index] setAlpha:0.5];
        
        if ([currentDetailViewControllerObjectID hasSuffix:docGuid])
        {
            [self.tableView deselectRowAtIndexPath:index animated:YES];
        }
    }
}

@end
