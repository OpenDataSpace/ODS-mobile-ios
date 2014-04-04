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
//  ActivitiesTableViewController.m
//

#import "ActivitiesTableViewController.h"
#import "IFTextViewTableView.h"
#import "Theme.h"
#import "ActivityTableCellController.h"
#import "IFTemporaryModel.h"
#import "Activity.h"
#import "AlfrescoAppDelegate.h"
#import "TableCellViewController.h"
#import "RepositoryServices.h"
#import "ObjectByIdRequest.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"
#import "MetaDataTableViewController.h"
#import "WhiteGlossGradientView.h"
#import "ThemeProperties.h"
#import "TableViewHeaderView.h"
#import "AccountManager.h"

@interface ActivitiesTableViewController(private)
- (void) loadActivities;
- (void) startHUD;
- (void) stopHUD;

- (void) noActivitiesForRepositoryError;
- (void) failedToFetchActivitiesError;

- (void)startObjectByIdRequest:(NSString *)objectId withFinishAction:(SEL)finishAction accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;
- (void)startDownloadRequest:(ObjectByIdRequest *) request;
- (void)startMetadataRequest:(ObjectByIdRequest *) request;
- (void)objectByIdNotFoundDialog;

- (void) presentMetadataErrorView:(NSString *)errorMessage;
@end

@implementation ActivitiesTableViewController

@synthesize HUD;
@synthesize activitiesRequest;
@synthesize objectByIdRequest;
@synthesize metadataRequest;
@synthesize downloadProgressBar;
@synthesize selectedActivity;
@synthesize cellSelection;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;

#pragma mark - View lifecycle
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [activitiesRequest clearDelegatesAndCancel];
    [objectByIdRequest clearDelegatesAndCancel];
    [metadataRequest clearDelegatesAndCancel];
    
    [HUD release];
    [activitiesRequest release];
    [objectByIdRequest release];
    [metadataRequest release];
    [downloadProgressBar release];
    [selectedActivity release];
    [cellSelection release];
    [_refreshHeaderView release];
    [_lastUpdated release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) name:kNotificationAccountListUpdated object:nil];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:NSLocalizedString(@"activities.view.title", @"Activity Table View Title")]; 
    
    if(IS_IPAD) {
        self.clearsSelectionOnViewWillAppear = NO;
    }

	// Pull to Refresh
    self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                arrowImageName:@"pull-to-refresh.png"
                                                                     textColor:[ThemeProperties pullToRefreshTextColor]] autorelease];
    [self.refreshHeaderView setDelegate:self];
    [self setLastUpdated:[NSDate date]];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];
    [self loadActivities];
}

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

- (void)loadActivities 
{
    [self startHUD];
    
    [[ActivityManager sharedManager] setDelegate:self];
    [[ActivityManager sharedManager] startActivitiesRequest];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate
- (void)activityManager:(ActivityManager *)activityManager requestFinished:(NSArray *)activities 
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    activities = [activities sortedArrayUsingDescriptors:sortDescriptors];
    [sortDescriptor release];
    
    NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:activities, nil] 
                                                                        forKeys:[NSArray arrayWithObjects:@"activities", nil]];
    
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
    [self updateAndReload];
    [self dataSourceFinishedLoadingWithSuccess:YES];
    [self stopHUD];
    activitiesRequest = nil;
}

- (void)activityManagerRequestFailed:(ActivityManager *)activityManager
{
    AlfrescoLogDebug(@"Request in ActivitiesTableViewController failed! %@", [activityManager.error description]);

    [self failedToFetchActivitiesError];
    [self dataSourceFinishedLoadingWithSuccess:NO];
    [self stopHUD];
    activitiesRequest = nil;
}

- (void)requestFinished:(ASIHTTPRequest *)sender
{
    if([sender isEqual:metadataRequest]) 
    {
        CMISTypeDefinitionHTTPRequest *tdd = (CMISTypeDefinitionHTTPRequest *) sender;
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[tdd repositoryItem] 
                                                                                             accountUUID:[tdd accountUUID] 
                                                                                                tenantID:[tdd tenantID]];
        [viewController setCmisObjectId:tdd.repositoryItem.guid];
        [viewController setMetadata:tdd.repositoryItem.metadata];
        [viewController setPropertyInfo:tdd.properties];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [viewController release];
    }
    
    [self stopHUD];
    [self.tableView setAllowsSelection:YES];
    activitiesRequest = nil;
}

