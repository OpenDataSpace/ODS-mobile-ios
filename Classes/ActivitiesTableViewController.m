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
 * Portions created by the Initial Developer are Copyright (C) 2011
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
#import "IFValueCellController.h"
#import "SBJSON.h"
#import "Activity.h"
#import "ActivitiesHttpRequest.h"
#import "AlfrescoAppDelegate.h"
#import "TableCellViewController.h"
#import "RepositoryServices.h"
#import "Constants.h"
#import "ObjectByIdRequest.h"
#import "CMISTypeDefinitionDownload.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"
#import "Utility.h"
#import "MetaDataTableViewController.h"
#import "WhiteGlossGradientView.h"
#import "ThemeProperties.h"
#import "TableViewHeaderView.h"

@interface ActivitiesTableViewController(private)
- (void) loadActivities;
- (void) startHUD;
- (void) stopHUD;

- (void) noActivitiesForRepositoryError;
- (void) failedToFetchActivitiesError;

- (void)startObjectByIdRequest: (NSString *) objectId withFinishAction: (SEL)finishAction;
- (void) startDownloadRequest: (ObjectByIdRequest *) request;
- (void) startMetadataRequest: (ObjectByIdRequest *) request;
- (void)objectByIdNotFoundDialog;

- (void) presentMetadataErrorView:(NSString *)errorMessage;
@end

@implementation ActivitiesTableViewController

@synthesize HUD;
@synthesize activitiesRequest;
@synthesize serviceDocumentRequest;
@synthesize objectByIdRequest;
@synthesize metadataRequest;
@synthesize downloadProgressBar;
#pragma mark - View lifecycle

- (void)dealloc {
    [HUD release];
    [activitiesRequest release];
    [serviceDocumentRequest release];
    [objectByIdRequest release];
    [metadataRequest release];
    [downloadProgressBar release];
    [super dealloc];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    //self.tableView = nil;
    [HUD setTaskInProgress:NO];
    [HUD hide:YES];
    [HUD release];
    HUD = nil;
    
    /*IFGenericTableViewController
    [tableGroups release];
    tableGroups = nil;
    [tableFooters release];
    tableGroups = nil;
    [tableHeaders release];
    tableHeaders = nil;*/
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationRepositoryShouldReload object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    NSLog(@"Row selected before viewWillAppear: %d", [self.tableView.indexPathForSelectedRow row]);
    [super viewWillAppear:animated];
    NSLog(@"Row selected after viewWillAppear: %d", [self.tableView.indexPathForSelectedRow row]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:NSLocalizedString(@"activities.view.title", @"Activity Table View Title")];
    
    UIBarButtonItem *refreshButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(performReload:)] autorelease];
    
    [self.navigationItem setRightBarButtonItem:refreshButton];
    if ([[RepositoryServices shared] currentRepositoryInfo] == nil) {
        [self startHUD];
        
        ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequest]; 
        [request setDelegate:self];
        [request setDidFinishSelector:@selector(serviceDocumentRequestFinished:)];
        [request setDidFailSelector:@selector(serviceDocumentRequestFailed:)];
        [self setServiceDocumentRequest:request];
        [request startAsynchronous];
    } else if(![[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName]) {
        [self noActivitiesForRepositoryError];
    } else {
        [self loadActivities];
    }
    
    if(IS_IPAD) {
        self.clearsSelectionOnViewWillAppear = NO;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositoryShouldReload:) name:kNotificationRepositoryShouldReload object:nil];
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

- (void)loadActivities {
    [self startHUD];
    
    NSString *objectByIdTemplate = [[[RepositoryServices shared] currentRepositoryInfo] objectByIdUriTemplate];
    NSLog(@"objectByIdTemplate - %@", objectByIdTemplate);
    ActivitiesHttpRequest * request = [ActivitiesHttpRequest httpRequestActivities];
    [request setDelegate:self];
    [request startAsynchronous];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark Refresh UIBarButton
- (void) performReload:(id) sender {
    if(!activitiesRequest.isExecuting) {
        [self loadActivities];
    }
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate
-(void)requestFinished:(ASIHTTPRequest *)sender
{
    NSLog(@"ActivitiesHttpRequestDidFinish");
    ActivitiesHttpRequest * request = (ActivitiesHttpRequest *)sender;
    NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:request.activities, nil] 
                                                                        forKeys:[NSArray arrayWithObjects:@"activities", nil]];
    
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
    [self updateAndReload];
    
    [self stopHUD];
    activitiesRequest = nil;
}

