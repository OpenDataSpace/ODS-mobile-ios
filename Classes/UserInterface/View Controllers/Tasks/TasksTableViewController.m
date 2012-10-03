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
//  TasksTableViewController.m
//

#import "TasksTableViewController.h"
#import "TableCellViewController.h"
#import "IFTextViewTableView.h"
#import "IFTemporaryModel.h"
#import "IFValueCellController.h"
#import "Theme.h"
#import "ThemeProperties.h"
#import "Utility.h"
#import "IpadSupport.h"
#import "TableViewHeaderView.h"
#import "TaskTableCellController.h"
#import "AccountManager.h"
#import "TaskItem.h"
#import "DocumentItem.h"
#import "TaskDetailsViewController.h"
#import "SelectTaskTypeViewController.h"
#import "MyTaskListHTTPRequest.h"
#import "SelectAccountViewController.h"
#import "SelectTenantViewController.h"
#import "RepositoryServices.h"
#import "RepositoryInfo.h"
#import "ReadUnreadManager.h"
#import "WorkflowDetailsHTTPRequest.h"
#import "WorkflowDetailsViewController.h"
#import "ServiceDocumentRequest.h"
#import "AddTaskDelegate.h"
#import "TaskTableViewCell.h"

static NSString *FilterMyTasks = @"filter_mytasks";
static NSString *FilterTasksStartedByMe = @"filter_startedbymetasks";

@interface TasksTableViewController() <UIActionSheetDelegate, CMISServiceManagerListener, AddTaskDelegate>

@property (nonatomic, retain) MBProgressHUD *HUD;

- (void) failedToFetchTasksError;

@property NSInteger selectedRow;
@property (nonatomic, retain) NSString *currentTaskFilter;
@property (nonatomic, retain) UIPopoverController *filterPopoverController;
@property (nonatomic, retain) UIActionSheet *filterActionSheet;

@end

@implementation TasksTableViewController

@synthesize HUD = _HUD;
@synthesize tasksRequest = _tasksRequest;
@synthesize cellSelection;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;
@synthesize selectedRow = _selectedRow;
@synthesize currentTaskFilter = _currentTaskFilter;
@synthesize filterPopoverController = _filterPopoverController;
@synthesize filterActionSheet = _filterActionSheet;

#pragma mark - View lifecycle
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_tasksRequest clearDelegatesAndCancel];
    
    [_HUD release];
    [_tasksRequest release];
    [cellSelection release];
    [_refreshHeaderView release];
    [_lastUpdated release];
    [_currentTaskFilter release];
    [_filterPopoverController release];
    [_filterActionSheet release];
    
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_HUD setTaskInProgress:NO];
    [_HUD hide:YES];
    [_HUD release];
    _HUD = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) name:kNotificationAccountListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTaskCompletion:) name:kNotificationTaskCompleted object:nil];
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:NSLocalizedString(@"tasks.view.mytasks.title", nil)];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Alfresco_iOS_Filter.png"] style:UIBarButtonItemStyleBordered 
                                                                                                 target:self action:@selector(filterTasksAction:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                              target:self action:@selector(addTaskAction:)] autorelease];
    
    if(IS_IPAD)
    {
        self.clearsSelectionOnViewWillAppear = NO;
    }
    
	// Pull to Refresh
    self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, 
                                                                                          self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                arrowImageName:@"pull-to-refresh.png"
                                                                     textColor:[ThemeProperties pullToRefreshTextColor]] autorelease];
    [self.refreshHeaderView setDelegate:self];
    [self setLastUpdated:[NSDate date]];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];
    self.currentTaskFilter = FilterMyTasks;
    [self loadTasks];
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

