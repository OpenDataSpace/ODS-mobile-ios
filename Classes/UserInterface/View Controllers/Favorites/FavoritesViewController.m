//
//  FavoritesViewController.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
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

#import "RepositoryPreviewManagerDelegate.h"

@interface FavoritesViewController ()

- (void) loadFavorites;
- (void) startHUD;
- (void) stopHUD;

//- (void) noFavoritesForRepositoryError;
//- (void) failedToFetchFavoritesError;

@end

@implementation FavoritesViewController

@synthesize HUD;
@synthesize favoritesRequest;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;

@synthesize dirWatcher = _dirWatcher;
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
    
    // NSUserDefaults * preferences = [NSUserDefaults standardUserDefaults];
    
    if([[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"didAskToSync"] == NO)
    {
        UIAlertView *syncAlert = [[UIAlertView alloc] initWithTitle:@"Sync Docs"
                                                            message:@"Would you like to Sync your favorite Docs?"
                                                           delegate:self 
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"No", @"Yes", nil];
        
        [syncAlert show];
        [syncAlert release];
        
        [[FDKeychainUserDefaults standardUserDefaults] setBool:YES forKey:@"didAskToSync"];
    }
    
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
    // [preferences setObject:@"Yes" forKey:kSyncPreference];
    // [preferences synchronize];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Synced Documents", @"Favorite Documents");
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    if(IS_IPAD) {
        self.clearsSelectionOnViewWillAppear = NO;
    }
    
    NSURL *applicationDocumentsDirectoryURL = [NSURL fileURLWithPath:[self applicationSyncedDocsDirectory] isDirectory:YES];
    
    FavoritesTableViewDataSource *dataSource = [[FavoritesTableViewDataSource alloc] initWithURL:applicationDocumentsDirectoryURL];
    
    [self setFolderDatasource:dataSource];
    [[self tableView] setDataSource:dataSource];
    [dataSource release];
    
    
    [self setDirWatcher:[DirectoryWatcher watchFolderWithPath:[self applicationSyncedDocsDirectory] 
                                                     delegate:self]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationFavoriteDownloadQueueChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[self tableView] reloadData];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kNotificationUploadFinished object:nil];    
}

- (void) showLiveFavoritesList:(BOOL)showLive
{
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    BOOL temp = NO;
    
    if([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference] == NO)
    {
        temp = YES;
    }
    else {
        
        temp = showLive;
    }
    
    [dataSource setShowLiveList:temp];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)loadFavorites 
{
    //[self startHUD];
    
    [[FavoriteManager sharedManager] setDelegate:self];
    
    //if ([[[FavoriteDownloadManager sharedManager] activeDownloads] count] == 0) {
        
        [[FavoriteManager sharedManager] startFavoritesRequest];
        
        
   // }
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
    
    if([dataSource showLiveList] == YES && ![[FavoriteFileDownloadManager sharedInstance] downloadExistsForKey:[[[dataSource.children objectAtIndex:indexPath.row] repositoryItem] title]])
    {
        RepositoryItem *child = nil;
        FavoriteTableCellWrapper *cellWrapper = nil;
        
        cellWrapper = [dataSource.favorites objectAtIndex:[indexPath row]];
        child = [cellWrapper anyRepositoryItem];
        
        
        [self.favoriteDownloadManagerDelegate setSelectedAccountUUID:cellWrapper.accountUUID];
        
        [[PreviewManager sharedManager] previewItem:child delegate:self.favoriteDownloadManagerDelegate accountUUID:cellWrapper.accountUUID tenantID:cellWrapper.tenantID];
    }
    else {
        
        RepositoryItem * repoItem = [[dataSource cellDataObjectForIndexPath:indexPath] repositoryItem];
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
        [viewController setIsDownloaded:YES];
        [viewController setSelectedAccountUUID:[downloadMetadata accountUUID]];  
        
        if(downloadInfo)
            [downloadMetadata release];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
        [viewController release];
    }
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate
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
    
    [self showLiveFavoritesList:YES];
    
    [self showLiveFavoritesList:YES];
    
    [self.favoriteDownloadManagerDelegate setRepositoryItems:[[favorites mutableCopy] autorelease]];
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
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
    
    [self showLiveFavoritesList:NO];
    
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    [dataSource refreshData];
    [self.tableView reloadData];
    
    [self dataSourceFinishedLoadingWithSuccess:NO];
    [self stopHUD];
    favoritesRequest = nil;
}


#pragma mark - MBProgressHUD Helper Methods
- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.navigationController.view);
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

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

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

#pragma mark - File System 

#pragma mark - File system support

- (NSString *)applicationSyncedDocsDirectory
{
	NSString * favDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"SyncedDocs"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory; 
	// [paths release];
    if(![fileManager fileExistsAtPath:favDir isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:favDir withIntermediateDirectories:YES attributes:nil error:&error];
        
        if(error) {
            NSLog(@"Error creating the %@ folder: %@", @"Documents", [error description]);
            return  nil;
        }
    }
    
	return favDir;
}

#pragma mark -
#pragma mark DirectoryWatcherDelegate methods

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
    
    FavoritesTableViewDataSource *folderDataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    if(folderDataSource.showLiveList == NO)
    {
        [folderDataSource refreshData];
        [self.tableView reloadData];
    }
}

#pragma mark - UIAlertView Delegates

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) 
    {
        
        [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:kSyncPreference];
    }
    else 
    {
        [[FDKeychainUserDefaults standardUserDefaults] setBool:YES forKey:kSyncPreference];
    }
    
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
    
    [self loadFavorites];
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

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
    //[self performSelector:@selector(loadFavorites) withObject:nil afterDelay:0.5];

    [self loadFavorites];
}

@end
