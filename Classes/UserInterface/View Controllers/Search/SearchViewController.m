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
//  SearchViewController.m
//

#import "SearchViewController.h"
#import "DocumentViewController.h"
#import "RepositoryItemTableViewCell.h"
#import "RepositoryItemCellWrapper.h"
#import "Utility.h"
#import "CMISSearchHTTPRequest.h"
#import "Theme.h"
#import "ThemeProperties.h"
#import "ServiceDocumentRequest.h"
#import "MBProgressHUD.h"
#import "RepositoryServices.h"
#import "TableViewHeaderView.h"
#import "AccountManager.h"
#import "AccountNode.h"
#import "SiteNode.h"
#import "NetworkNode.h"
#import "DetailFirstTableViewCell.h"
#import "FileDownloadManager.h"
#import "NetworkSiteNode.h"
#import "SearchPreviewManagerDelegate.h"
#import "AppProperties.h"
#import "ObjectByIdRequest.h"
#import "MetaDataTableViewController.h"
#import "RepositoryNodeUtils.h"

@implementation SearchViewController
static CGFloat const kSectionHeaderHeightPadding = 6.0;

#pragma mark Memory Management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_serviceDocumentRequest clearDelegatesAndCancel];
    _previewDelegate = nil;
    
	[_search release];
	[_table release];
	[_results release];
	[_searchDownload release];
    [_serviceDocumentRequest release];
    [_HUD release];
    [_selectedSearchNode release];
    [_selectedAccountUUID release];
    [_savedTenantID release];
    [_metadataDownloader release];

    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // the DownloadProgressBar listen to a ResignActiveNotification and
    // dismisses the modal automatically
    
    [self.searchDownload cancel];
    self.searchDownload = nil;
}

#pragma mark View Life Cycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self updateCurrentRowSelection];
    
    if (!self.selectedSearchNode)
    {
        [self selectSavedNodeAllowingCMISServiceRequests:YES];
    }
    
    if (self.selectedSearchNode)
    {
        AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedSearchNode.accountUUID];
        NSString *tenantID = self.selectedSearchNode.tenantID;
        
        if (account && [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[account uuid] tenantID:tenantID] == nil)
        {
            [self startHUD];
            
            CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
            [serviceManager addListener:self forAccountUuid:[account uuid]];
            [serviceManager loadServiceDocumentForAccountUuid:[account uuid]];
        }
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDetailViewControllerChangedNotification object:nil];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    [self setTitle:NSLocalizedString(@"searchViewTitle", @"Search Results")];
	
	[Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
	[self.search setTintColor:ThemeProperties.toolbarColor];
	[self.table setBackgroundColor:[UIColor clearColor]];
    
    if (!self.results)
    {
        [self setResults:[NSMutableArray array]];
    }
    
    [self.table reloadData];
    [self.search setShowsCancelButton:NO];
    
    SearchPreviewManagerDelegate *previewDelegate = [[SearchPreviewManagerDelegate alloc] init];
    [previewDelegate setTableView:self.table];
    [previewDelegate setSelectedAccountUUID:self.selectedAccountUUID];
    [previewDelegate setTenantID:self.selectedSearchNode.tenantID];
    [previewDelegate setNavigationController:self.navigationController];
    [self setPreviewDelegate:previewDelegate];
    [previewDelegate release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                 name:kNotificationAccountListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userPreferencesChanged:) 
                                                 name:kUserPreferencesChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFilesExpired:)
                                                 name:kNotificationExpiredFiles object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return YES;
}

- (void)selectDefaultAccount 
{
    NSArray *allAccounts = [[AccountManager sharedManager] activeAccounts];
    
    if ([allAccounts count] <= 0)
    {
        return;
    }
    
    AccountInfo *account = [allAccounts objectAtIndex:0];
    
    if (![account isMultitenant])
    {
        AccountNode *defaultNode = [[AccountNode alloc] init];
        [defaultNode setIndentationLevel:0];
        [defaultNode setValue:account];
        [defaultNode setCanExpand:YES];
        [defaultNode setAccountUUID:[account uuid]];
        
        self.selectedSearchNode = defaultNode;
        [defaultNode release];
        [self saveAccountUUIDSelection:[account uuid] tenantID:nil guid:nil title:nil];
    }
    else
    {
        [self startHUD];
        
        //If it's a cloud account, we search for the first network
        [self setSelectedAccountUUID:[account uuid]];
        CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
        [serviceManager addQueueListener:self];
        [serviceManager loadServiceDocumentForAccountUuid:[account uuid]];
    }
}

