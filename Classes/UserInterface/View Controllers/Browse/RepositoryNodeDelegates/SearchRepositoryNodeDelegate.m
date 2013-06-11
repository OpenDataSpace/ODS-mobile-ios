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
//  SearchRepositoryNodeDelegate.m
//

#import "SearchRepositoryNodeDelegate.h"
#import "RepositoryItemCellWrapper.h"
#import "RepositoryPreviewManagerDelegate.h"
#import "MBProgressHUD.h"
#import "ObjectByIdRequest.h"
#import "MetaDataTableViewController.h"
#import "CMISSearchHTTPRequest.h"
#import "ThemeProperties.h"
#import "TableViewHeaderView.h"

@implementation SearchRepositoryNodeDelegate
@synthesize repositoryItems = _repositoryItems;
@synthesize previewDelegate = _previewDelegate;
@synthesize metadataDownloader = _metadataDownloader;
@synthesize searchRequest = _searchRequest;
@synthesize tableView = _tableView;
@synthesize navigationController = _navigationController;
@synthesize searchController = _searchController;
@synthesize HUD = _HUD;
@synthesize repositoryNodeGuid = _repositoryNodeGuid;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_repositoryItems release];
    [_previewDelegate release];
    [_metadataDownloader release];
    [_searchRequest release];
    [_tableView release];
    [_navigationController release];
    [_searchController release];
    [_HUD release];
    [_repositoryNodeGuid release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [super dealloc];
}

