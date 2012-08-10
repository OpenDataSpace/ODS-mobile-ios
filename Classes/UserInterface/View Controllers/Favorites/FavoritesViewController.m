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

#import "FavoritesTableViewDataSource.h"

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    NSUserDefaults * preferences = [NSUserDefaults standardUserDefaults];
    
    if([preferences objectForKey:kSyncPreference] == nil)
    {
        UIAlertView *syncAlert = [[UIAlertView alloc] initWithTitle:@"Sync Docs"
                                                        message:@"Would you like to Sync your favorite Docs?"
                                                       delegate:self 
                                              cancelButtonTitle:nil 
                                              otherButtonTitles:@"No", @"Yes", nil];
        
        [syncAlert show];
        [syncAlert release];
    }
    
    [preferences setObject:@"Yes" forKey:kSyncPreference];
    [preferences synchronize];
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
    
    [[self tableView] reloadData];
    
	// Pull to Refresh
    self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                arrowImageName:@"pull-to-refresh.png"
                                                                     textColor:[ThemeProperties pullToRefreshTextColor]] autorelease];
    [self.refreshHeaderView setDelegate:self];
    [self setLastUpdated:[NSDate date]];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];
    
}

-(void) setTableDatasourceFavorites:(NSArray*) items
{
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    if(items != nil)
    {
       [dataSource setFavorites:items];
    }
    [dataSource refreshData];
    [self.tableView reloadData];
}

- (void) showLiveFavoritesList:(BOOL)showLive
{
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    
    NSUserDefaults * preferences = [NSUserDefaults standardUserDefaults];
    
    BOOL temp = NO;
    
    if([[preferences objectForKey:kSyncPreference] isEqualToString:@"No"]) 
    {
        temp = YES;
    }
    else {
        
        if(showLive && [[[FavoriteDownloadManager sharedManager] activeDownloads] count] == 0)
        {
            temp = NO;
        }
        else {
            
           temp = showLive;
        }
    }
    
    [dataSource setShowLiveList:temp];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*
- (void)loadView
{
	// NOTE: This code circumvents the normal loading of the UITableView and replaces it with an instance
	// of IFTextViewTableView (which includes a workaround for the hit testing problems in a UITextField.)
	// Check the header file for IFTextViewTableView to see why this is important.
	//
	// Since there is no style accessor on UITableViewController (to obtain the value passed in with the
	// initWithStyle: method), the value is hard coded for this use case. Too bad.
    
	self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}
*/

- (void)loadFavorites 
{
    //[self startHUD];
    
    [[FavoriteManager sharedManager] setDelegate:self];
    
    if ([[[FavoriteDownloadManager sharedManager] activeDownloads] count] == 0) {
      
       [[FavoriteManager sharedManager] startFavoritesRequest];
        
        
    }
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

#pragma mark - Table view data source

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.favorites count];
}
 */

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] init];
    }
    
    //RepositoryItem *item = [self.favorites objectAtIndex:indexPath.row];
    //cell.textLabel.text = item.title;
    

    return cell;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FavoritesTableViewDataSource *dataSource = (FavoritesTableViewDataSource *)[tableView dataSource];
    NSString *key = [[dataSource sectionKeys] objectAtIndex:indexPath.section];
    
    /*
    if ([key isEqualToString:kDownloadManagerSection])
    {
        NSString *cellType = [dataSource cellDataObjectForIndexPath:indexPath];
        if ([cellType hasPrefix:kDownloadSummaryCellIdentifier])
        {
            ActiveDownloadsViewController *viewController = [[ActiveDownloadsViewController alloc] init];
            [viewController setTitle:NSLocalizedString(@"download.summary.title", @"In Progress")];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
        }
        else if ([cellType isEqualToString:kDownloadFailureSummaryCellIdentifier])
        {
            FailedDownloadsViewController *viewController = [[FailedDownloadsViewController alloc] init];
            [viewController setTitle:NSLocalizedString(@"download.failuresView.title", @"Download Failures")];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
        }
    }
      */
    //else
    if([dataSource showLiveList] == NO)
    {
        NSURL *fileURL = [dataSource cellDataObjectForIndexPath:indexPath];
        DownloadMetadata *downloadMetadata = [dataSource downloadMetadataForIndexPath:indexPath];
        NSString *fileName = [[fileURL path] lastPathComponent];
        
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
        
        NSLog(@"=========== %@ ======= %@ ========== %@", [downloadMetadata accountUUID], [downloadMetadata tenantID], [downloadMetadata objectId]);
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
        //
        // NOTE: I do not believe it makes sense to store the selectedAccounUUID in 
        // this DocumentViewController as the viewController is not tied to a AccountInfo object.
        // this should probably be retrieved from the downloadMetaData
        // 
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
        [viewController release];
        
       // self.selectedFile = fileURL;
    }
    else {
        NSURL *fileURL = [dataSource cellDataObjectForIndexPath:indexPath];
        RepositoryItem * repItem = [dataSource downloadMetadataForIndexPath:indexPath];
        NSString *fileName = repItem.title;
        NSLog(@"=========== %@", fileName);
        DocumentViewController *viewController = [[DocumentViewController alloc] 
                                                  initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
        
        
        [viewController setFileName:fileName];
        
        NSLog(@"=========== %@ --------- %@", [repItem.metadata objectForKey:@"accountUUID"], repItem.selfURL);
        RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:@"53612229-64BF-46D0-BB9E-E452BEE130AF"
                                                                                       tenantID:nil];
        NSString *currentRepoId = [repoInfo repositoryId];
        if ([[repItem.metadata objectForKey:@"csim:repositoryId"] isEqualToString:currentRepoId])
        {
            //viewController.fileMetadata = repItem.metadata;
        }
        //viewController.fileMetadata = 
        [viewController setCmisObjectId:@"workspace://SpacesStore/5f6ec952-4eab-4041-9f35-c28fd47698ec"];
        [viewController setFilePath:repItem.selfURL];      //[FavoriteFileUtils pathToSavedFile:fileName]];
        [viewController setContentMimeType:repItem.contentStreamLengthString];
        [viewController setHidesBottomBarWhenPushed:YES];
        [viewController setIsDownloaded:YES];
        [viewController setSelectedAccountUUID:@"53612229-64BF-46D0-BB9E-E452BEE130AF"];  
        //
        // NOTE: I do not believe it makes sense to store the selectedAccounUUID in 
        // this DocumentViewController as the viewController is not tied to a AccountInfo object.
        // this should probably be retrieved from the downloadMetaData
        // 
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
        [viewController release];
    }
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


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
    [self setTableDatasourceFavorites:favorites];
    
    [self.tableView reloadData];
    [self dataSourceFinishedLoadingWithSuccess:YES];
    [self stopHUD];
    favoritesRequest = nil;
    
}