- (void)saveAccountUUIDSelection:(NSString *)accountUUID tenantID:(NSString *)tenantID guid:(NSString *)guid title:(NSString *)title
{
    [[FDKeychainUserDefaults standardUserDefaults] setObject:accountUUID forKey:kFDSearchSelectedUUID];
    
    if (tenantID == nil)
    {
        [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:kFDSearchSelectedTenantID];
    }
    else
    {
        [[FDKeychainUserDefaults standardUserDefaults] setObject:tenantID forKey:kFDSearchSelectedTenantID];
    }
    
    if (guid && title)
    {
        [[FDKeychainUserDefaults standardUserDefaults] setObject:guid forKey:kFDSearchSelectedGuid];
        [[FDKeychainUserDefaults standardUserDefaults] setObject:title forKey:kFDSearchSelectedTitle];
    } else
    {
        [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:kFDSearchSelectedGuid];
        [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:kFDSearchSelectedTitle];
    }
    
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
}

- (void)selectSavedNodeAllowingCMISServiceRequests:(BOOL)allowCMISServiceRequests
{
    NSString *savedAccountUUID = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:kFDSearchSelectedUUID];
    [self setSavedTenantID:[[FDKeychainUserDefaults standardUserDefaults] objectForKey:kFDSearchSelectedTenantID]];
    NSString *searchGuid = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:kFDSearchSelectedGuid];
    NSString *searchTitle = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:kFDSearchSelectedTitle];
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:savedAccountUUID];
    BOOL activeAccount = [account.accountStatusInfo isActive];
    
    if (!activeAccount)
    {
        [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:kFDSearchSelectedUUID];
        [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:kFDSearchSelectedTenantID];
        [self setSavedTenantID:nil];
        [self selectDefaultAccount];
    }
    else if (activeAccount && !self.savedTenantID && !searchGuid && !searchTitle)
    {
        AccountNode *defaultNode = [[AccountNode alloc] init];
        [defaultNode setIndentationLevel:0];
        [defaultNode setValue:account];
        [defaultNode setCanExpand:YES];
        [defaultNode setAccountUUID:[account uuid]];
        
        self.selectedSearchNode = defaultNode;
        [defaultNode release];
    }
    else if (searchGuid && searchTitle && self.savedTenantID)
    {
        self.selectedAccountUUID = savedAccountUUID;
        
        // NetworkSite
        NetworkSiteNode *defaultNode = [[NetworkSiteNode alloc] init];
        RepositoryItem *repoItem = [[RepositoryItem alloc] init];
        [repoItem setGuid:searchGuid];
        [repoItem setTitle:searchTitle];
        defaultNode.value = repoItem;
        [repoItem release];
        [defaultNode setTenantID:self.savedTenantID];
        [defaultNode setAccountUUID:[self selectedAccountUUID]];
        
        self.selectedSearchNode = defaultNode;
        [defaultNode release];
    }
    else if (searchGuid && searchTitle)
    {
        self.selectedAccountUUID = savedAccountUUID;
        
        // SiteNode
        SiteNode *defaultNode = [[SiteNode alloc] init];
        RepositoryItem *repoItem = [[RepositoryItem alloc] init];
        [repoItem setGuid:searchGuid];
        [repoItem setTitle:searchTitle];
        defaultNode.value = repoItem;
        [repoItem release];
        [defaultNode setAccountUUID:[self selectedAccountUUID]];
        
        self.selectedSearchNode = defaultNode;
        [defaultNode release];
    }
    else if (activeAccount && self.savedTenantID && allowCMISServiceRequests)
    {
        //Cloud account
        [self startHUD];
        
        //If it's a cloud account, we search for the first network
        [self setSelectedAccountUUID:savedAccountUUID];
        CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
        [serviceManager addQueueListener:self];
        [serviceManager loadServiceDocumentForAccountUuid:savedAccountUUID];
    }
    [self.table reloadData];
}

