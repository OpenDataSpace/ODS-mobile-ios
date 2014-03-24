//
//  ChooserFolderViewController.m
//  FreshDocs
//
//  Created by bdt on 11/13/13.
//
//

#import "ChooserFolderViewController.h"
#import "IFTextViewTableView.h"
#import "RepositoryServices.h"
#import "TableCellViewController.h"
#import "RootViewController.h"
#import "AccountManager.h"
#import "Utility.h"
#import "ThemeProperties.h"
#import "NSURL+HTTPURLUtils.h"
#import "LinkRelationService.h"

NSString * const  kMoveTargetTypeRepo = @"TYPE_REPO";
NSString * const  kMoveTargetTypeFolder = @"TYPE_FOLDER";;

@interface ChooserFolderViewController ()

@end

@implementation ChooserFolderViewController
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize viewTitle = _viewTitle;
@synthesize HUD = _HUD;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;
@synthesize repositoriesForAccount = _repositoriesForAccount;
@synthesize itemType = _itemType;
@synthesize folderItems = _folderItems;
@synthesize tenantID = _tenantID;
@synthesize repositoryID = _repositoryID;
@synthesize parentItem = _parentItem;
@synthesize selectedDelegate = _selectedDelegate;

#pragma mark dealloc & init

- (void)dealloc
{
    [[CMISServiceManager sharedManager] removeAllListeners:self];
}

- (id)initWithAccountUUID:(NSString *)uuid
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        _selectedAccountUUID = uuid;
        _repositoriesForAccount = nil;
        _folderItems = nil;
        _parentItem = nil;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)loadView
{
    self.view = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	[(UITableView *)self.view setDelegate:self];
	[(UITableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [[self navigationItem] setTitle:[self viewTitle]];
    
    [self.tableView setRowHeight:kDefaultTableCellHeight];
    
    // Pull to Refresh
    self.refreshHeaderView = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                               arrowImageName:@"pull-to-refresh.png"
                                                                    textColor:[ThemeProperties pullToRefreshTextColor]];
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
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"dialog.chooser.cancel", @"Cancel") style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPress)];
    UIBarButtonItem *fixSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace        target:self action:nil];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"dialog.chooser.confirm", @"Choose") style:UIBarButtonItemStyleBordered target:self action:@selector(chooseButtonPress)];
    
   if (_parentItem != nil && [_parentItem isKindOfClass:[RepositoryItem class]]) {
       [doneBtn setEnabled:YES];
   }else {
       [doneBtn setEnabled:NO];
   }
    self.toolbarItems = [NSArray arrayWithObjects:cancelBtn, fixSpace,doneBtn, nil];
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    [[CMISServiceManager sharedManager] removeAllListeners:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    [self startHUD];
    
    //load repo list first
    if ([_itemType isEqualToString:kMoveTargetTypeRepo]) {
        CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
        [serviceManager addListener:self forAccountUuid:[self selectedAccountUUID]];
        [serviceManager addQueueListener:self];
        [serviceManager loadServiceDocumentForAccountUuid:[self selectedAccountUUID]];
    }else if ([_itemType isEqualToString:kMoveTargetTypeFolder]) {
        if (_parentItem != nil && [_parentItem isKindOfClass:[RepositoryInfo class]]) {
            [self companyHomeRequest];
        }else if (_parentItem != nil && [_parentItem isKindOfClass:[RepositoryItem class]]) {
            [self folderItemsRequest];
        }
    }
    
    
    [self setupBackButton];
}

