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

@interface SearchViewController (PrivateMethods)
- (void)startHUD;
- (void)stopHUD;
- (void)searchNotAvailableAlert;
- (void)selectDefaultAccount;
- (void)saveAccountUUIDSelection:(NSString *)accountUUID tenantID:(NSString *)tenantID guid:(NSString *)guid title:(NSString *)title;
- (void)selectSavedNodeAllowingCMISServiceRequests:(BOOL)allowCMISServiceRequests;
@end

@implementation SearchViewController
static CGFloat const kSectionHeaderHeightPadding = 6.0;

@synthesize search;
@synthesize table;
@synthesize results;
@synthesize searchDownload;
@synthesize serviceDocumentRequest;
@synthesize HUD;
@synthesize selectedSearchNode;
@synthesize selectedAccountUUID;
@synthesize savedTenantID;
@synthesize previewDelegate = _previewDelegate;

#pragma mark Memory Management
- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [serviceDocumentRequest clearDelegatesAndCancel];
    
	[search release];
	[table release];
	[results release];
	[searchDownload release];
    [selectedIndex release];
    [willSelectIndex release];
    [serviceDocumentRequest release];
    [HUD release];
    [selectedSearchNode release];
    [selectedAccountUUID release];
    [savedTenantID release];
    _previewDelegate = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // the DownloadProgressBar listen to a ResignActiveNotification and
    // dismisses the modal automatically
    
    [self.searchDownload cancel];
    self.searchDownload = nil;
}

- (void)viewDidUnload {
	[super viewDidUnload];
    
    self.search = nil;
    self.table = nil;
}

#pragma mark View Life Cycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    if(IS_IPAD) {
        [table selectRowAtIndexPath:selectedIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    [willSelectIndex release];
    willSelectIndex = nil;
    
    if(!selectedSearchNode) {
        [self selectSavedNodeAllowingCMISServiceRequests:YES];
    }
    
    if(selectedSearchNode) {
        AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:[selectedSearchNode accountUUID]];
        NSString *tenantID = [selectedSearchNode tenantID];
        
        if (account && [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[account uuid] tenantID:tenantID] == nil) {
            [self startHUD];
            
            CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
            [serviceManager addListener:self forAccountUuid:[account uuid]];
            [serviceManager loadServiceDocumentForAccountUuid:[account uuid]];
        }
    }
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
    [self setTitle:NSLocalizedString(@"searchViewTitle", @"Search Results")];
	
	[Theme setThemeForUINavigationBar:[[self navigationController] navigationBar]];
	[search setTintColor:[ThemeProperties toolbarColor]];
	[table setBackgroundColor:[UIColor clearColor]];
    
    if (! results) {
        [self setResults:[NSMutableArray array]];
    }
    
    [table reloadData];
    [search setShowsCancelButton:NO];
    
    SearchPreviewManagerDelegate *previewDelegate = [[SearchPreviewManagerDelegate alloc] init];
    [previewDelegate setTableView:self.table];
    [previewDelegate setSelectedAccountUUID:self.selectedAccountUUID];
    [previewDelegate setTenantID:selectedSearchNode.tenantID];
    [previewDelegate setNavigationController:self.navigationController];
    [self setPreviewDelegate:previewDelegate];
    [previewDelegate release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                 name:kNotificationAccountListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userPreferencesChanged:) 
                                                 name:kUserPreferencesChangedNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return YES;
}