- (void)loadTasks 
{
    [self startHUD];
    
    [[TaskManager sharedManager] setDelegate:self];
    if ([self.currentTaskFilter isEqualToString:FilterMyTasks])
    {
        [[TaskManager sharedManager] startMyTasksRequest];
    }
    else 
    {
        [[TaskManager sharedManager] startInitiatorTasksRequest];
    }
    // initialzing for performance when showing table
    [ReadUnreadManager sharedManager];
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

- (void)filterTasksAction:(id)sender 
{
    if (!self.filterActionSheet)
    {
        UIActionSheet *filterActionSheet = [[UIActionSheet alloc] initWithTitle:@"Task filter" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                                                       otherButtonTitles:NSLocalizedString(@"tasks.view.mytasks.title", nil), 
                                                            NSLocalizedString(@"tasks.view.startedbymetasks.title", nil), nil];
        if(IS_IPAD) {
            [filterActionSheet setActionSheetStyle:UIActionSheetStyleDefault];
            [filterActionSheet showFromBarButtonItem:sender animated:YES];
        } else {
            [filterActionSheet showFromTabBar:[[self tabBarController] tabBar]];
        }
        
        self.filterActionSheet = filterActionSheet;
        
        [filterActionSheet release];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) 
    {
        case 0:
            if ([self.currentTaskFilter isEqualToString:FilterMyTasks] == NO)
            {
                self.currentTaskFilter = FilterMyTasks;
                [self loadTasks];
            }
            break;
        case 1:
            if ([self.currentTaskFilter isEqualToString:FilterTasksStartedByMe] == NO)
            {
                self.currentTaskFilter = FilterTasksStartedByMe;
                [self loadTasks];
            }
            break;
    }
    
    self.filterActionSheet = nil;
}

- (void)addTaskAction:(id)sender 
{
    // Check if there is repository information for each of the active account
    // This is at the time of writing a bug, hence why we fetched the repo info if needed here
    // Note that this is a very rare case (ie fiddling with accounts in between task list refreshes),
    // so normally this won't have much impact on end-users (ie they will see the HUD very excpetionally)
    BOOL allAccountsLoaded = [self verifyAllAccountsLoaded];

    if (allAccountsLoaded)
    {
        [self showAddTaskViewController];
    }
    else
    {
        [self startHUD:NSLocalizedString(@"task.create.loading.accounts", nil)];
        [[CMISServiceManager sharedManager] addQueueListener:self];
        [[CMISServiceManager sharedManager] loadAllServiceDocuments];
    }
}

- (BOOL)verifyAllAccountsLoaded
{
    // Check if we have repository info for each of the active accounts
    BOOL allAccountsLoaded = YES;
    uint index = 0;
    NSArray *activeAccounts = [[AccountManager sharedManager] activeAccounts];
    while (allAccountsLoaded && index < activeAccounts.count)
    {
        AccountInfo *accountInfo = [activeAccounts objectAtIndex:index];
        if ([[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:accountInfo.uuid] == nil)
        {
            NSLog(@"AccountManager not in sync with RepositoryServices: %@ not found", accountInfo.description);
            allAccountsLoaded = NO;
        }
        index++;
    }
    return allAccountsLoaded;
}

- (void)showAddTaskViewController
{
    if ([[AccountManager sharedManager] activeAccounts].count == 0)
    {
        return;
    }

    UIViewController *newViewController;
    if ([[AccountManager sharedManager] activeAccounts].count > 1)
    {
        SelectAccountViewController *accountViewController = [[SelectAccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
        accountViewController.addTaskDelegate = self;
        newViewController = accountViewController;
    }
    else
    {
        AccountInfo *account = [[[AccountManager sharedManager] activeAccounts] objectAtIndex:0];
        if (account.isMultitenant)
        {
            RepositoryServices *repoService = [RepositoryServices shared];
            NSArray *repositories = [repoService getRepositoryInfoArrayForAccountUUID:account.uuid];

            if (repositories.count > 1)
            {
                SelectTenantViewController *tenantController = [[SelectTenantViewController alloc] initWithStyle:UITableViewStyleGrouped account:account.uuid];
                tenantController.addTaskDelegate = self;
                newViewController = tenantController;
            }
            else
            {
                SelectTaskTypeViewController *taskTypeViewController = [[SelectTaskTypeViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                                   account:account.uuid
                                                                                                                  tenantID:[[repositories objectAtIndex:0] tenantID]];
                taskTypeViewController.addTaskDelegate = self;
                newViewController = taskTypeViewController;
            }
        }
        else
        {
            SelectTaskTypeViewController *taskTypeViewController = [[SelectTaskTypeViewController alloc] initWithStyle:UITableViewStyleGrouped
                                                                                                               account:account.uuid tenantID:nil];
            taskTypeViewController.addTaskDelegate = self;
            newViewController = taskTypeViewController;
        }

    }

    newViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    newViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [IpadSupport presentModalViewController:newViewController withNavigation:nil];

    [newViewController release];
}

#pragma mark CmisServiceManager listener

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];

    [self stopHUD];
    [self showAddTaskViewController]; // We're now sure all the repository information is fetched
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)serviceRequest
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [self stopHUD];
}

#pragma mark Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

// Hackaround: when device is rotated, the table view seems to forget the current selection
// This workaround simply selects the current selection again after rotation happened.
// Don't worry, this will not trigger any new requests for data.
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
}


#pragma mark - TaskManagerDelegate
- (void)taskManager:(TaskManager *)taskManager requestFinished:(NSArray *)tasks
{
    NSSortDescriptor *sortDescriptor;
    if ([self.currentTaskFilter isEqualToString:FilterMyTasks])
    {
        [self.navigationItem setTitle:NSLocalizedString(@"tasks.view.mytasks.title", nil)];
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"properties.bpm_dueDate" ascending:YES];
    }
    else 
    {
        [self.navigationItem setTitle:NSLocalizedString(@"tasks.view.startedbymetasks.title", nil)];
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dueDate" ascending:YES];
    }
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    tasks = [tasks sortedArrayUsingDescriptors:sortDescriptors];
    NSMutableArray *newTaskArray = [NSMutableArray arrayWithArray:tasks];
    [sortDescriptor release];
    
    NSMutableArray *finalTaskArray = [NSMutableArray arrayWithCapacity:tasks.count];
    
    for (int i = 0; i < newTaskArray.count; i++) {
        NSDictionary *taskDict = [newTaskArray objectAtIndex:i];
        if (([self.currentTaskFilter isEqualToString:FilterMyTasks]
             && [[taskDict valueForKeyPath:@"properties.bpm_dueDate"] class] != [NSNull class]) ||
            
            ([self.currentTaskFilter isEqualToString:FilterTasksStartedByMe]
             && [[taskDict valueForKeyPath:@"dueDate"] class] != [NSNull class]))
        {
            [finalTaskArray addObject:taskDict];
        }
    }
    
    for (int i = 0; i < newTaskArray.count; i++) {
        NSDictionary *taskDict = [newTaskArray objectAtIndex:i];
        if (([self.currentTaskFilter isEqualToString:FilterMyTasks]
            && [[taskDict valueForKeyPath:@"properties.bpm_dueDate"] class] == [NSNull class]) ||
            
            ([self.currentTaskFilter isEqualToString:FilterTasksStartedByMe]
             && [[taskDict valueForKeyPath:@"dueDate"] class] == [NSNull class]))
        {
            [finalTaskArray addObject:taskDict];
        }
    }

    NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObject:finalTaskArray forKey:@"tasks"];
    
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
    [self updateAndReload];
    [self dataSourceFinishedLoadingWithSuccess:YES];
    [self stopHUD];
    self.tasksRequest = nil;
}