-(void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"ActivitiesHttpRequest failed! %@", [request.error description]);
    [self failedToFetchActivitiesError];
    
    // TODO Make sure the string bundles are updated for the different targets
    NSString *failureMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"),
                                [request url]];
	
    UIAlertView *sdFailureAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"serviceDocumentRequestFailureTitle", @"Error")
															  message:failureMessage
															 delegate:nil 
													cancelButtonTitle:NSLocalizedString(@"Continue", nil)
													otherButtonTitles:nil] autorelease];
	[sdFailureAlert show];
    
    [self stopHUD];
    activitiesRequest = nil;
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
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
        NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray array], nil] forKeys:[NSArray arrayWithObjects:@"activities", nil]];
        
        [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
	}
    
    // Arrays for section headers, bodies and footers
    NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];

    NSArray *activities = [self.model objectForKey:@"activities"];
    
    for (NSDictionary *activity in activities) {
        Activity *parser = [[[Activity alloc] initWithJsonDictionary:activity] autorelease];
                
        ActivityTableCellController *cellController = [[ActivityTableCellController alloc] initWithTitle:[parser activityText] andSubtitle:[parser activityDate] inModel:self.model];
        
        [cellController setActivity:parser];
        [cellController setImage:[parser iconImage]];
        
        if(parser.isDocument && ![[[cellController activity] activityType] hasSuffix:@"-deleted"]) {
            [cellController setSelectionTarget:self];
            [cellController setSelectionAction:@selector(performActivitySelected:withSelection:)];
//            cellController.accesoryType = UITableViewCellAccessoryDetailDisclosureButton; 
            [cellController setAccessoryView:[UIButton buttonWithType:UIButtonTypeInfoDark]];
            cellController.selectionStyle = UITableViewCellSelectionStyleBlue;
        } else {
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

- (void) performActivitySelected: (id) sender withSelection: (NSString *) selection {
    ActivityTableCellController *activityCell = (ActivityTableCellController *)sender;
    Activity *activity = activityCell.activity;
    NSLog(@"User tapped row, selection type: %@", selection);
    
    if(selection == kActivityCellRowSelection) {
        [self startObjectByIdRequest:activity.objectId withFinishAction:@selector(startDownloadRequest:)];
    } else if(selection == kActivityCellDisclosureSelection) {
        [self startObjectByIdRequest:activity.objectId withFinishAction:@selector(startMetadataRequest:)];
    }
}

#pragma mark -
#pragma mark Document download methods

- (void)startObjectByIdRequest: (NSString *)objectId withFinishAction: (SEL)finishAction {
    self.objectByIdRequest = [ObjectByIdRequest defaultObjectById:objectId];
    [self.objectByIdRequest setDidFinishSelector:finishAction];
    [self.objectByIdRequest setDidFailSelector:@selector(objectByIdRequestFailed:)];
    [self.objectByIdRequest setDelegate:self];
    
    [self startHUD];
    [self.objectByIdRequest startAsynchronous];
    NSLog(@"Starting objectByIdRequest");
}

- (void) startDownloadRequest: (ObjectByIdRequest *) request {
    NSLog(@"objectByIdRequest finished with: %@", request.responseString);
    RepositoryItem *repositoryNode = request.repositoryItem;
    
    if(repositoryNode.contentLocation && request.responseStatusCode < 400) {
        NSString *urlStr  = repositoryNode.contentLocation;
        NSURL *contentURL = [NSURL URLWithString:urlStr];
        [self setDownloadProgressBar:[DownloadProgressBar createAndStartWithURL:contentURL delegate:self 
                                                                        message:NSLocalizedString(@"Downloading Documents", @"Downloading Documents")
                                                                       filename:repositoryNode.title contentLength:[repositoryNode contentStreamLength]]];
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

- (void) startMetadataRequest: (ObjectByIdRequest *) request{
    NSLog(@"objectByIdRequest finished with: %@", request.responseString);
    RepositoryItem *repositoryNode = request.repositoryItem;
    
    if(repositoryNode.describedByURL && request.responseStatusCode < 400) {
        CMISTypeDefinitionDownload *down = [[CMISTypeDefinitionDownload alloc] initWithURL:[NSURL URLWithString:repositoryNode.describedByURL] delegate:self];
        down.repositoryItem = repositoryNode;
        down.showHUD = NO;
        [down start];
        self.metadataRequest = down;
        [down release];
    } else if(request.responseStatusCode < 400) {
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
    NSLog(@"objectByIdRequest failed");
    [self requestFailed:request];
    self.objectByIdRequest = nil;
}

- (void) presentMetadataErrorView:(NSString *)errorMessage {
    MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                          cmisObject:nil];
    viewController.errorMessage = errorMessage;
    [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
    [viewController release];
}

- (void)objectByIdNotFoundDialog {
    UIAlertView *objectByIdNotFound = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"activities.document.notfound.title", @"Document not found")
															  message:NSLocalizedString(@"activities.document.notfound.message", @"The document could not be found")
															 delegate:nil 
													cancelButtonTitle:NSLocalizedString(@"Continue", nil)
													otherButtonTitles:nil] autorelease];
	[objectByIdNotFound show];
}

#pragma mark -
#pragma mark DownloadProgressBar Delegate

- (void) download:(DownloadProgressBar *)down completeWithData:(NSData *)data {
    
	NSString *nibName = @"DocumentViewController";
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:nibName bundle:[NSBundle mainBundle]];
	[doc setCmisObjectId:down.cmisObjectId];
    [doc setFileData:data];
    [doc setContentMimeType:[down cmisContentStreamMimeType]];
    [doc setHidesBottomBarWhenPushed:YES];
    
    DownloadMetadata *fileMetadata = down.downloadMetadata;
    NSString *filename;
    
    if(fileMetadata.key) {
        filename = fileMetadata.key;
    } else {
        filename = down.filename;
    }
    
    [doc setFileName:filename];
    [doc setFileMetadata:fileMetadata];
	
	[IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:@"detailViewControllerChanged" object:nil];
	[doc release];
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark -
#pragma mark AsynchronousDownloadDelegate methods

- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async {
    CMISTypeDefinitionDownload *tdd = (CMISTypeDefinitionDownload *) async;
    MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                          cmisObject:[tdd repositoryItem]];
    [viewController setCmisObjectId:tdd.repositoryItem.guid];
    [viewController setMetadata:tdd.repositoryItem.metadata];
    [viewController setPropertyInfo:tdd.properties];
    
    [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
    
    [viewController release];
    [self stopHUD];
}

- (void) asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error {
    NSLog(@"Error performing the described by request: %@", [error description]);
	[self stopHUD];
}

#pragma mark -
#pragma mark HTTP Request Handling

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)sender
{
	RepositoryServices *currentRepository = [RepositoryServices shared];
	
	if (![currentRepository isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName]) {
		NSLog(@"Activities are not supported in this repository");
        [self noActivitiesForRepositoryError];
        [self stopHUD];
	} else {
        //We don't stop the HUD since loadActivities will start it again
        [self loadActivities];
    }
	
    
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)sender
{
	NSLog(@"ServiceDocument Request Failure \n\tErrorDescription: %@ \n\tErrorFailureReason:%@ \n\tErrorObject:%@", 
          [[sender error] description], [[sender error] localizedFailureReason],[sender error]);
    
    [self failedToFetchActivitiesError];
    [self stopHUD];
    
    // TODO Make sure the string bundles are updated for the different targets
    NSString *failureMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"),
                                [sender url]];
	
    UIAlertView *sdFailureAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"serviceDocumentRequestFailureTitle", @"Error")
															  message:failureMessage
															 delegate:nil 
													cancelButtonTitle:NSLocalizedString(@"Continue", nil)
													otherButtonTitles:nil] autorelease];
	[sdFailureAlert show];
    [sender cancel];
}


#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}
    
    [self setHUD:[MBProgressHUD showHUDAddedTo:self.tableView animated:YES]];
    [self.HUD setRemoveFromSuperViewOnHide:YES];
    [self.HUD setTaskInProgress:YES];
    [self.HUD setMode:MBProgressHUDModeIndeterminate];
}

- (void)stopHUD
{
	if (HUD) {
		[HUD setTaskInProgress:NO];
		[HUD hide:YES];
		[HUD removeFromSuperview];
		[self setHUD:nil];
	}
}

#pragma mark - NotificationCenter methods
- (void) detailViewControllerChanged:(NSNotification *) notification {
    id sender = [notification object];
    
    if(sender && ![sender isEqual:self]) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"detailViewControllerChanged" object:nil];
}

- (void) applicationWillResignActive:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in ActivitiesTableViewController");
    [activitiesRequest clearDelegatesAndCancel];
    [serviceDocumentRequest clearDelegatesAndCancel];
}

-(void) repositoryShouldReload:(NSNotification *)notification {
    [self serviceDocumentRequestFinished:nil];
}

@end