- (void)companyHomeRequest
{
    NSString *folder = [_parentItem rootFolderHref];
    NSDictionary *defaultParamsDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];
    NSURL *folderChildrenCollectionURL = [[NSURL URLWithString:folder] URLByAppendingParameterDictionary:defaultParamsDictionary];
    
    FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithURL:folderChildrenCollectionURL accountUUID:self.selectedAccountUUID];
    [down setDelegate:self];
    [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
    [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
    [down setParentTitle:[[self navigationItem] title]];
    [down setContext:@"rootCollection"];
    [down setTenantID:self.tenantID];
    
    [down startAsynchronous];
}

- (void)folderItemsRequest {
    RepositoryItem *item = (RepositoryItem*)_parentItem;
    NSDictionary *optionalArguments = [[LinkRelationService shared] optionalArgumentsForFolderChildrenCollectionWithMaxItems:nil skipCount:nil
                                                                                                                      filter:kCMISExtendedPropertyFilterValue
                                                                                                     includeAllowableActions:YES includeRelationships:NO
                                                                                                             renditionFilter:nil orderBy:nil includePathSegment:NO];
    NSURL *getChildrenURL = [[LinkRelationService shared] getFolderTreeURLForCMISFolder:item withOptionalArguments:optionalArguments];
    FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:self.selectedAccountUUID];
    [down setDelegate:self];
    [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
    [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
    [down setItem:item];
    [down setParentTitle:item.title];
    [down setContext:@"childFolder"];
    [down startAsynchronous];
}

- (void)setupBackButton
{
    //TODO:cancel move operation ?
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView DataSource & Delegate
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([_itemType isEqualToString:kMoveTargetTypeRepo] && _repositoriesForAccount != nil) {
        return [_repositoriesForAccount count];
    }else if ([_itemType isEqualToString:kMoveTargetTypeFolder] && _folderItems != nil) {
        return [_folderItems count];
    }
    
    return 0;  //default is zero.
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kRepoCellIdentifier = @"RepoCellIdentifier";
    static NSString *kFolderCellIdentifier = @"FolderCellIdentifier";
    
    UITableViewCell *cell = nil;
    
    if ([_itemType isEqualToString:kMoveTargetTypeRepo]) {
        cell = [tableView dequeueReusableCellWithIdentifier:kRepoCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kRepoCellIdentifier];
        }
        RepositoryInfo *repoInfo = [[self repositoriesForAccount] objectAtIndex:indexPath.row];
        cell.textLabel.text = [repoInfo repositoryName];
        [cell.imageView setImage:[UIImage imageNamed:kNetworkIcon_ImageName]];
    }else if ([_itemType isEqualToString:kMoveTargetTypeFolder]){
        cell = [tableView dequeueReusableCellWithIdentifier:kFolderCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kFolderCellIdentifier];
        }
        RepositoryItem *repoItem = [[self folderItems] objectAtIndex:indexPath.row];
        NSString *filename = [repoItem.metadata valueForKey:@"cmis:name"];
        cell.textLabel.text = filename;
        [cell.imageView setImage:[UIImage imageNamed:@"folder.png"]];
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_itemType isEqualToString:kMoveTargetTypeRepo]) {
        RepositoryInfo *repoInfo = [[self repositoriesForAccount] objectAtIndex:indexPath.row];
        ChooserFolderViewController *folderViewController = [[ChooserFolderViewController alloc] initWithAccountUUID:self.selectedAccountUUID];
        [folderViewController setItemType:kMoveTargetTypeFolder];
        [folderViewController setViewTitle:repoInfo.repositoryName];
        [folderViewController setRepositoryID:repoInfo.repositoryId];
        [folderViewController setTenantID:repoInfo.tenantID];
        [folderViewController setParentItem:repoInfo];
        [folderViewController setSelectedDelegate:_selectedDelegate];
        [self.navigationController pushViewController:folderViewController animated:YES];
    }else if ([_itemType isEqualToString:kMoveTargetTypeFolder]) {
        RepositoryItem *repoItem = [self.folderItems objectAtIndex:indexPath.row];
        ChooserFolderViewController *folderViewController = [[ChooserFolderViewController alloc] initWithAccountUUID:self.selectedAccountUUID];
        [folderViewController setItemType:kMoveTargetTypeFolder];
        [folderViewController setViewTitle:[repoItem.metadata valueForKey:@"cmis:name"]];
        [folderViewController setRepositoryID:self.repositoryID];
        [folderViewController setTenantID:self.tenantID];
        [folderViewController setParentItem:repoItem];
        [folderViewController setSelectedDelegate:_selectedDelegate];
        [self.navigationController pushViewController:folderViewController animated:YES];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kDefaultTableCellHeight;
}

#pragma mark - CMISServiceManagerListener

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    NSArray *array = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:[self selectedAccountUUID]]];
    //TODO:disable config & backup reposiories.
    NSMutableArray *reposArr = [NSMutableArray array];
    for (RepositoryInfo *repo in array) {
        if (repo && ([repo.repositoryName caseInsensitiveCompare:@"config"]
                    != NSOrderedSame && [repo.repositoryName caseInsensitiveCompare:@"backup"] != NSOrderedSame)) {
            [reposArr addObject:repo];
        }
    }
    [self setRepositoriesForAccount:reposArr];
    
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:[self selectedAccountUUID]];
    
    [self.tableView reloadData];
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

- (void)reloadData
{
    [self startHUD];
    
    if ([_itemType isEqualToString:kMoveTargetTypeRepo]) {
        CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
        [serviceManager addListener:self forAccountUuid:[self selectedAccountUUID]];
        [serviceManager addQueueListener:self];
        [serviceManager loadServiceDocumentForAccountUuid:[self selectedAccountUUID]];
    }else if ([_itemType isEqualToString:kMoveTargetTypeFolder]) {
        if (_parentItem != nil && [_parentItem isKindOfClass:[RepositoryInfo class]]) {
            [self companyHomeRequest];
        }
    }
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
}

- (void)stopHUD
{
	if (self.HUD)
    {
        stopProgressHUD(self.HUD);
        self.HUD = nil;
    }
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

#pragma mark - ToolBar Button Actions

- (void) cancelButtonPress {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) chooseButtonPress {
    if ([_selectedDelegate respondsToSelector:@selector(selectedItem:repositoryID:)]) {
        [_selectedDelegate selectedItem:_parentItem repositoryID:_repositoryID];
    }
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - FolderItemsHTTPRequest delegate methods

- (void)folderItemsRequestFinished:(ASIHTTPRequest *)request
{
    [self stopHUD];
	// if we're being told that a list of folder items is ready
	if ([request isKindOfClass:[FolderItemsHTTPRequest class]])
    {
		FolderItemsHTTPRequest *fid = (FolderItemsHTTPRequest *) request;
        [self setFolderItems:[fid children]];
        [self.tableView reloadData];
        [self dataSourceFinishedLoadingWithSuccess:YES];
        
        [self clearAllHUDs];
    }
}

- (void)folderItemsRequestFailed:(ASIHTTPRequest *)request
{
    [self dataSourceFinishedLoadingWithSuccess:NO];
    [self clearAllHUDs];
    AlfrescoLogDebug(@"FAILURE %@", [request error]);
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self clearAllHUDs];
    AlfrescoLogDebug(@"FAILURE %@", [request error]);
}
@end