- (void)itemRequestFinished:(NSArray *)taskItems
{
    NSMutableArray *itemArray = [NSMutableArray arrayWithCapacity:taskItems.count];
    for (NSDictionary *taskItemDict in taskItems) {
        DocumentItem *documentItem = [[DocumentItem alloc] initWithJsonDictionary:taskItemDict];
        [itemArray addObject:documentItem];
        [documentItem release];
    }
    
    TaskTableCellController *taskController = (TaskTableCellController *) [self cellControllerForIndexPath:[self.tableView indexPathForSelectedRow]];
    TaskItem *task = taskController.task;
    task.documentItems = [NSArray arrayWithArray:itemArray];
    
    [[ReadUnreadManager sharedManager] saveReadStatus:YES taskId:task.taskId];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.selectedRow inSection:0]] 
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.selectedRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];

    TaskDetailsViewController *detailsController = [[TaskDetailsViewController alloc] initWithTaskItem:task];
    [IpadSupport pushDetailController:detailsController withNavigation:self.navigationController andSender:self];
    [detailsController release];
    [self stopHUD];
}

- (void)taskManagerRequestFailed:(TaskManager *)taskManager
{
    NSLog(@"Request in TasksTableViewController failed! %@", [taskManager.error description]);
    
    [self failedToFetchTasksError];
    [self dataSourceFinishedLoadingWithSuccess:NO];
    [self stopHUD];
    self.tasksRequest = nil;
}