- (void)selectDefaultAccount 
{
    NSArray *allAccounts = [[AccountManager sharedManager] activeAccounts];
    
    if([allAccounts count] <= 0) 
    {
        return;
    }
    
    AccountInfo *account = [allAccounts objectAtIndex:0];
    
    if(![account isMultitenant])
    {
        AccountNode *defaultNode = [[AccountNode alloc] init];
        [defaultNode setIndentationLevel:0];
        [defaultNode setValue:account];
        [defaultNode setCanExpand:YES];
        [defaultNode setAccountUUID:[account uuid]];
        
        self.selectedSearchNode = defaultNode;
        [defaultNode release];
        [self saveAccountUUIDSelection:[account uuid] tenantID:nil guid:nil title:nil];
    } else 
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
    
    if(tenantID == nil)
    {
        [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:kFDSearchSelectedTenantID];
    } else 
    {
        [[FDKeychainUserDefaults standardUserDefaults] setObject:tenantID forKey:kFDSearchSelectedTenantID];
    }
    
    if (guid && title) {
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
    
    if(!activeAccount)
    {
        [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:kFDSearchSelectedUUID];
        [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:kFDSearchSelectedTenantID];
        [self setSavedTenantID:nil];
        [self selectDefaultAccount];
    }
    else if(activeAccount && !savedTenantID && !searchGuid && !searchTitle)
    {
        AccountNode *defaultNode = [[AccountNode alloc] init];
        [defaultNode setIndentationLevel:0];
        [defaultNode setValue:account];
        [defaultNode setCanExpand:YES];
        [defaultNode setAccountUUID:[account uuid]];
        
        self.selectedSearchNode = defaultNode;
        [defaultNode release];
    }
    else if (searchGuid && searchTitle && savedTenantID)
    {
        self.selectedAccountUUID = savedAccountUUID;
        
        // NetworkSite
        NetworkSiteNode *defaultNode = [[NetworkSiteNode alloc] init];
        RepositoryItem *repoItem = [[RepositoryItem alloc] init];
        [repoItem setGuid:searchGuid];
        [repoItem setTitle:searchTitle];
        defaultNode.value = repoItem;
        [repoItem release];
        [defaultNode setTenantID:savedTenantID];
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
    else if(activeAccount && savedTenantID && allowCMISServiceRequests)
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

#pragma mark -
#pragma mark HTTP Request Handling
- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest 
{
    NSString *accountUUID = [selectedSearchNode accountUUID];
    NSString *tenantID = [selectedSearchNode tenantID];
    RepositoryInfo *currentRepository = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:accountUUID tenantID:tenantID];
    
    if (!currentRepository) {
        NSLog(@"Search is not available but the user is notified when a search is triggered");
    }
	
    [self stopHUD];
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)serviceRequest 
{
	NSLog(@"ServiceDocument Request Failure \n\tErrorDescription: %@ \n\tErrorFailureReason:%@ \n\tErrorObject:%@", 
          [[serviceRequest error] description], [[serviceRequest error] localizedFailureReason],[serviceRequest error]);
    [self stopHUD];
}

#pragma mark Handling cloud account information
- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    RepositoryInfo *networkInfo = nil;
    if(savedTenantID)
    {
        //We are selecting a tenantID
        networkInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[self selectedAccountUUID] tenantID:[self savedTenantID]];
    } else 
    {
        //Select the first tenant, used when selecting a default account, persist the selection
        NSArray *array = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:[self selectedAccountUUID]]];
        if ([array count] > 0) 
        {
            networkInfo = [array objectAtIndex:0];
        }
        [self saveAccountUUIDSelection:selectedAccountUUID tenantID:savedTenantID guid:nil title:nil];
    }
    
    [self setSelectedSearchNode:nil];
    [self selectSavedNodeAllowingCMISServiceRequests:NO];
    
    if(networkInfo)
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
    [table reloadData];
    [self stopHUD];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [self setSelectedAccountUUID:nil];
    [self setSavedTenantID:nil];
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [self stopHUD];
}