-(void)requestFailed:(ASIHTTPRequest *)request
{
    AlfrescoLogDebug(@"Request in ActivitiesTableViewController failed! %@", [request.error description]);
    
    [self stopHUD];
    [self.tableView setAllowsSelection:YES];
    activitiesRequest = nil;
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self objectByIdNotFoundDialog];
}


#pragma mark -
#pragma mark UITableViewDelegate

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
#pragma mark Generic Table View Construction
- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]] && ![activitiesRequest isExecuting]) {
        return;
	}
    
    // Arrays for section headers, bodies and footers
    NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];

    NSArray *activities = [self.model objectForKey:@"activities"];
    
    for (NSDictionary *activity in activities) 
    {
        Activity *parser = [[[Activity alloc] initWithJsonDictionary:activity] autorelease];
        AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:[parser accountUUID]];
        NSString *subtitle = [NSString stringWithFormat:@"%@ • %@", [accountInfo description],  [parser activityDate]];
                
        ActivityTableCellController *cellController = [[ActivityTableCellController alloc] initWithTitle:[parser activityText] andSubtitle:subtitle inModel:self.model];
        
        [cellController setActivity:parser];
        [cellController setImage:[parser iconImage]];
        [cellController setSubtitleTextColor:[UIColor grayColor]];
        //[cellController setTitleFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
        
        if (parser.isDocument && ![[[cellController activity] activityType] hasSuffix:@"-deleted"])
        {
            [cellController setSelectionTarget:self];
            [cellController setSelectionAction:@selector(performActivitySelected:withSelection:)];
            [cellController setAccessoryView:[UIButton buttonWithType:UIButtonTypeInfoDark]];
            
            cellController.selectionStyle = UITableViewCellSelectionStyleBlue;
        } 
        else 
        {
            cellController.accesoryType = UITableViewCellAccessoryNone; 
            cellController.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        NSMutableArray *cellGroup;
        
        if(![headers containsObject:[parser groupHeader]]) {
            cellGroup = [NSMutableArray array];
            [groups addObject:cellGroup];
            [headers addObject:[parser groupHeader]];
            [footers addObject:@""];
        } else {
            NSInteger index = [headers indexOfObject:[parser groupHeader]];
            cellGroup = [groups objectAtIndex:index];
        }
        
        [cellGroup addObject:cellController];
        [cellController release];
        [self.tableView setAllowsSelection:YES];
    }

    //model is not loaded yet.
    if([activities count] == 0) {
        TableCellViewController *cell;
        NSString *error = [self.model objectForKey:@"error"];
        
        cell = [[TableCellViewController alloc]initWithAction:nil onTarget:nil];
        
        if(error) {
            cell.textLabel.text = error;
        } else if(activitiesRequest == nil) {
            cell.textLabel.text = NSLocalizedString(@"activities.empty", @"No activities Available");
        } else {
            cell.textLabel.text = @" ";
        }
        
        cell.shouldResizeTextToFit = YES;
        [headers addObject:@""];
        [footers addObject:@""];
        
        NSMutableArray *group = [NSMutableArray array];
        [group addObject:cell];
        [cell release];
        
        [groups addObject:group];
        [self.tableView setAllowsSelection:NO];
    }
    
    [tableGroups release];
    [tableHeaders release];
    [tableFooters release];
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	tableFooters = [footers retain];
	
    [self setEditing:NO animated:YES];
    
	[self assignFirstResponderHostToCellControllers];
}

- (void) noActivitiesForRepositoryError {
    NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:NSLocalizedString(@"activities.unavailable.for-repository", @"No activities Available"), nil] forKeys:[NSArray arrayWithObjects:@"error", nil]];
    
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
    [self updateAndReload];
}

- (void) failedToFetchActivitiesError {
    NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:NSLocalizedString(@"activities.unavailable", @"No activities Available"), nil] forKeys:[NSArray arrayWithObjects:@"error", nil]];
    
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
    [self updateAndReload];
}

