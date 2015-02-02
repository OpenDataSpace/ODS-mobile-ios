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
//  RepositoriesViewController.m
//

#import "RepositoriesViewController.h"
#import "IFTextViewTableView.h"
#import "RepositoryServices.h"
#import "TableCellViewController.h"
#import "RootViewController.h"
#import "AccountManager.h"
#import "Utility.h"
#import "ThemeProperties.h"
#import "LinkRelationService.h"
#import "RepositoryNodeViewController.h"
#import "NSURL+HTTPURLUtils.h"

@interface RepositoriesViewController ()
- (void)repositoryCellPressed:(id)sender;
- (void)setupBackButton;
@end


@implementation RepositoriesViewController
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize repositoriesForAccount = _repositoriesForAccount;
@synthesize viewTitle = _viewTitle;
@synthesize HUD = _HUD;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;

#pragma mark dealloc & init

- (void)dealloc
{
    [[CMISServiceManager sharedManager] removeAllListeners:self];
    
    [_viewTitle release];
    [_selectedAccountUUID release];
    [_repositoriesForAccount release];
    [_HUD release];
    [_refreshHeaderView release];
    [_lastUpdated release];
    
    [super dealloc];
}

- (id)initWithAccountUUID:(NSString *)uuid
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        _selectedAccountUUID = [uuid retain];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)loadView
{
    self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self navigationItem] setTitle:[self viewTitle]];
    
    [self.tableView setRowHeight:kDefaultTableCellHeight];

	// Pull to Refresh
    self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                arrowImageName:@"pull-to-refresh.png"
                                                                     textColor:[ThemeProperties pullToRefreshTextColor]] autorelease];
    [self.refreshHeaderView setDelegate:self];
    [self setLastUpdated:[NSDate date]];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
    }
#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopHUD];
    [[CMISServiceManager sharedManager] removeAllListeners:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startHUD];
    
    CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
    [serviceManager addListener:self forAccountUuid:[self selectedAccountUUID]];
    [serviceManager addQueueListener:self];
    [serviceManager loadServiceDocumentForAccountUuid:[self selectedAccountUUID]];
    
    [self setupBackButton];
}

- (void)setupBackButton
{
    //Retrieve account count
    NSArray *allAccounts = [[AccountManager sharedManager] activeAccounts];
    NSInteger accountCount = [allAccounts count];
    if (accountCount == 1) 
    {
        [self.navigationItem setHidesBackButton:YES];
    }
    else 
    {
        [self.navigationItem setHidesBackButton:NO];
    }
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillUnload
{
    [[CMISServiceManager sharedManager] removeAllListeners:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - GenericTableView Methods

static NSString *RepositoryInfoKey = @"RepositoryInfo";

- (void)constructTableGroups
{
    if (![self model])
    {
        [self setModel:[[[IFTemporaryModel alloc] init] autorelease]];
    }
    
	NSMutableArray *headers = [NSMutableArray array];
    NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];
    
    NSMutableArray *mainGroup = [NSMutableArray array];
    [headers addObject:@""];
    [groups addObject:mainGroup];
    [footers addObject:@""];
    
    for (RepositoryInfo *repoInfo in [self repositoriesForAccount]) 
    {
        if ([repoInfo.repositoryName caseInsensitiveCompare:@"config"] == NSOrderedSame) { //TODO:disable config and backup repo.
            continue;
        }
        IFTemporaryModel *tmpModel = [[IFTemporaryModel alloc] init];
        [tmpModel setObject:repoInfo forKey:RepositoryInfoKey];
        
        NSString *labelText = NSLocalizedString([repoInfo repositoryName], nil) ;
#ifndef OPEN_DATA_SPACE
        if ([repoInfo tenantID]) {
            labelText = [repoInfo tenantID];
        }
#endif
        TableCellViewController *cellController = [[TableCellViewController alloc] initWithAction:@selector(repositoryCellPressed:)
                                                                                         onTarget:self withModel:tmpModel];
        [tmpModel release];
        
        [cellController setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cellController setSelectionStyle:UITableViewCellSelectionStyleBlue];
        [cellController.textLabel setText:labelText];
        [[cellController imageView] setImage:[UIImage imageNamed:kNetworkIcon_ImageName]];
        
        [mainGroup addObject:cellController];
        [cellController release];
    }
    
    if ([mainGroup count] != 0) {
        tableHeaders = [headers retain];
        tableGroups = [groups retain];
        tableFooters = [footers retain];
    }
}


#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}


#pragma mark - CMISServiceManagerListener

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    NSArray *array = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:[self selectedAccountUUID]]];
    [self setRepositoriesForAccount:array];
    
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:[self selectedAccountUUID]];
    
    [self updateAndReload];
    [self dataSourceFinishedLoadingWithSuccess:YES];
    
    [self clearAllHUDs];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:[self selectedAccountUUID]];
    [self dataSourceFinishedLoadingWithSuccess:NO];
    
    [self clearAllHUDs];
}

