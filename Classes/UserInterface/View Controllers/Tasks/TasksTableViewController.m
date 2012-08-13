//
//  TasksTableViewController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 10/08/2012.
//  Copyright (c) 2012 . All rights reserved.
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
#import "TaskDetailsViewController.h"

@interface TasksTableViewController(private)
- (void) loadTasks;
- (void) startHUD;
- (void) stopHUD;

- (void) noTasksForRepositoryError;
- (void) failedToFetchTasksError;

@end

@implementation TasksTableViewController

@synthesize HUD = _HUD;
@synthesize tasksRequest = _tasksRequest;
@synthesize selectedTask = _selectedTask;
@synthesize cellSelection;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;

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
    
    [super dealloc];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [_HUD setTaskInProgress:NO];
    [_HUD hide:YES];
    [_HUD release];
    _HUD = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) name:kNotificationAccountListUpdated object:nil];
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:NSLocalizedString(@"tasks.view.title", @"Tasks Table View Title")]; 
    
    if(IS_IPAD) {
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
    [[TaskManager sharedManager] startTasksRequest];
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
#pragma mark TaskManagerDelegate
- (void)taskManager:(TaskManager *)taskManager requestFinished:(NSArray *)tasks
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"properties.bpm_startDate" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    tasks = [tasks sortedArrayUsingDescriptors:sortDescriptors];
    [sortDescriptor release];
    
    NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:tasks, nil] 
                                                                        forKeys:[NSArray arrayWithObjects:@"tasks", nil]];
    
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
    [self updateAndReload];
    [self dataSourceFinishedLoadingWithSuccess:YES];
    [self stopHUD];
    self.tasksRequest = nil;
}

- (void)taskManagerRequestFailed:(TaskManager *)taskManager
{
    NSLog(@"Request in TasksTableViewController failed! %@", [taskManager.error description]);
    
    [self failedToFetchActivitiesError];
    [self dataSourceFinishedLoadingWithSuccess:NO];
    [self stopHUD];
    self.tasksRequest = nil;
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
        TaskItem *task = [[[TaskItem alloc] initWithJsonDictionary:taskDict] autorelease];
        
        TaskTableCellController *cellController = [[TaskTableCellController alloc] initWithTitle:task.title andSubtitle:task.description inModel:self.model];
        
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
            cell.textLabel.text = NSLocalizedString(@"activities.empty", @"No activities Available");
        } else {
            cell.textLabel.text = @" ";
        }
        
        cell.shouldResizeTextToFit = YES;
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

- (void) performTaskSelected:(id)sender withSelection:(NSString *)selection 
{
    TaskTableCellController *taskCell = (TaskTableCellController *)sender;
    TaskItem *task = taskCell.task;
    NSLog(@"User tapped row, selection type: %@", selection);
    
    self.cellSelection = selection;
    self.selectedTask = task;
    
    TaskDetailsViewController *detailsController = [[TaskDetailsViewController alloc] init];
    [IpadSupport pushDetailController:detailsController withNavigation:self.navigationController andSender:self];
    [detailsController showTask:task];
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
    NSLog(@"applicationWillResignActive in ActivitiesTableViewController");
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

#pragma mark -

@end