- (id)initWithViewController:(UIViewController *)viewController
{
    self = [super init];
    if(self)
    {
        UITableView *originalTableView = nil;
        [self setNavigationController:[viewController navigationController]];
        if([viewController respondsToSelector:@selector(tableView)])
        {
            originalTableView = [viewController performSelector:@selector(tableView)];
        }
        if([viewController respondsToSelector:@selector(selectedAccountUUID)])
        {
            [self setSelectedAccountUUID:[viewController performSelector:@selector(selectedAccountUUID)]];
        }
        if([viewController respondsToSelector:@selector(tenantID)])
        {
            [self setTenantID:[viewController performSelector:@selector(tenantID)]];
        }
        
        //Contextual Search view
        UISearchBar *theSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
        [theSearchBar setTintColor:[ThemeProperties toolbarColor]];
        [theSearchBar setShowsCancelButton:YES];
        [theSearchBar setDelegate:self];
        [theSearchBar setShowsCancelButton:NO animated:NO];
        [originalTableView setTableHeaderView:theSearchBar];
        [theSearchBar release];

        //Setting up the search controller
        UISearchDisplayController *searchCon = [[UISearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:viewController];
        [searchCon.searchBar setBackgroundColor:[UIColor whiteColor]];
        [self setSearchController: searchCon];
        [searchCon release];
        [self.searchController setDelegate:self];
        [self.searchController setSearchResultsDelegate:self];
        [self.searchController setSearchResultsDataSource:self];
        [self.searchController.searchResultsTableView setRowHeight:kDefaultTableCellHeight];
        [self setTableView:[self.searchController searchResultsTableView]];
        
        RepositoryPreviewManagerDelegate *previewDelegate = [[RepositoryPreviewManagerDelegate alloc] init];
        [previewDelegate setTableView:[self tableView]]; 
        [previewDelegate setSelectedAccountUUID:[self selectedAccountUUID]];
        [previewDelegate setTenantID:[self tenantID]];
        [previewDelegate setNavigationController:[self navigationController]];
        [[PreviewManager sharedManager] setDelegate:previewDelegate];
        [self setPreviewDelegate:previewDelegate];
        [previewDelegate release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFilesExpired:) name:kNotificationExpiredFiles object:nil];
    }
    return self;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [self.repositoryItems count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    return [cellWrapper createCellInTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
// Row selection (all modes)
{
    [self selectDocumentAtIndexPath:indexPath inTableView:tableView];
}

- (void)selectDocumentAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
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
    
    FavoriteManager *favoriteManager = [FavoriteManager sharedManager];
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSString *fileName = [fileManager generatedNameForFile:child.title withObjectID:child.guid];
    
    if ([favoriteManager isNodeFavorite:child.guid inAccount:self.selectedAccountUUID tenantID:self.tenantID] && [fileManager downloadExistsForKey:fileName])
    {
        if ([[AlfrescoMDMLite sharedInstance] isSyncExpired:fileName withAccountUUID:self.selectedAccountUUID])
        {
            [[RepositoryServices shared] removeRepositoriesForAccountUuid:self.selectedAccountUUID];
            [[AlfrescoMDMLite sharedInstance] setServiceDelegate:self];
            [[AlfrescoMDMLite sharedInstance] loadRepositoryInfoForAccount:self.selectedAccountUUID];
        }
        else
        {
            DownloadInfo *downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:child] autorelease];
            [downloadInfo setSelectedAccountUUID:self.selectedAccountUUID];
            [downloadInfo setTenantID:self.tenantID];
            [downloadInfo setTempFilePath:[fileManager pathToFileDirectory:fileName]];
            
            [tableView setAllowsSelection:YES];
            [self.previewDelegate showDocument:downloadInfo];
        }
    }
    else
    {
        if (child.contentLocation)
        {
            [tableView setAllowsSelection:NO];
            [[PreviewManager sharedManager] previewItem:child delegate:self.previewDelegate accountUUID:self.selectedAccountUUID tenantID:self.tenantID];
        }
        else
        {
            displayWarningMessageWithTitle(NSLocalizedString(@"noContentWarningMessage", @"This document has no content."), NSLocalizedString(@"noContentWarningTitle", @"No content"));
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
	RepositoryItem *child = [cellWrapper anyRepositoryItem];
	
    if (child)
    {
        if (cellWrapper.isDownloadingPreview)
        {
            [[PreviewManager sharedManager] cancelPreview];
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    // TODO: we should check the number of sections in the table view before assuming that there will be a Site Selection
    if ([self.searchRequest.results count] == 30) { // TODO EXTERNALIZE THIS OR MAKE IT CONFIGURABLE
        return NSLocalizedString(@"searchview.footer.displaying-30-results", 
                                 @"Displaying the first 30 results");
    }
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
    if ((nil == sectionTitle))
        return nil;
    
    //The height gets adjusted if it is less than the needed height
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
    [headerView setBackgroundColor:[ThemeProperties browseFooterColor]];
    [headerView.textLabel setTextColor:[ThemeProperties browseFooterTextColor]];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
    if ((nil == sectionTitle))
        return 0.0f;
    
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
    return headerView.frame.size.height;
}

#pragma mark - SearchBarDelegate Protocol Methods
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar 
{
    NSString *searchPattern = [[searchBar text] trimWhiteSpace];
    
    if ([searchPattern length] > 0)
    {
        AlfrescoLogDebug(@"Start searching for %@", searchPattern);
        // Cancel if there's a current request
        if ([self.searchRequest isExecuting])
        {
            [self.searchRequest clearDelegatesAndCancel];
            [self stopHUD];
            [self setSearchRequest:nil];
        }
        
        [self startHUDInTableView:self.tableView];
        
        CMISSearchHTTPRequest *searchReq = [[[CMISSearchHTTPRequest alloc] initWithSearchPattern:searchPattern
                                                                                  folderObjectId:self.repositoryNodeGuid 
                                                                                     accountUUID:self.selectedAccountUUID
                                                                                        tenantID:self.tenantID] autorelease];
        [self setSearchRequest:searchReq];        
        [self.searchRequest setDelegate:self];
        // set the time out interval to 60 seconds for search requests for slow responses
        [self.searchRequest setTimeOutSeconds:60.0f];
        [self.searchRequest startAsynchronous];
    }
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller 
{
    // Cleaning up the search results
    [self setSearchRequest:nil];
    [self.repositoryItems removeAllObjects];
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
        [viewController setTenantID:self.tenantID];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [viewController release];
    }
    else if ([request isKindOfClass:[CMISSearchHTTPRequest class]]) 
    { 
        AlfrescoMDMLite * mdmManager = [AlfrescoMDMLite sharedInstance];
        [mdmManager loadMDMInfo:[(CMISQueryHTTPRequest *)request results] withAccountUUID:[(CMISQueryHTTPRequest *)request accountUUID]
                    andTenantId:[(CMISQueryHTTPRequest *)request tenantID] delegate:self];
        
        [self initSearchResultItems];
        [[self.searchController searchResultsTableView] reloadData];
    } 
    
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];
    if ([request isKindOfClass:[CMISSearchHTTPRequest class]])
    {
        [[self.searchController searchResultsTableView] reloadData];
    }
    [self stopHUD];
}

- (void)initSearchResultItems
{
    NSMutableArray *searchResults = [NSMutableArray array];
    
    if ([self.searchRequest.results count] > 0)
    {
        for(RepositoryItem *result in [self.searchRequest results])
        {
            RepositoryItemCellWrapper *cellWrapper = [[RepositoryItemCellWrapper alloc] initWithRepositoryItem:result];
            [cellWrapper setItemTitle:result.title];
            [searchResults addObject:cellWrapper];
            [cellWrapper release];
        }
    }
    else 
    {
        RepositoryItemCellWrapper *cellWrapper = [[RepositoryItemCellWrapper alloc] initWithRepositoryItem:nil];
        [cellWrapper setIsSearchError:YES];
        [cellWrapper setSearchStatusCode:self.searchRequest.responseStatusCode];
        [searchResults addObject:cellWrapper];
        [cellWrapper release];
    }
    
    [self.previewDelegate setRepositoryItems:searchResults];
    [self setRepositoryItems:searchResults];
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

// MDMLite Delegate Method
- (void)mdmServiceManagerRequestFinishedForAccount:(NSString*)accountUUID withSuccess:(BOOL)success
{
    if (success)
    {
        NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
        [self.tableView reloadData];
        [self selectDocumentAtIndexPath:selectedRow inTableView:self.tableView];
        [self.tableView selectRowAtIndexPath:selectedRow animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

#pragma mark NSNotificationCenter Method MDMLite

- (void)mdmLiteRequestFinishedWithItems:(NSArray *)items
{
    [self.searchController.searchResultsTableView reloadData];
}

/**
 * Documents Expired notification
 */
- (void)handleFilesExpired:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSArray *expiredSyncFiles = userInfo[@"expiredSyncFiles"];
    NSString *currentDetailViewControllerObjectID = [[IpadSupport getCurrentDetailViewControllerObjectID] lastPathComponent];
    
    for (NSString *docTitle in expiredSyncFiles)
    {
        NSString *docGuid = [docTitle stringByDeletingPathExtension];
        NSIndexPath *index = [RepositoryNodeUtils indexPathForNodeWithGuid:docGuid inItems:self.repositoryItems];
        
        [[self.tableView cellForRowAtIndexPath:index] setAlpha:0.5];
        
        if ([currentDetailViewControllerObjectID hasSuffix:docGuid])
        {
            [self.tableView deselectRowAtIndexPath:index animated:YES];
        }
    }
}

@end