#pragma mark - Action Handlers

- (void)repositoryCellPressed:(id)sender
{
    TableCellViewController *cellController = (TableCellViewController *)sender;
    IFTemporaryModel *tmpModel = [cellController model];
    RepositoryInfo *repoInfo = [tmpModel objectForKey:RepositoryInfoKey];
    
#if 0
    NSString *repoName = [repoInfo repositoryName];
#ifndef OPEN_DATA_SPACE
    if ([repoInfo tenantID]) {
        repoName = [repoInfo tenantID];
    }
#endif

    RootViewController *nextController = [[RootViewController alloc] init];//initWithNibName:kFDRootViewController_NibName bundle:nil];
    [nextController setSelectedAccountUUID:[self selectedAccountUUID]];
    [nextController setTenantID:[repoInfo tenantID]];
    [nextController setRepositoryID:[repoInfo repositoryId]];
    [[nextController navigationItem] setTitle:NSLocalizedString(repoName, nil)];
    
    [[self navigationController] pushViewController:nextController animated:YES];
    [nextController release];
#else
    
    NSString *folder = [repoInfo rootFolderHref];
    NSDictionary *defaultParamsDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];
    NSURL *folderChildrenCollectionURL = [[NSURL URLWithString:folder] URLByAppendingParameterDictionary:defaultParamsDictionary];
    FolderItemsHTTPRequest *request = [[[FolderItemsHTTPRequest alloc] initWithURL:folderChildrenCollectionURL accountUUID:self.selectedAccountUUID] autorelease];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(folderItemsRequestFinished:)];
    [request setDidFailSelector:@selector(folderItemsRequestFailed:)];
    [request setParentTitle:[[self navigationItem] title]];
    [request setTenantID:[repoInfo tenantID]];
    [request setRepoInfo:repoInfo];
    
    [request startAsynchronous];
    
    [self startHUD];
#endif
}

- (void)reloadData
{
    [self startHUD];
    
    CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
    [serviceManager addListener:self forAccountUuid:[self selectedAccountUUID]];
    [serviceManager addQueueListener:self];
    [serviceManager reloadServiceDocumentForAccountUuid:[self selectedAccountUUID]];
}

- (void)dataSourceFinishedLoadingWithSuccess:(BOOL)wasSuccessful
{
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    
    if (wasSuccessful)
    {
        [self setLastUpdated:[NSDate date]];
        [self.refreshHeaderView refreshLastUpdatedDate];
    }
}

#pragma mark - MBProgressHUD Helper Methods

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    // Remove HUD from screen when the HUD was hidded
    [self stopHUD];
}

- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView([[self navigationController] view]);
        [self.HUD setDelegate:self];
	}
    [self.tableView setAllowsSelection:NO];
}

- (void)stopHUD
{
	if (self.HUD)
    {
        stopProgressHUD(self.HUD);
        self.HUD = nil;
    }
    
    [self.tableView setAllowsSelection:YES];
}

- (void)clearAllHUDs
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        for (UIView *view in [self.navigationController.view subviews])
        {
            if ([view class] == [MBProgressHUD class])
            {
                stopProgressHUD((MBProgressHUD*)view);
            }
        }
		self.HUD = nil;
        [self.tableView setAllowsSelection:YES];
    });
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
    [self reloadData];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return (self.HUD != nil);
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [self lastUpdated];
}

#pragma mark - FolderItemsHTTPRequest delegate methods

- (void)folderItemsRequestFinished:(ASIHTTPRequest *)request
{
    [self stopHUD];
    if ([request isKindOfClass:[FolderItemsHTTPRequest class]])
    {
        FolderItemsHTTPRequest *fid = (FolderItemsHTTPRequest *) request;
        
        // create a new view controller for the list of repository items (documents and folders)
        RepositoryNodeViewController *vc = [[RepositoryNodeViewController alloc] initWithStyle:UITableViewStylePlain];
        [vc setFolderItems:fid];
        [vc setTitle:[fid parentTitle]];
        [vc setGuid:[[fid repoInfo] repositoryId]];
        [vc setSelectedAccountUUID:self.selectedAccountUUID];
        [vc setTenantID:fid.tenantID];
        
        
        // push that view onto the nav controller's stack
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
}

- (void)folderItemsRequestFailed:(ASIHTTPRequest *)request
{
    [self clearAllHUDs];
}

@end