- (void)updateCurrentRowSelection
{
    NSIndexPath *selectedRow = [self.table indexPathForSelectedRow];
    
    if (!IS_IPAD)
    {
        [self.table deselectRowAtIndexPath:selectedRow animated:YES];
    }
    else
    {
        NSIndexPath *indexPath = [RepositoryNodeUtils indexPathForNodeWithGuid:[IpadSupport getCurrentDetailViewControllerObjectID] inItems:self.results inSection:1];
        if (self.table)
        {
            if (indexPath)
            {
                [self.table selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
            else if (self.table.indexPathForSelectedRow)
            {
                [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES];
            }
        }
    }
}

#pragma mark - HTTP Request Handling

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest 
{
    NSString *accountUUID = [self.selectedSearchNode accountUUID];
    NSString *tenantID = [self.selectedSearchNode tenantID];
    RepositoryInfo *currentRepository = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:accountUUID tenantID:tenantID];
    
    if (!currentRepository)
    {
        AlfrescoLogDebug(@"Search is not available but the user is notified when a search is triggered");
    }
	
    [self stopHUD];
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)serviceRequest 
{
	AlfrescoLogDebug(@"ServiceDocument Request Failure \n\tErrorDescription: %@ \n\tErrorFailureReason:%@ \n\tErrorObject:%@", 
          [[serviceRequest error] description], [[serviceRequest error] localizedFailureReason],[serviceRequest error]);
    [self stopHUD];
}

#pragma mark - Handling cloud account information

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    RepositoryInfo *networkInfo = nil;
    if (self.savedTenantID)
    {
        //We are selecting a tenantID
        networkInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[self selectedAccountUUID] tenantID:[self savedTenantID]];
    }
    else
    {
        //Select the first tenant, used when selecting a default account, persist the selection
        NSArray *array = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:[self selectedAccountUUID]]];
        if ([array count] > 0) 
        {
            networkInfo = [array objectAtIndex:0];
        }
        [self saveAccountUUIDSelection:self.selectedAccountUUID tenantID:self.savedTenantID guid:nil title:nil];
    }
    
    [self setSelectedSearchNode:nil];
    [self selectSavedNodeAllowingCMISServiceRequests:NO];
    
    if (networkInfo)
    {
        NetworkNode *defaultNode = [[NetworkNode alloc] init];
        [defaultNode setIndentationLevel:0];
        [defaultNode setValue:networkInfo];
        [defaultNode setCanExpand:YES];
        [defaultNode setAccountUUID:[self selectedAccountUUID]];
        
        self.selectedSearchNode = defaultNode;
        [defaultNode release];
    }
    
    [self setSelectedAccountUUID:nil];
    [self setSavedTenantID:nil];
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [self.table reloadData];
    [self stopHUD];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [self setSelectedAccountUUID:nil];
    [self setSavedTenantID:nil];
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [self stopHUD];
}


#pragma mark - ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request 
{
    [self.table setAllowsSelection:YES];

    if ([request isKindOfClass:[ObjectByIdRequest class]])
    {
        ObjectByIdRequest *object = (ObjectByIdRequest *)request;
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                              cmisObject:object.repositoryItem
                                                                                             accountUUID:object.accountUUID
                                                                                                tenantID:object.tenantID];
        [viewController setCmisObjectId:object.repositoryItem.guid];
        [viewController setMetadata:object.repositoryItem.metadata];
        [viewController setSelectedAccountUUID:object.accountUUID];
        [viewController setTenantID:object.tenantID];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [viewController release];
    }
    else if ([request isKindOfClass:[CMISSearchHTTPRequest class]])
    {
        [self.results removeAllObjects];
        
        AlfrescoMDMLite * mdmManager = [AlfrescoMDMLite sharedInstance];
        mdmManager.delegate = self;
        [mdmManager loadMDMInfo:[(CMISQueryHTTPRequest *)request results] withAccountUUID:[(CMISQueryHTTPRequest *)request accountUUID]
                    andTenantId:[(CMISQueryHTTPRequest *)request tenantID] delegate:self];
        
        [self initRepositoryWrappersWithRepositoryItems:[(CMISQueryHTTPRequest *)request results]];
        
        if ([self.results count] == 0)
        {
            RepositoryItem *emptyResult = [[RepositoryItem alloc] init];
            [emptyResult setTitle:NSLocalizedString(@"noSearchResultsMessage", @"No Results Found")];
            [emptyResult setContentLocation:nil];
            [self initRepositoryWrappersWithRepositoryItems:[NSArray arrayWithObject:emptyResult]];
            [emptyResult release];
        }
        
        [self.table reloadData];
    }
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request 
{
    NSError *error = [request error];
    AlfrescoLogDebug(@"Failure: %@", error);	
    
    [self.results removeAllObjects];
    if ([request responseStatusCode] == 500)
    {
        RepositoryItem *errorResult = [[RepositoryItem alloc] init];
		[errorResult setTitle:NSLocalizedString(@"Too many search results", @"Server Error")];
		[errorResult setContentLocation:nil];
        [self initRepositoryWrappersWithRepositoryItems:[NSArray arrayWithObject:errorResult]];
        [errorResult release];
    }
    [self.table reloadData];
    [self stopHUD];
}