- (void)favoriteManagerRequestFailed:(FavoriteManager *)favoriteManager
{
    NSLog(@"Request in ActivitiesTableViewController failed! %@", [favoriteManager.error description]);
    
    [self showLiveFavoritesList:NO];
    //[self failedToFetchFavoritesError];
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
    
   // FolderTableViewDataSource *folderDataSource = (FolderTableViewDataSource *)[self.tableView dataSource];
    
    /* We disable the automatic table view refresh while editing to get an animated
     effect. The automatic refresh is activated after only one time it was disabled.
     */
    /*
    if (!folderDataSource.editing)
    {
        NSLog(@"Reloading favorites tableview");
        [folderDataSource refreshData];
        [self.tableView reloadData];
        //[self selectCurrentRow];
    }
    else
    {
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
        // [self performSelector:@selector(selectCurrentRow) withObject:nil afterDelay:0.5];
        folderDataSource.editing = NO;
    }
    */
    
    FavoritesTableViewDataSource *folderDataSource = (FavoritesTableViewDataSource *)[self.tableView dataSource];
    [folderDataSource refreshData];
    [self.tableView reloadData];
}

#pragma mark - UIAlertView Delegates

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSUserDefaults * preferences = [NSUserDefaults standardUserDefaults];
    
    if (buttonIndex == 0) {
        
        [preferences setObject:@"No" forKey:kSyncPreference];
    }
    else {
        
        [preferences setObject:@"Yes" forKey:kSyncPreference];
        
        
        
    }
    
    [preferences synchronize];
    
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
    
    if(activeCount == 0)
    {
        [self showLiveFavoritesList:NO];
    }
    
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


@end