- (void) performActivitySelected:(id)sender withSelection:(NSString *)selection 
{
    //Prevent the tapping unless there is no loading in process
    if(selectedActivity == nil) 
    {
        [self.tableView setAllowsSelection:NO];
        ActivityTableCellController *activityCell = (ActivityTableCellController *)sender;
        Activity *activity = activityCell.activity;
        AlfrescoLogDebug(@"User tapped row, selection type: %@", selection);
        
        self.cellSelection = selection;
        self.selectedActivity = activity;
        
        [self startHUD];
        
        CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
        [serviceManager addListener:self forAccountUuid:[activity accountUUID]];
        [serviceManager loadServiceDocumentForAccountUuid:[activity accountUUID]];
    }
}

#pragma mark -
#pragma mark Document download methods

- (void)startObjectByIdRequest:(NSString *)objectId withFinishAction:(SEL)finishAction accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self.objectByIdRequest = [ObjectByIdRequest defaultObjectById:objectId accountUUID:uuid tenantID:tenantID];
    [self.objectByIdRequest setDidFinishSelector:finishAction];
    [self.objectByIdRequest setDidFailSelector:@selector(objectByIdRequestFailed:)];
    [self.objectByIdRequest setDelegate:self];
    self.objectByIdRequest.suppressAllErrors = YES;
    
    [self startHUD];
    [self.objectByIdRequest startAsynchronous];
    
    AlfrescoLogDebug(@"Starting objectByIdRequest");
}

- (void)startDownloadRequest:(ObjectByIdRequest *)request 
{
    AlfrescoLogDebug(@"objectByIdRequest finished with: %@", request.responseString);
    RepositoryItem *repositoryNode = request.repositoryItem;
    
    if(repositoryNode.contentLocation && request.responseStatusCode < 400) 
    {
        AlfrescoLogTrace(@"cmis guid %@", [repositoryNode guid]);

        NSString *urlStr  = repositoryNode.contentLocation;
        NSURL *contentURL = [NSURL URLWithString:urlStr];
        [self setDownloadProgressBar:[DownloadProgressBar createAndStartWithURL:contentURL delegate:self
                                                                        message:NSLocalizedString(@"Downloading Document", @"Downloading Document")
                                                                       filename:repositoryNode.title 
                                                                  contentLength:[repositoryNode contentStreamLength] 
                                                                    accountUUID:[request accountUUID]
                                                                       tenantID:[request tenantID]]];
        [[self downloadProgressBar] setCmisObjectId:[repositoryNode guid]];
        [[self downloadProgressBar] setCmisContentStreamMimeType:[[repositoryNode metadata] objectForKey:@"cmis:contentStreamMimeType"]];
        [[self downloadProgressBar] setVersionSeriesId:[repositoryNode versionSeriesId]];
        [[self downloadProgressBar] setRepositoryItem:repositoryNode];
    }
    
    if(request.responseStatusCode >= 400) {
        [self objectByIdNotFoundDialog];
    }
    
    [self stopHUD];
    self.objectByIdRequest = nil;
}

- (void)startMetadataRequest:(ObjectByIdRequest *)request
{
    AlfrescoLogDebug(@"objectByIdRequest finished with: %@", request.responseString);
    
    RepositoryItem *repositoryNode = request.repositoryItem;
    if (repositoryNode.describedByURL && request.responseStatusCode < 400) 
    {
        CMISTypeDefinitionHTTPRequest *down = [[CMISTypeDefinitionHTTPRequest alloc] initWithURL:[NSURL URLWithString:repositoryNode.describedByURL] 
                                                                                     accountUUID:[request accountUUID]];
        [down setTenantID:[request tenantID]];
        [down setRepositoryItem:repositoryNode];
        [down setDelegate:self];
        [down startAsynchronous];
        [self setMetadataRequest:down];
        [down release];
    } 
    else if(request.responseStatusCode < 400) {
        [self stopHUD];
        [self presentMetadataErrorView:NSLocalizedString(@"metadata.error.cell.notsaved", @"Metadata not saved for the download")];
    }
    
    if(request.responseStatusCode >= 400) {
        [self stopHUD];
        [self objectByIdNotFoundDialog];
    }

    self.objectByIdRequest = nil;
}