- (void)initRepositoryWrappersWithRepositoryItems:(NSArray *)repositoryItems
{
    for (RepositoryItem *child in repositoryItems)
    {
        RepositoryItemCellWrapper *cellWrapper = [[RepositoryItemCellWrapper alloc] initWithRepositoryItem:child];
        [cellWrapper setItemTitle:child.title];
        [cellWrapper setSelectedAccountUUID:self.selectedSearchNode.accountUUID];
        [self.results addObject:cellWrapper];
        [cellWrapper release];
    }
}

#pragma mark - MDMLiteDelegate

- (void)mdmLiteRequestFinishedWithItems:(NSArray *)items
{
    [self.table reloadData];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if (!IS_IPAD)
    {
        [searchBar setShowsCancelButton:YES animated:YES];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    if (!IS_IPAD)
    {
        [searchBar setShowsCancelButton:NO animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        static CGFloat textLabelOriginalY = 0.0f;
        DetailFirstTableViewCell *cell = (DetailFirstTableViewCell *) [tableView dequeueReusableCellWithIdentifier:kDetailFirstCellIdentifier];
        if (cell == nil)
        {
            NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"DetailFirstTableViewCell" owner:self options:nil];
            cell = [nibItems objectAtIndex:0];
            NSAssert(nibItems, @"Failed to load object from NIB");
            
            cell.backgroundColor = [UIColor whiteColor];
            textLabelOriginalY = cell.textLabel.frame.origin.y;
        }
        
        NSString *siteName = nil;
        if (self.selectedSearchNode == nil)
        {
            siteName = NSLocalizedString(@"search.noAccounts", @"No Accounts");
            [cell.imageView setImage:nil];
            [cell.detailTextLabel setText:nil];
        }
        else
        {
            siteName = [self.selectedSearchNode title];
            [cell.imageView setImage:[self.selectedSearchNode cellImage]];
            [cell.detailTextLabel setText:[self.selectedSearchNode breadcrumb]];
            
            CGRect frame = cell.textLabel.frame;
            frame.origin.y = textLabelOriginalY;
            if (cell.detailTextLabel.text.length == 0)
            {
                frame.origin.y = textLabelOriginalY - 6.0f;
            }
            [cell.textLabel setFrame:frame];
        }
        
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cell setSelected:UITableViewCellSelectionStyleBlue];
        [cell.textLabel setText:siteName];
        return cell;
    }
    
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil)
    {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
    RepositoryItemCellWrapper *cellWrapper = [self.results objectAtIndex:indexPath.row];
	RepositoryItem *result = [cellWrapper repositoryItem];
	if (([result contentLocation] == nil) && ([self.results count] == 1))
    {
		cell.filename.text = result.title;
        
        if ([result.title isEqualToString:NSLocalizedString(@"search.too.many.results", @"Too many search results")])
        {
            [[cell details] setText:NSLocalizedString(@"refineSearchTermsMessage", @"refineSearchTermsMessage")];
        }
        else
        {
            cell.details.text = NSLocalizedString(@"tryDifferentSearchMessage", @"Please try a different search");
        }
        
		cell.imageView.image = nil;
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setAccessoryView:nil];
	}
	else
    {
        cell = (RepositoryItemTableViewCell *)[cellWrapper createCellInTableView:self.table];
        [cell setAccessoryView:[cellWrapper makeDetailDisclosureButton]];
	}
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    } 
	return [self.results count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectDocumentAtIndexPath:indexPath inTableView:tableView];
}

