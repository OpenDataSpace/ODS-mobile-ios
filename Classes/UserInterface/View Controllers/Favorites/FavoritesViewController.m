
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
#import "IFTextViewTableView.h"
#import "Theme.h"
#import "IFTemporaryModel.h"
#import "IFValueCellController.h"
#import "SBJSON.h"
#import "FavoritesHttpRequest.h"
#import "AlfrescoAppDelegate.h"
#import "TableCellViewController.h"
#import "RepositoryServices.h"
#import "ObjectByIdRequest.h"
#import "CMISTypeDefinitionHTTPRequest.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"
#import "Utility.h"
#import "MetaDataTableViewController.h"
#import "WhiteGlossGradientView.h"
#import "ThemeProperties.h"
#import "TableViewHeaderView.h"
#import "AccountManager.h"
#import "FileUtils.h"
#import "FavoriteFileDownloadManager.h"
#import "PreviewManager.h"
#import "FavoritesTableViewDataSource.h"
#import "FavoritesDownloadManagerDelegate.h"
#import "FavoriteTableCellWrapper.h"
#import "MetaDataCellController.h"
#import "RepositoryPreviewManagerDelegate.h"
#import "Reachability.h"
#import "ConnectivityManager.h"
#import "FavoritesUploadManager.h"
#import "FailedTransferDetailViewController.h"
#import "FavoritesErrorsViewController.h"

static const NSInteger delayToShowErrors = 5.0f;

@interface FavoritesViewController ()

@property (nonatomic, assign) BOOL shownErrorsBefore;

- (void) loadFavorites:(SyncType)syncType;
- (void)startHUDInTableView:(UITableView *)tableView;
- (void) stopHUD;

//- (void) noFavoritesForRepositoryError;
//- (void) failedToFetchFavoritesError;
- (void)checkForSyncErrorsAndDisplay;

@end

@implementation FavoritesViewController

@synthesize HUD;
@synthesize favoritesRequest;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;
@synthesize folderDatasource = _folderDatasource;
@synthesize favoriteDownloadManagerDelegate = _favoriteDownloadManagerDelegate;