- (void)objectByIdRequestFailed: (ASIHTTPRequest *) request {
    AlfrescoLogDebug(@"objectByIdRequest failed");
    [self requestFailed:request];
    self.objectByIdRequest = nil;
}

- (void)presentMetadataErrorView:(NSString *)errorMessage 
{
    MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                          cmisObject:nil accountUUID:nil tenantID:nil];
    [viewController setErrorMessage:errorMessage];
    [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
    [viewController release];
}

- (void)objectByIdNotFoundDialog
{
    displayErrorMessageWithTitle(NSLocalizedString(@"activities.document.notfound.message", @"The document could not be found"), NSLocalizedString(@"activities.document.notfound.title", @"Document not found"));
}

#pragma mark -
#pragma mark DownloadProgressBar Delegate

- (void)download:(DownloadProgressBar *)down completeWithPath:(NSString *)filePath 
{
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
	[doc setCmisObjectId:down.cmisObjectId];
    [doc setContentMimeType:[down cmisContentStreamMimeType]];
    [doc setHidesBottomBarWhenPushed:YES];
    [doc setSelectedAccountUUID:[down selectedAccountUUID]];
    [doc setTenantID:[down tenantID]];
    [doc setShowReviewButton:NO];
    
    DownloadMetadata *fileMetadata = down.downloadMetadata;
    NSString *filename;
    
    if (fileMetadata.key)
    {
        filename = fileMetadata.key;
    }
    else
    {
        filename = down.filename;
    }
    
    [doc setFileName:filename];
    [doc setFilePath:filePath];
    [doc setFileMetadata:fileMetadata];
    [doc setIsRestrictedDocument:[[AlfrescoMDMLite sharedInstance] isRestrictedDocument:fileMetadata]];
	
	[IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
	[doc release];

    [self.tableView setAllowsSelection:YES];
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down {
    [self.tableView setAllowsSelection:YES];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark -
#pragma mark CMISServiceManagerListener Methods

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest 
{
    NSString *accountUUID = [selectedActivity accountUUID];
    NSString *tenantID = [selectedActivity tenantID];
    
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:accountUUID tenantID:tenantID];
    if(repoInfo) 
    {
        if(self.cellSelection == kActivityCellRowSelection) 
        {
            [self startObjectByIdRequest:[selectedActivity objectId] withFinishAction:@selector(startDownloadRequest:) 
                             accountUUID:accountUUID tenantID:tenantID];
        } 
        else if(self.cellSelection == kActivityCellDisclosureSelection) 
        {
            [self startObjectByIdRequest:[selectedActivity objectId] withFinishAction:@selector(startMetadataRequest:) 
                             accountUUID:accountUUID tenantID:tenantID];
        }
    } else {
        //Service document not loaded
        [self stopHUD];
    }
    self.cellSelection = nil;
    self.selectedActivity = nil;
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:accountUUID];
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)serviceRequest {
    self.cellSelection = nil;
    self.cellSelection = nil;
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:[selectedActivity accountUUID]];
    [self stopHUD];
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

#pragma mark - NotificationCenter methods
- (void) detailViewControllerChanged:(NSNotification *) notification {
    id sender = [notification object];
    
    if(sender && ![sender isEqual:self]) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDetailViewControllerChangedNotification object:nil];
}

- (void) applicationWillResignActive:(NSNotification *) notification {
    AlfrescoLogDebug(@"applicationWillResignActive in ActivitiesTableViewController");
    [activitiesRequest clearDelegatesAndCancel];
}

- (void)handleAccountListUpdated:(NSNotification *) notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    [[self navigationController] popToRootViewControllerAnimated:NO];
    [self loadActivities];
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // Prevent trying to load activities when no accounts are active
    // in those cases the ActivityManager calls the delegate immediately and the
    // Push to refresh animation does not get cleared because the animation is in progress
    NSArray *activeAccounts = [[AccountManager sharedManager] activeAccounts];
    if([activeAccounts count] > 0)
    {
        [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

#pragma mark -
#pragma mark EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    if (![activitiesRequest isExecuting])
    {
        [self loadActivities];
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

#pragma mark -

@end