#pragma mark - AddTaskDelegate

- (void)taskAddedForLoggedInUser
{
    [self loadTasks];
}

#pragma mark - UITableViewDelegate

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

// Overriding this method, as the regular implementation doesn't take in account changes in the model
// (it onl checks the number of elements in the table group)
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *tasks = [self.model objectForKey:@"tasks"];
    if (tasks.count > 0)
    {
        return tasks.count;
    }
    else 
    {
        return 1;
    }
}


#pragma mark - Generic Table View Construction
- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]] && ![self.tasksRequest isExecuting]) {
        return;
	}
    
    NSMutableArray *headers = [NSMutableArray array];
    NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];
    
    NSMutableArray *mainGroup = [NSMutableArray array];
    [headers addObject:@""];
    [groups addObject:mainGroup];
    [footers addObject:@""];
    
    NSArray *tasks = [self.model objectForKey:@"tasks"];
    
    for (NSDictionary *taskDict in tasks) 
    {
        TaskItem *task;
        if ([self.currentTaskFilter isEqualToString:FilterMyTasks])
        {
            task = [[[TaskItem alloc] initWithMyTaskJsonDictionary:taskDict] autorelease];
        }
        else
        {
            task = [[[TaskItem alloc] initWithStartedByMeTaskJsonDictionary:taskDict] autorelease];
        }
        
        TaskTableCellController *cellController;
        if (task.taskItemType == TASKITEM_TYPE_STARTEDBYME)
        {
            cellController = [[TaskTableCellController alloc] initWithTitle:task.title andSubtitle:task.message inModel:self.model];
        }
        else 
        {
            cellController = [[TaskTableCellController alloc] initWithTitle:task.title andSubtitle:task.description inModel:self.model];
        }
        
        [cellController setTask:task];
        [cellController setSubtitleTextColor:[UIColor grayColor]];
        [cellController setSelectionTarget:self];
        [cellController setSelectionAction:@selector(performTaskSelected:withSelection:)];

        cellController.selectionStyle = UITableViewCellSelectionStyleBlue;
        cellController.accesoryType = UITableViewCellAccessoryNone; 
        
        [mainGroup addObject:cellController];
        [cellController release];
        [self.tableView setAllowsSelection:YES];
    }
    
    //model is not loaded yet.
    if([tasks count] == 0) {
        TableCellViewController *cell;
        NSString *error = [self.model objectForKey:@"error"];
        
        cell = [[TableCellViewController alloc] initWithAction:nil onTarget:nil];
        
        if(error) {
            cell.textLabel.text = error;
        } else if(self.tasksRequest == nil) {
            cell.textLabel.text = NSLocalizedString(@"tasks.empty", @"No tasks available");
        } else {
            cell.textLabel.text = @" ";
        }
        
        cell.shouldResizeTextToFit = YES;
        [mainGroup addObject:cell];
        [cell release];
        
        [self.tableView setAllowsSelection:NO];
    }
    
    if ([mainGroup count] != 0) {
        [tableGroups release];
        [tableHeaders release];
        [tableFooters release];
        tableHeaders = [headers retain];
        tableGroups = [groups retain];
        tableFooters = [footers retain];
    }
    
    [self setEditing:NO animated:YES];
    
	[self assignFirstResponderHostToCellControllers];
}