@synthesize wrapperToRetry = _wrapperToRetry;
@synthesize popover = _popover;
@synthesize shownErrorsBefore;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View lifecycle
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [favoritesRequest clearDelegatesAndCancel];
    
    [HUD release];
    [favoritesRequest release];
    [downloadProgressBar release];
    [_refreshHeaderView release];
    [_lastUpdated release];
    [_wrapperToRetry release];
    [_popover release];
    
    [super dealloc];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [HUD setTaskInProgress:NO];
    [HUD hide:YES];
    [HUD release];
    HUD = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) name:kNotificationAccountListUpdated object:nil];
    [super viewDidAppear:animated];
    
    if (!self.shownErrorsBefore) {
        [self checkForSyncErrorsAndDisplay];
        self.shownErrorsBefore = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    if ([[FavoriteManager sharedManager] isFirstUse])
    {
        if([[[AccountManager sharedManager] activeAccounts] count] > 0)
        {
            [self startHUDInTableView:self.tableView];
            
        }
        [[FavoriteManager sharedManager] showSyncPreferenceAlert];
        
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Synced Documents", @"Favorite Documents");
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    if(IS_IPAD)
    {
        self.clearsSelectionOnViewWillAppear = NO;
    }
    
    
    FavoritesTableViewDataSource *dataSource = [[FavoritesTableViewDataSource alloc] init];
    
    [self setFolderDatasource:dataSource];
    [[self tableView] setDataSource:dataSource];
    [dataSource release];
    
    [self.folderDatasource setFavorites:[[FavoriteManager sharedManager] getLiveListIfAvailableElseLocal]];
    
    [self.folderDatasource refreshData];
    [self.tableView reloadData];
    
    [[FavoriteManager sharedManager] setDelegate:self];
    
    if ([[FavoriteManager sharedManager] isFirstUse] == NO)
    {
        [self loadFavorites:IsManualSync];
        
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
    [favoriteDownloaderDelegate setTableView:[self tableView]];  
    [favoriteDownloaderDelegate setNavigationController:[self navigationController]];
    [self setFavoriteDownloadManagerDelegate:favoriteDownloaderDelegate];
    [favoriteDownloaderDelegate release];
    
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kNotificationUploadFinished object:nil];
    self.shownErrorsBefore = NO;
}

- (void) loadFavorites:(SyncType)syncType
{
    if([[[AccountManager sharedManager] activeAccounts] count] > 0)
    {
        [self startHUDInTableView:self.tableView];
        [[FavoriteManager sharedManager] setDelegate:self];
        [[FavoriteManager sharedManager] startFavoritesRequest:syncType];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dataSourceFinishedLoadingWithSuccess:(BOOL) wasSuccessful
{
    if (wasSuccessful)
    {
        [self setLastUpdated:[NSDate date]];
        [self.refreshHeaderView refreshLastUpdatedDate];
    }
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

#pragma mark - UITableViewDelegate methods

-(NSIndexPath *) tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *) indexPath
{
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[tableView dataSource];
    UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
    FavoriteTableCellWrapper *cellWrapper = [dataSource.favorites objectAtIndex:[indexPath row]];
    
    if (IS_IPAD)
    {
        [cellWrapper changeFavoriteIconForCell:cell selected:NO];
    }
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[tableView dataSource];
    
    RepositoryItem *child = nil;
    FavoriteTableCellWrapper *cellWrapper = nil;
    
    cellWrapper = [dataSource.favorites objectAtIndex:[indexPath row]];
    child = [cellWrapper anyRepositoryItem];
    if (IS_IPAD)
    {
        [cellWrapper changeFavoriteIconForCell:[self.tableView cellForRowAtIndexPath:indexPath] selected:YES];
    }
    
    if(cellWrapper.isActivityInProgress == NO)
    {
        if(![fileManager downloadExistsForKey:[fileManager generatedNameForFile:child.title withObjectID:child.guid]]) 
        {
            
            [self.favoriteDownloadManagerDelegate setSelectedAccountUUID:cellWrapper.accountUUID];
            
            [[PreviewManager sharedManager] previewItem:child delegate:self.favoriteDownloadManagerDelegate accountUUID:cellWrapper.accountUUID tenantID:cellWrapper.tenantID];
        }
        else {
            
            // RepositoryItem * repoItem = [[dataSource cellDataObjectForIndexPath:indexPath] repositoryItem];
            RepositoryItem * repoItem = [[dataSource cellDataObjectForIndexPath:indexPath] anyRepositoryItem];
            
            NSString *fileName = [fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid];
            DownloadMetadata *downloadMetadata =  nil; 
            
            NSDictionary *downloadInfo = [fileManager downloadInfoForFilename:fileName];
            
            if (downloadInfo)
            {
                downloadMetadata = [[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo];
                
            }
            
            DocumentViewController *viewController = [[DocumentViewController alloc] 
                                                      initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
            
            if (downloadMetadata && downloadMetadata.key)
            {
                [viewController setFileName:downloadMetadata.key];
            }
            else
            {
                [viewController setFileName:fileName];
            }
            
            RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[downloadMetadata accountUUID] 
                                                                                           tenantID:[downloadMetadata tenantID]];
            NSString *currentRepoId = [repoInfo repositoryId];
            if (downloadMetadata && [[downloadMetadata repositoryId] isEqualToString:currentRepoId])
            {
                viewController.fileMetadata = downloadMetadata;
            }
            
            [viewController setCmisObjectId:[downloadMetadata objectId]];
            NSString * pathToSyncedFile = [fileManager pathToFileDirectory:fileName];
            [viewController setFilePath:pathToSyncedFile];
            [viewController setContentMimeType:[downloadMetadata contentStreamMimeType]];
            [viewController setHidesBottomBarWhenPushed:YES];
            
            [viewController setPresentNewDocumentPopover:NO];
            [viewController setSelectedAccountUUID:[downloadMetadata accountUUID]]; 
            
            [viewController setCanEditDocument:repoItem.canSetContentStream];
            [viewController setContentMimeType:repoItem.contentStreamMimeType];
            [viewController setShowReviewButton:YES];
            //[viewController setPresentNewDocumentPopover:self.presentNewDocumentPopover];
            //[viewController setPresentEditMode:self.presentEditMode];
            
            if(downloadInfo)
                [downloadMetadata release];
            
            
            if(!IS_IPAD)
            {
                [self.navigationController pushViewController:viewController animated:NO];
            }
            else 
            {
                [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
            }
            
            
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
        if(cellWrapper.syncStatus != SyncFailed && cellWrapper.syncStatus != SyncCancelled)
        {
            if(cellWrapper.isActivityInProgress == YES)
            {
                if (cellWrapper.activityType == Download)
                {
                    if([[FavoriteDownloadManager sharedManager] isManagedDownload:child.guid])
                    {
                        [[FavoriteDownloadManager sharedManager] clearDownload:child.guid];
                    }
                }
                else if (cellWrapper.activityType == Upload)
                {
                    [[FavoritesUploadManager sharedManager] clearUpload:[[cellWrapper uploadInfo] uuid]];
                }
                [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
            }
            else
            {
                BOOL connectionAvailable = [[ConnectivityManager sharedManager] hasInternetConnection];
                if(connectionAvailable)
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
                    
                    DownloadMetadata *downloadMetadata =  nil; 
                    
                    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
                    
                    NSDictionary *downloadInfo = [fileManager downloadInfoForFilename:[fileManager generatedNameForFile:child.title withObjectID:child.guid]]; 
                    
                    if (downloadInfo)
                    {
                        downloadMetadata = [[[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo] autorelease];
                        
                    }
                    
                    MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                                          cmisObject:child 
                                                                                                         accountUUID:[cellWrapper accountUUID] 
                                                                                                            tenantID:cellWrapper.tenantID];
                    [viewController setCmisObjectId:child.guid];
                    [viewController setMetadata:child.metadata];
                    NSLog(@" =================== Meta Data: %@", downloadMetadata);
                    [viewController setSelectedAccountUUID:cellWrapper.accountUUID];
                    
                    [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
                    [viewController release];
                }
                
            }
            
        }
        
        if(cellWrapper.isPreviewInProgress == YES)
        {
            [[PreviewManager sharedManager] cancelPreview];
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }
        
        
        UploadInfo *uploadInfo = cellWrapper.uploadInfo;
        DownloadInfo *downloadInfo = nil;
        
        if ((cellWrapper.syncStatus == SyncFailed || cellWrapper.syncStatus == SyncCancelled) && cellWrapper.isPreviewInProgress == NO)
        {
            self.wrapperToRetry = cellWrapper;
            
            if (IS_IPAD)
            {
                FailedTransferDetailViewController *viewController = nil;
                
                if (cellWrapper.activityType == Upload)
                {
                    viewController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"sync.failureDetail.title", @"Upload failed popover title")
                                                                                       message:[self.wrapperToRetry.uploadInfo.error localizedDescription]];
                    
                    [viewController setUserInfo:self.wrapperToRetry.uploadInfo];
                }
                else {
                    
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
                NSError * syncError;
                
                if (cellWrapper.activityType == Upload) 
                {
                    syncError = uploadInfo.error;
                }
                else 
                {
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
        if (buttonIndex == alertView.cancelButtonIndex)
        {
            //[[UploadsManager sharedManager] clearUpload:self.uploadToDismiss.uuid];
        }
        else {
            //[[UploadsManager sharedManager] retryUpload:self.uploadToDismiss.uuid];
            
            [[FavoriteManager sharedManager] retrySyncForItem:self.wrapperToRetry];
        }
}

#pragma mark - UIPopoverController Delegate methods

// This is called when the popover was dismissed by the user by tapping in another part of the screen,
// We want to to clear the upload
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    /*
     if(self.uploadToDismiss)
     {
     [[FavoritesUploadManager sharedManager] clearUpload:self.uploadToDismiss.uuid];
     }
     else 
     {
     [[FavoriteDownloadManager sharedManager] clearDownload:self.downloadToDismiss.cmisObjectId];
     }
     */
    
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

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath 
{
    if ([[[AccountManager sharedManager] activeAccounts] count] < 2)
    {
        return 60.0f;
    }
    return 84.0;
}

//- (void) favoriteButtonPressedAtIndexPath:(NSIndexPath *) indexPath
-(void) favoriteButtonPressed:(UIControl*) button withEvent:(UIEvent *)event
{
    /*
     NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
     if (indexPath != nil)
     {
     FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];    
     FavoriteTableCellWrapper *cellWrapper = [dataSource cellDataObjectForIndexPath:indexPath];
     
     if (cellWrapper.document == IsFavorite) 
     {
     cellWrapper.document = IsNotFavorite;
     }
     else
     {
     cellWrapper.document = IsFavorite;
     }
     
     [cellWrapper favoriteOrUnfavoriteDocument:(FavoriteTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath]];
     
     }
     */
}

#pragma mark - ASIHTTPRequestDelegate

- (void)favoriteManager:(FavoriteManager *)favoriteManager requestFinished:(NSArray *)favorites
{
    [self.favoriteDownloadManagerDelegate setRepositoryItems:[[favorites mutableCopy] autorelease]];
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    dataSource.favorites = nil;
    [dataSource setFavorites:favorites];
    
    [dataSource refreshData];
    [self.tableView reloadData];
    
    [self dataSourceFinishedLoadingWithSuccess:YES];
    [self stopHUD];
    favoritesRequest = nil;
    
    if (self.isViewLoaded && self.view.window)
    {
        [self performSelector:@selector(checkForSyncErrorsAndDisplay) withObject:nil afterDelay:delayToShowErrors];
    }
}

- (void)favoriteManagerRequestFailed:(FavoriteManager *)favoriteManager
{
    NSLog(@"Request in FavoriteManager failed! %@", [favoriteManager.error description]);
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    NSArray *sortedFavorites = [[[FavoriteManager sharedManager] getFavoritesFromLocalIfAvailable] retain];
    [dataSource setFavorites:sortedFavorites];
    [sortedFavorites release];
    
    [dataSource refreshData];
    [self.tableView reloadData];
    
    [self dataSourceFinishedLoadingWithSuccess:NO];
    [self stopHUD];
    favoritesRequest = nil;
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
        [viewController setSelectedAccountUUID:[object accountUUID]];
        
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
    if (![favoritesRequest isExecuting])
    {
        [self loadFavorites:IsManualSync];
    }
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
    return (HUD != nil);
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
    return [self lastUpdated];
}


#pragma mark - NotificationCenter methods

- (void)detailViewControllerChanged:(NSNotification *) notification
{
    id sender = [notification object];
    
    if (sender && ![sender isEqual:self])
    {
        [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
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

@end