#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request 
{
    [results removeAllObjects];
    [self initRepositoryWrappersWithRepositoryItems:[(CMISQueryHTTPRequest *)request results]];
	
	if ([results count] == 0) {
		RepositoryItem *emptyResult = [[RepositoryItem alloc] init];
		[emptyResult setTitle:NSLocalizedString(@"noSearchResultsMessage", @"No Results Found")];
		[emptyResult setContentLocation:nil];
        [self initRepositoryWrappersWithRepositoryItems:[NSArray arrayWithObject:emptyResult]];
        [emptyResult release];
	}
    
	[table reloadData];
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request 
{
    NSError *error = [request error];
    NSLog(@"Failure: %@", error);	
    
    [results removeAllObjects];
    if ([request responseStatusCode] == 500)
    {
        RepositoryItem *errorResult = [[RepositoryItem alloc] init];
		[errorResult setTitle:NSLocalizedString(@"Too many search results", @"Server Error")];
		[errorResult setContentLocation:nil];
        [self initRepositoryWrappersWithRepositoryItems:[NSArray arrayWithObject:errorResult]];
        [errorResult release];
    }
    [table reloadData];
    [self stopHUD];
}

- (void)initRepositoryWrappersWithRepositoryItems:(NSArray *)repositoryItems
{
    for (RepositoryItem *child in repositoryItems)
    {
        RepositoryItemCellWrapper *cellWrapper = [[RepositoryItemCellWrapper alloc] initWithRepositoryItem:child];
        [cellWrapper setItemTitle:child.title];
        [cellWrapper setSelectedAccountUUID:selectedSearchNode.accountUUID];
        [results addObject:cellWrapper];
        [cellWrapper release];
    }
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
    if(indexPath.section == 0)
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
        if(selectedSearchNode == nil)
        {
            siteName = NSLocalizedString(@"search.noAccounts", @"No Accounts");
            [cell.imageView setImage:nil];
            [cell.detailTextLabel setText:nil];
        }
        else
        {
            siteName = [selectedSearchNode title];
            [cell.imageView setImage:[selectedSearchNode cellImage]];
            [cell.detailTextLabel setText:[selectedSearchNode breadcrumb]];
            
            CGRect frame = cell.textLabel.frame;
            frame.origin.y = textLabelOriginalY;
            if (cell.detailTextLabel.text.length == 0)
            {
                frame.origin.y = textLabelOriginalY - 6.0f;
            }
            [cell.textLabel setFrame:frame];
        }
        
        [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
        [cell setSelected:UITableViewCellSelectionStyleBlue];
        [cell.textLabel setText:siteName];
        return cell;
    }
    
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil) {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
    RepositoryItemCellWrapper * cellWrapper = [self.results objectAtIndex:indexPath.row];
	RepositoryItem *result = [cellWrapper repositoryItem];
	if (([result contentLocation] == nil) && ([results count] == 1)) 
    {
		cell.filename.text = result.title;
        
        if ([result.title isEqualToString:NSLocalizedString(@"search.too.many.results", @"Too many search results")]) {
            [[cell details] setText:NSLocalizedString(@"refineSearchTermsMessage", @"refineSearchTermsMessage")];
        } else {
            cell.details.text = NSLocalizedString(@"tryDifferentSearchMessage", @"Please try a different search");
        }
        
		cell.imageView.image = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setAccessoryView:nil];
	}
	else
    {
        cell = (RepositoryItemTableViewCell *)[cellWrapper createCellInTableView:self.table];
        [cell setAccessoryView:nil];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 ) {
        SelectSiteViewController *selectSiteController = [SelectSiteViewController selectSiteViewController];
        [selectSiteController setSelectedNode:selectedSearchNode];
        [selectSiteController setDelegate:self];
        [self.navigationController pushViewController:selectSiteController animated:YES];
        [table deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
	RepositoryItem *result = [[self.results objectAtIndex:[indexPath row]] repositoryItem];
	if (([result contentLocation] == nil) && ([results count] == 1)) {
		return;
	}
    
    [self.table setAllowsSelection:NO];
    
    FavoriteManager * favoriteManager = [FavoriteManager sharedManager];
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSString *fileName = [fileManager generatedNameForFile:result.title withObjectID:result.guid];
    [self.previewDelegate setSelectedAccountUUID:selectedSearchNode.accountUUID];
    
    if ([favoriteManager isNodeFavorite:result.guid inAccount:selectedSearchNode.accountUUID] && [fileManager downloadExistsForKey:fileName])
    {
        DownloadInfo *downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:result] autorelease];
        [downloadInfo setSelectedAccountUUID:selectedSearchNode.accountUUID];
        [downloadInfo setTenantID:selectedSearchNode.tenantID];
        [downloadInfo setTempFilePath:[fileManager pathToFileDirectory:fileName]];
        
        [tableView setAllowsSelection:YES];
        [self.previewDelegate showDocument:downloadInfo];
    }
    else 
    {
        if (result.contentLocation)
        {
            [tableView setAllowsSelection:NO];
            // We fetch the current repository items from the DataSource
            [self.previewDelegate setRepositoryItems:[self results]];
            [[PreviewManager sharedManager] previewItem:result delegate:self.previewDelegate accountUUID:selectedSearchNode.accountUUID tenantID:selectedSearchNode.tenantID];
        }
        else
        {
            displayErrorMessageWithTitle(NSLocalizedString(@"noContentWarningMessage", @"This document has no content."), NSLocalizedString(@"noContentWarningTitle", @"No content"));
        }
    }
    
    [willSelectIndex autorelease];
    willSelectIndex = [indexPath retain];
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
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    // TODO: we should check the number of sections in the table view before assuming that there will be a Site Selection
    if (section == 1)
    {
        if ([results count] == 30) { // TODO EXTERNALIZE THIS OR MAKE IT CONFIGURABLE
            return NSLocalizedString(@"searchview.footer.displaying-30-results", 
                                     @"Displaying the first 30 results");
        }
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

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return NSLocalizedString(@"search.sectionHeader.site", 
                                 @"Search:");
    } else if(section == 1) {
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

#pragma mark -
#pragma mark SelectSite Delegate
-(void)selectSite:(SelectSiteViewController *)selectSite finishedWithItem:(TableViewNode *)item {
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

-(void)selectSiteDidCancel:(SelectSiteViewController *)selectSite {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if(!self.selectedSearchNode)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"search.unavailable.noaccount.alert", @"Please select an account, network or site to start the search"), NSLocalizedString(@"searchUnavailableDialogTitle", @"Search Not Available"));
        return;
    }
    
    NSString *accountUUID = [selectedSearchNode accountUUID];
    NSString *tenantID = [selectedSearchNode tenantID];
	RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:accountUUID tenantID:tenantID];
	if (![repoInfo cmisQueryHref]) {
		[self searchNotAvailableAlert];
		
		return;
	}
	
	
	NSString *searchPattern = [[searchBar text] trimWhiteSpace];
    if([searchPattern length] > 0)
    {
        [self startHUD];
        
        NSString *objectId = nil;
        if([selectedSearchNode isKindOfClass:[SiteNode class]] || [selectedSearchNode isKindOfClass:[NetworkSiteNode class]]) {
            objectId = [selectedSearchNode.value guid];
        }
        
        BaseHTTPRequest *down = [[CMISSearchHTTPRequest alloc] initWithSearchPattern:searchPattern folderObjectId:objectId 
                                                                         accountUUID:accountUUID tenantID:tenantID];
        
        [down setDelegate:self];
        [self setSearchDownload:down];
        [down startAsynchronous];
        [down release];
        [search resignFirstResponder];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
}

- (void) detailViewControllerChanged:(NSNotification *) notification {
    id sender = [notification object];
    
    if(sender && ![sender isEqual:self]) {
        [selectedIndex release];
        selectedIndex = nil;
        
        [table selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
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

- (void) searchNotAvailableAlert
{
    displayErrorMessageWithTitle(NSLocalizedString(@"searchUnavailableDialogMessage", @"Search is not available for this repository"), NSLocalizedString(@"searchUnavailableDialogTitle", @"Search Not Available"));
}

#pragma mark - NotificationCenter methods

- (void) applicationWillResignActive:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in SearchViewController");
    [searchDownload cancel];
    [serviceDocumentRequest clearDelegatesAndCancel];
}

- (void)handleAccountListUpdated:(NSNotification *) notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSString *uuid = [userInfo objectForKey:@"uuid"];
    BOOL isReset = [[userInfo objectForKey:@"reset"] boolValue];
    
    if(self.selectedSearchNode && ([[self.selectedSearchNode accountUUID] isEqualToString:uuid] || isReset) ) 
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

@end