- (void) failedToFetchTasksError {
    NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:NSLocalizedString(@"tasks.unavailable", @"No tasks available"), nil] forKeys:[NSArray arrayWithObjects:@"error", nil]];
    
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
    [self updateAndReload];
}

- (void) performTaskSelected:(id)sender withSelection:(NSString *)selection 
{
    TaskTableCellController *taskCell = (TaskTableCellController *) sender;
    TaskItem *task = taskCell.task;

    self.cellSelection = selection;
    self.selectedRow = taskCell.indexPathInTable.row;

    [self startHUD];

    if ([self.currentTaskFilter isEqualToString:FilterMyTasks])
    {
        [[TaskManager sharedManager] setDelegate:self];
        [[TaskManager sharedManager] startTaskItemRequestForTaskId:task.taskId accountUUID:task.accountUUID tenantID:task.tenantId];
    }
    else if ([self.currentTaskFilter isEqualToString:FilterTasksStartedByMe])
    {
        WorkflowDetailsHTTPRequest *request = [WorkflowDetailsHTTPRequest workflowDetailsRequestForWorkflow:task.taskId 
                                                                                                accountUUID:task.accountUUID tenantID:task.tenantId];
        [request setCompletionBlock:^{
            [self stopHUD];

            WorkflowDetailsViewController *detailsController = [[WorkflowDetailsViewController alloc] initWithWorkflowItem:request.workflowItem];
            [IpadSupport pushDetailController:detailsController withNavigation:self.navigationController andSender:self];
            [detailsController release];


        }];
        [request setFailedBlock:^{
            NSLog(@"Request in TasksTableViewController failed! %@", [request.error description]);
            [self stopHUD];
        }];
        [request startAsynchronous];
    }

}

#pragma mark - MBProgressHUD Helper Methods

- (void)startHUD
{
    [self startHUD:nil];
}

- (void)startHUD:(NSString *)text
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.navigationController.view);
        if (text)
        {
            self.HUD.labelText = text;
        }
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
    NSLog(@"applicationWillResignActive in TasksTableViewController");
    [self.tasksRequest clearDelegatesAndCancel];
}

- (void)handleAccountListUpdated:(NSNotification *) notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    [[self navigationController] popToRootViewControllerAnimated:NO];
    [self loadTasks];
}

- (void)handleTaskCompletion:(NSNotification *)notification
{
    NSString *taskId = [notification.userInfo objectForKey:@"taskId"];
    
    TaskTableCellController *taskController = (TaskTableCellController *) [self cellControllerForIndexPath:[self.tableView indexPathForSelectedRow]];
    TaskItem *task = taskController.task;
    
    if ([task.taskId isEqualToString:taskId])
    {
        // The current selected task is completed. We'll remove it from the table
        // Due to the faboulus IF* framework, this is a serious pain in the ass
        [IpadSupport clearDetailController];
        NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;

        NSMutableArray *tasks = [self.model objectForKey:@"tasks"];
        if (tasks.count > 0)
        {
            [tasks removeObjectAtIndex:selectedIndexPath.row]; // Delete from model
            
            if (tasks.count > 0)
            {
                // And select the next task
                NSInteger newIndex = (selectedIndexPath.row == [self tableView:self.tableView numberOfRowsInSection:0])
                        ? selectedIndexPath.row - 1 : selectedIndexPath.row;
                NSIndexPath *newSelectedIndexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];

                [self tableView:self.tableView didSelectRowAtIndexPath:newSelectedIndexPath];
                [self updateAndReload];
                [self.tableView selectRowAtIndexPath:newSelectedIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
            else 
            {
                [self updateAndReload];
            }
        }
        else
        {
            [self updateAndReload];
        }
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // Prevent trying to load tasks when no accounts are active
    // in those cases the TaskManager calls the delegate immediately and the
    // Push to refresh animation does not get cleared because the animation is in progress
    NSArray *activeAccounts = [[AccountManager sharedManager] activeAccounts];
    if([activeAccounts count] > 0)
    {
        [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    if (![self.tasksRequest isExecuting])
    {
        [self loadTasks];
    }
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return (self.HUD != nil);
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [self lastUpdated];
}

@end
