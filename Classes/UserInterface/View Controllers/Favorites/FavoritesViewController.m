
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
#import "FavoriteFileUtils.h"
#import "FavoriteFileDownloadManager.h"
#import "PreviewManager.h"
#import "FavoritesTableViewDataSource.h"
#import "FavoritesDownloadManagerDelegate.h"
#import "FavoriteTableCellWrapper.h"
#import "MetaDataCellController.h"
#import "RepositoryPreviewManagerDelegate.h"
#import "Reachability.h"
#import "ConnectivityManager.h"

@interface FavoritesViewController ()

- (void) loadFavorites;
- (void)startHUDInTableView:(UITableView *)tableView;
- (void) stopHUD;

//- (void) noFavoritesForRepositoryError;
//- (void) failedToFetchFavoritesError;

@end

@implementation FavoritesViewController

@synthesize HUD;
@synthesize favoritesRequest;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;
@synthesize folderDatasource = _folderDatasource;
@synthesize favoriteDownloadManagerDelegate = _favoriteDownloadManagerDelegate;

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
        [self loadFavorites];
        
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationFavoriteDownloadQueueChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
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
}

- (void) loadFavorites
{
    if([[[AccountManager sharedManager] activeAccounts] count] > 0)
    {
        [self startHUDInTableView:self.tableView];
        [[FavoriteManager sharedManager] setDelegate:self];
        [[FavoriteManager sharedManager] startFavoritesRequest];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[tableView dataSource];
    
    if(![[FavoriteFileDownloadManager sharedInstance] downloadExistsForKey:[[[dataSource.children objectAtIndex:indexPath.row] repositoryItem] title]])
    {
        RepositoryItem *child = nil;
        FavoriteTableCellWrapper *cellWrapper = nil;
        
        cellWrapper = [dataSource.favorites objectAtIndex:[indexPath row]];
        child = [cellWrapper anyRepositoryItem];
        
        
        [self.favoriteDownloadManagerDelegate setSelectedAccountUUID:cellWrapper.accountUUID];
        
        [[PreviewManager sharedManager] previewItem:child delegate:self.favoriteDownloadManagerDelegate accountUUID:cellWrapper.accountUUID tenantID:cellWrapper.tenantID];
    }
    else {
        
        // RepositoryItem * repoItem = [[dataSource cellDataObjectForIndexPath:indexPath] repositoryItem];
        RepositoryItem * repoItem = [[dataSource cellDataObjectForIndexPath:indexPath] anyRepositoryItem];
        
        NSString *fileName = repoItem.title;
        DownloadMetadata *downloadMetadata =  nil; 
        
        NSDictionary *downloadInfo = [[FavoriteFileDownloadManager sharedInstance] downloadInfoForFilename:fileName];
        
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
        [viewController setFilePath:[FavoriteFileUtils pathToSavedFile:fileName]];
        [viewController setContentMimeType:[downloadMetadata contentStreamMimeType]];
        [viewController setHidesBottomBarWhenPushed:YES];
        
        [viewController setPresentNewDocumentPopover:NO];
        [viewController setSelectedAccountUUID:[downloadMetadata accountUUID]]; 
        
        [viewController setCanEditDocument:repoItem.canSetContentStream];
        [viewController setContentMimeType:repoItem.contentStreamMimeType];
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[tableView dataSource];    
    FavoriteTableCellWrapper *cellWrapper = [dataSource cellDataObjectForIndexPath:indexPath];
    
	RepositoryItem *child = [cellWrapper anyRepositoryItem];
    //UploadInfo *uploadInfo = cellWrapper.uploadInfo;
	
    if (child)
    {
        if (cellWrapper.isDownloadingPreview)
        {
            if([[FavoriteDownloadManager sharedManager] isManagedDownload:child.guid])
            {
                [[FavoriteDownloadManager sharedManager] clearDownload:child.guid];
            }
            else 
            {
                [[PreviewManager sharedManager] cancelPreview];
                
            }
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        }
        else
        {
            if([[FavoriteManager sharedManager] listType] == IsLive)
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
                
                NSDictionary *downloadInfo = [[FavoriteFileDownloadManager sharedInstance] downloadInfoForFilename:child.title];
                
                if (downloadInfo)
                {
                    downloadMetadata = [[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo];
                    
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
    /*
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
     [self.popover presentPopoverFromRect:cell.accessoryView.frame inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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
     */
}


- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath 
{
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
    /*
     NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
     NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
     favorites = [favorites sortedArrayUsingDescriptors:sortDescriptors];
     [sortDescriptor release];
     */
    
    // NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:favorites, nil] 
    //                                                                    forKeys:[NSArray arrayWithObjects:@"favorites", nil]];
    
    //[self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
    //[self updateAndReload];
    
    //[self setTableDatasource];
    
    //[self showLiveFavoritesList:YES];
    
    //[self showLiveFavoritesList:YES];
    
    [self.favoriteDownloadManagerDelegate setRepositoryItems:[[favorites mutableCopy] autorelease]];
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    dataSource.favorites = nil;
    [dataSource setFavorites:favorites];
    
    [dataSource refreshData];
    [self.tableView reloadData];
    
    [self dataSourceFinishedLoadingWithSuccess:YES];
    [self stopHUD];
    favoritesRequest = nil;
    
}

- (void)favoriteManagerRequestFailed:(FavoriteManager *)favoriteManager
{
    NSLog(@"Request in FavoriteManager failed! %@", [favoriteManager.error description]);
    
    //[self showLiveFavoritesList:NO];
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    [dataSource setFavorites:[[FavoriteManager sharedManager] getFavoritesFromLocalIfAvailable]];
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
        [self loadFavorites];
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
        //self.selectedFile = nil;
        
        [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark - DownloadManager Notification methods

- (void)downloadQueueChanged:(NSNotification *)notification
{
    NSArray *failedDownloads = [[FavoriteDownloadManager sharedManager] failedDownloads];
    NSInteger activeCount = [[[FavoriteDownloadManager sharedManager] activeDownloads] count];
    
    
    if ([failedDownloads count] > 0)
    {
        [self.navigationController.tabBarItem setBadgeValue:@"!"];
    }
    else if (activeCount > 0)
    {
        [self.navigationController.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%d", activeCount]];
    }
    else 
    {
        [self.navigationController.tabBarItem setBadgeValue:nil];
    }
}


/*
 Listening to the reachability changes to get updated list
 */
- (void)reachabilityChanged:(NSNotification *)notification
{
    //BOOL connectionAvailable = [[ConnectivityManager sharedManager] hasInternetConnection];
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    [dataSource setFavorites:[[FavoriteManager sharedManager] getLiveListIfAvailableElseLocal]];
    
    [dataSource refreshData];
    [self.tableView reloadData];
    
}


@end