- (void)selectDocumentAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
{
    if (indexPath.section == 0)
    {
        SelectSiteViewController *selectSiteController = [SelectSiteViewController selectSiteViewController];
        [selectSiteController setSelectedNode:self.selectedSearchNode];
        [selectSiteController setDelegate:self];
        [self.navigationController pushViewController:selectSiteController animated:YES];
        [self.table deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
	RepositoryItem *result = [[self.results objectAtIndex:indexPath.row] repositoryItem];
	if (([result contentLocation] == nil) && (self.results.count == 1))
    {
		return;
	}
    
    [self.table setAllowsSelection:NO];
    
    FavoriteManager *favoriteManager = [FavoriteManager sharedManager];
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSString *fileName = [fileManager generatedNameForFile:result.title withObjectID:result.guid];
    [self.previewDelegate setSelectedAccountUUID:self.selectedSearchNode.accountUUID];
    [self.previewDelegate setTenantID:self.selectedSearchNode.tenantID];
    
    if ([favoriteManager isNodeFavorite:result.guid inAccount:self.selectedSearchNode.accountUUID] && [fileManager downloadExistsForKey:fileName])
    {
        if ([[AlfrescoMDMLite sharedInstance] isSyncExpired:fileName withAccountUUID:self.selectedAccountUUID])
        {
            [[RepositoryServices shared] removeRepositoriesForAccountUuid:self.selectedSearchNode.accountUUID];
            [[AlfrescoMDMLite sharedInstance] setServiceDelegate:self];
            [[AlfrescoMDMLite sharedInstance] loadRepositoryInfoForAccount:self.selectedSearchNode.accountUUID];
        }
        else
        {
            DownloadInfo *downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:result] autorelease];
            [downloadInfo setSelectedAccountUUID:self.selectedSearchNode.accountUUID];
            [downloadInfo setTenantID:self.selectedSearchNode.tenantID];
            [downloadInfo setTempFilePath:[fileManager pathToFileDirectory:fileName]];
            
            [tableView setAllowsSelection:YES];
            [self.previewDelegate showDocument:downloadInfo];
        }
    }
    else
    {
        if (result.contentLocation)
        {
            [tableView setAllowsSelection:NO];
            // We fetch the current repository items from the DataSource
            [self.previewDelegate setRepositoryItems:[self results]];
            [[PreviewManager sharedManager] previewItem:result delegate:self.previewDelegate accountUUID:self.selectedSearchNode.accountUUID tenantID:self.selectedSearchNode.tenantID];
        }
        else
        {
            displayErrorMessageWithTitle(NSLocalizedString(@"noContentWarningMessage", @"This document has no content."), NSLocalizedString(@"noContentWarningTitle", @"No content"));
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemCellWrapper *cellWrapper = [self.results objectAtIndex:indexPath.row];
	RepositoryItem *child = [cellWrapper anyRepositoryItem];
    
    if (child)
    {
        if (cellWrapper.isDownloadingPreview)
        {
            [[PreviewManager sharedManager] cancelPreview];
            [self.table deselectRowAtIndexPath:self.table.indexPathForSelectedRow animated:YES];
        }
        else
        {
            [tableView setAllowsSelection:NO];
            [self startHUD];
            
            ObjectByIdRequest *object = [ObjectByIdRequest defaultObjectById:child.guid accountUUID:self.selectedSearchNode.accountUUID tenantID:self.selectedSearchNode.tenantID];
            [object setDelegate:self];
            [object startAsynchronous];
            [self setMetadataDownloader:object];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    // TODO: we should check the number of sections in the table view before assuming that there will be a Site Selection
    if (section == 1)
    {
        // TODO EXTERNALIZE THIS OR MAKE IT CONFIGURABLE
        if (self.results.count == 30)
        {
            return NSLocalizedString(@"searchview.footer.displaying-30-results", 
                                     @"Displaying the first 30 results");
        }
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
	if ((nil == sectionTitle))
    {
		return nil;
    }
    
    // The height gets adjusted if it is less than the needed height
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
    [headerView setBackgroundColor:[ThemeProperties browseFooterColor]];
    [headerView.textLabel setTextColor:[ThemeProperties browseFooterTextColor]];
    
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
	if ((nil == sectionTitle))
    {
		return 0.0f;
    }
	
	TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
	return headerView.frame.size.height;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return NSLocalizedString(@"search.sectionHeader.site", 
                                 @"Search:");
    }
    else if (section == 1)
    {
        return NSLocalizedString(@"search.sectionHeader.results", 
                                 @"Search Results");
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
	if ((nil == sectionTitle))
		return nil;
     
    //The height gets adjusted if it is less than the needed height
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
    [headerView setBackgroundColor:[ThemeProperties browseHeaderColor]];
    [headerView.textLabel setTextColor:[ThemeProperties browseHeaderTextColor]];
    
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
	if ((nil == sectionTitle))
		return 0.0f;
	
	TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
	return headerView.frame.size.height;
}

#pragma mark - SelectSite Delegate

- (void)selectSite:(SelectSiteViewController *)selectSite finishedWithItem:(TableViewNode *)item
{
    self.selectedSearchNode = item;
    
    if ([item.value isKindOfClass:[RepositoryItem class]])
    {
        [self saveAccountUUIDSelection:[item accountUUID] tenantID:[item tenantID] guid:[item.value guid] title:[item.value title]];
    }
    else if ([item.value isKindOfClass:[RepositoryInfo class]])
    {
        [self saveAccountUUIDSelection:[item accountUUID] tenantID:[item tenantID] guid:nil title:nil];
    }
    
    [self.table reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectSiteDidCancel:(SelectSiteViewController *)selectSite
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (!self.selectedSearchNode)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"search.unavailable.noaccount.alert", @"Please select an account, network or site to start the search"), NSLocalizedString(@"searchUnavailableDialogTitle", @"Search Not Available"));
        return;
    }
    
    NSString *accountUUID = [self.selectedSearchNode accountUUID];
    NSString *tenantID = [self.selectedSearchNode tenantID];
	RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:accountUUID tenantID:tenantID];
	if (![repoInfo cmisQueryHref])
    {
		[self searchNotAvailableAlert];
		return;
	}
	
	NSString *searchPattern = [[searchBar text] trimWhiteSpace];
    if (searchPattern.length > 0)
    {
        [self startHUD];
        
        NSString *objectId = nil;
        if ([self.selectedSearchNode isKindOfClass:[SiteNode class]] || [self.selectedSearchNode isKindOfClass:[NetworkSiteNode class]])
        {
            objectId = [self.selectedSearchNode.value guid];
        }
        
        CMISSearchHTTPRequest *down = [[CMISSearchHTTPRequest alloc] initWithSearchPattern:searchPattern folderObjectId:objectId
                                                                         accountUUID:accountUUID tenantID:tenantID];
        
        [down setDelegate:self];
        [self setSearchDownload:down];
        [down startAsynchronous];
        [down release];
        [self.search resignFirstResponder];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
}

- (void)detailViewControllerChanged:(NSNotification *)notification
{
    [self updateCurrentRowSelection];
}

#pragma mark - MBProgressHUD Helper Methods

- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.table);
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

- (void)searchNotAvailableAlert
{
    displayErrorMessageWithTitle(NSLocalizedString(@"searchUnavailableDialogMessage", @"Search is not available for this repository"), NSLocalizedString(@"searchUnavailableDialogTitle", @"Search Not Available"));
}

#pragma mark - NotificationCenter methods

- (void) applicationWillResignActive:(NSNotification *) notification
{
    AlfrescoLogDebug(@"applicationWillResignActive in SearchViewController");
    [self.searchDownload cancel];
    [self.serviceDocumentRequest clearDelegatesAndCancel];
}

- (void)handleAccountListUpdated:(NSNotification *) notification
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSString *uuid = [userInfo objectForKey:@"uuid"];
    BOOL isReset = [[userInfo objectForKey:@"reset"] boolValue];
    
    if (self.selectedSearchNode && ([[self.selectedSearchNode accountUUID] isEqualToString:uuid] || isReset))
    {
        [self setResults:[NSMutableArray array]];
        [self setSelectedSearchNode:nil];
        [self selectDefaultAccount];
        [self.table reloadData];
    }
}

- (void)userPreferencesChanged:(NSNotification *)notification 
{
    [self setResults:[NSMutableArray array]];
    [self.table reloadData];
}

// MDMLite Delegate Method
- (void)mdmServiceManagerRequestFinishedForAccount:(NSString*)accountUUID withSuccess:(BOOL)success
{
    if (success)
    {
        NSIndexPath *selectedRow = [self.table indexPathForSelectedRow];
        [self.table reloadData];
        [self selectDocumentAtIndexPath:selectedRow inTableView:self.table];
        [self.table selectRowAtIndexPath:selectedRow animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        [self.table deselectRowAtIndexPath:[self.table indexPathForSelectedRow] animated:YES];
    }
}

#pragma mark NSNotificationCenter Method MDMLite
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
        NSIndexPath *index = [RepositoryNodeUtils indexPathForNodeWithGuid:docGuid inItems:self.results inSection:1];
        
        [[self.table cellForRowAtIndexPath:index] setAlpha:0.5];
        
        if ([currentDetailViewControllerObjectID hasSuffix:docGuid])
        {
            [self.table deselectRowAtIndexPath:index animated:YES];
        }
    }
}

@end
