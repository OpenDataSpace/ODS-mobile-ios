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
// WorkflowDetailsViewController 
//
#import "WorkflowDetailsViewController.h"
#import "DownloadProgressBar.h"
#import "DateIconView.h"
#import "MBProgressHUD.h"
#import "ObjectByIdRequest.h"
#import "WorkflowItem.h"
#import "MetaDataTableViewController.h"
#import "IpadSupport.h"
#import "DocumentViewController.h"
#import "TaskDocumentViewCell.h"
#import "DocumentItem.h"
#import "NodeThumbnailHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "AsyncLoadingUIImageView.h"
#import "UILabel+Utils.h"
#import "TaskManager.h"
#import "WorkflowTaskViewCell.h"
#import "AvatarHTTPRequest.h"

#define HEADER_MARGIN 20.0
#define DUEDATE_SIZE 60.0
#define CELL_HEIGHT_DOCUMENT_CELL 150.0
#define CELL_HEIGHT_TASK_CELL 120.0

#define TAG_TASK_TABLE 0
#define TAG_DOCUMENT_TABLE 1

@interface WorkflowDetailsViewController () <UITableViewDataSource, UITableViewDelegate, DownloadProgressBarDelegate, TaskManagerDelegate>

@property (nonatomic, retain) MBProgressHUD *generalHud;

// Header
@property (nonatomic, retain) UILabel *workflowNameLabel;
@property (nonatomic, retain) DateIconView *dueDateIconView;
@property (nonatomic, retain) UIImageView *headerSeparator;
@property (nonatomic, retain) UIImageView *priorityIcon;
@property (nonatomic, retain) UILabel *priorityLabel;
@property (nonatomic, retain) UILabel *workflowTypeLabel;
@property (nonatomic, retain) UIImageView *initiatorIcon;
@property (nonatomic, retain) UILabel *initiatorLabel;

// Tasks
@property (nonatomic, retain) UILabel *tasksLabel;
@property (nonatomic, retain) UITableView *taskTable;
@property BOOL isFetchingAttachments;

// Documents
@property (nonatomic, retain) UILabel *documentsLabel;
@property (nonatomic, retain) UITableView *documentTable;
@property (nonatomic, retain) MBProgressHUD *documentTableHUD;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;
@property (nonatomic, retain) ObjectByIdRequest *objectByIdRequest;
@property (nonatomic, retain) MetaDataTableViewController *metaDataViewController;

@end


@implementation WorkflowDetailsViewController

@synthesize workflowItem = _workflowItem;
@synthesize workflowNameLabel = _workflowNameLabel;
@synthesize dueDateIconView = _dueDateIconView;
@synthesize headerSeparator = _headerSeparator;
@synthesize priorityIcon = _priorityIcon;
@synthesize priorityLabel = _priorityLabel;
@synthesize initiatorIcon = _initiatorIcon;
@synthesize initiatorLabel = _initiatorLabel;
@synthesize taskTable = _taskTable;
@synthesize documentTable = _documentTable;
@synthesize generalHud = _generalHud;
@synthesize downloadProgressBar = _downloadProgressBar;
@synthesize objectByIdRequest = _objectByIdRequest;
@synthesize metaDataViewController = _metaDataViewController;
@synthesize workflowTypeLabel = _workflowTypeLabel;
@synthesize isFetchingAttachments = _isFetchingAttachments;
@synthesize documentTableHUD = _documentTableHUD;



#pragma mark View lifecycle

- (void)dealloc
{
    [_workflowNameLabel release];
    [_dueDateIconView release];
    [_headerSeparator release];
    [_priorityIcon release];
    [_priorityLabel release];
    [_initiatorIcon release];
    [_initiatorLabel release];
    [_taskTable release];
    [_documentTable release];
    [_generalHud release];
    [_downloadProgressBar release];
    [_objectByIdRequest release];
    [_metaDataViewController release];
    [_workflowItem release];
    [_workflowTypeLabel release];
    [_documentTableHUD release];
    [super dealloc];
}

- (id)initWithWorkflowItem:(WorkflowItem *)workflowItem
{
    self = [self init];
    if (self)
    {
        _workflowItem = [workflowItem retain];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    [self createDueDateView];
    [self createWorkflowNameLabel];
    [self createPriorityViews];
    [self createWorkflowTypeLabel];
    [self createInitiatorViews];
    [self createTaskTable];
    [self createDocumentTable];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Hide navigation bar if it still would be visible
    if (IS_IPAD)
    {
        [self.navigationController setNavigationBarHidden:YES];
    }

    // Calculate frames of all components
    [self calculateSubViewFrames];

    // Show the details
    [self displayWorkflowDetails];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // If the workflow attachments are not fetched, we need to fetch them first
    if (self.workflowItem.documents == nil && !self.isFetchingAttachments)
    {
        self.isFetchingAttachments = YES;
        self.documentTableHUD = createAndShowProgressHUDForView(self.documentTable);
        self.documentTableHUD.labelText = NSLocalizedString(@"workflow.fetching.documents", nil);

        // We're using the start task to fetch the attachments. It would also be possible using the workflow id
        // but then we would need to mess around with more code.
        [[TaskManager sharedManager] setDelegate:self];
        [[TaskManager sharedManager] startTaskItemRequestForTaskId:self.workflowItem.startTask.taskId
                        accountUUID:self.workflowItem.accountUUID tenantID:self.workflowItem.tenantId];
    }
}

#pragma mark TaskManagerDelegate

- (void)itemRequestFinished:(NSArray *)items
{
    NSMutableArray *documentItems = [NSMutableArray arrayWithCapacity:items.count];
    for (NSDictionary *taskItemDict in items)
    {
        DocumentItem *documentItem = [[DocumentItem alloc] initWithJsonDictionary:taskItemDict];
        [documentItems addObject:documentItem];
        [documentItem release];
    }
    self.workflowItem.documents = documentItems;

    // Remove Hud and reset state
    self.isFetchingAttachments = NO;
    stopProgressHUD(self.documentTableHUD);
    self.documentTableHUD = nil;

    // Reload document table
    [self.documentTable reloadData];
}



#pragma mark Creation of subviews

- (void)createWorkflowNameLabel
{
    UILabel *workflowNameLabel = [[UILabel alloc] init];
    workflowNameLabel.lineBreakMode = UILineBreakModeClip;
    workflowNameLabel.font = [UIFont systemFontOfSize:24];
    workflowNameLabel.numberOfLines = 1;
    self.workflowNameLabel = workflowNameLabel;
    [self.view addSubview:self.workflowNameLabel];
    [workflowNameLabel release];

    // Separator
    UIImageView *separator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"taskDetailsHorizonalLine.png"]];
    self.headerSeparator = separator;
    [separator release];
    [self.view addSubview:self.headerSeparator];
}

- (void)createDueDateView
{
    DateIconView *dateIconView = [[DateIconView alloc] init];
    self.dueDateIconView = dateIconView;
    [self.view addSubview:self.dueDateIconView];
    [dateIconView release];
}

- (void)createPriorityViews
{
    // Icon
    UIImageView *priorityIcon = [[UIImageView alloc] init];
    priorityIcon.image = [UIImage imageNamed:@"MedPriorityHeader.png"]; // Default, will be changed when task is set
    self.priorityIcon = priorityIcon;
    [self.view addSubview:priorityIcon];
    [priorityIcon release];

    // Label
    UILabel *priorityLabel = [[UILabel alloc] init];
    priorityLabel.font = [UIFont systemFontOfSize:13];
    self.priorityLabel = priorityLabel;
    [self.view addSubview:priorityLabel];
    [priorityLabel release];
}

-(void)createWorkflowTypeLabel
{
    UILabel *workflowTypeLabel = [[UILabel alloc] init];
    workflowTypeLabel.font = [UIFont systemFontOfSize:13];
    self.workflowTypeLabel = workflowTypeLabel;
    [self.view addSubview:workflowTypeLabel];
    [workflowTypeLabel release];
}

- (void)createInitiatorViews
{
    // Icon
    UIImageView *initiatorIcon= [[UIImageView alloc] init];
    initiatorIcon.image = [UIImage imageNamed:@"taskAssignee.png"];
    self.initiatorIcon = initiatorIcon;
    [self.view addSubview:self.initiatorIcon];
    [initiatorIcon release];

    // Label
    UILabel *initiatorLabel = [[UILabel alloc] init];
    initiatorLabel.font = [UIFont systemFontOfSize:13];
    self.initiatorLabel = initiatorLabel;
    [self.view addSubview:self.initiatorLabel];
    [initiatorLabel release];
}

- (void)createTaskTable
{
    // Title
    UILabel *tasksLabel = [[UILabel alloc] init];
    tasksLabel.text = NSLocalizedString(@"workflow.task.table.title", nil);
    self.tasksLabel = tasksLabel;
    [self.view addSubview:self.tasksLabel];
    [tasksLabel release];

    // Table
    UITableView *taskTableView = [[UITableView alloc] init];
    taskTableView.tag = TAG_TASK_TABLE;
    taskTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    taskTableView.delegate = self;
    taskTableView.dataSource = self;
    self.taskTable = taskTableView;
    [self.view addSubview:self.taskTable];
    [taskTableView release];
}

- (void)createDocumentTable
{
     // Title
    UILabel *documentsLabel = [[UILabel alloc] init];
    documentsLabel.text = NSLocalizedString(@"workflow.document.table.title", nil);
    self.documentsLabel = documentsLabel;
    [self.view addSubview:self.documentsLabel];

    // Table
    UITableView *documentTableView = [[UITableView alloc] init];
    documentTableView.tag = TAG_DOCUMENT_TABLE;
    documentTableView.delegate = self;
    documentTableView.dataSource = self;
    documentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.documentTable = documentTableView;
    [self.view addSubview:self.documentTable];
    [documentTableView release];
}

- (void)calculateSubViewFrames
{
    // Header
    CGRect dueDateFrame = CGRectMake(HEADER_MARGIN, HEADER_MARGIN, DUEDATE_SIZE, DUEDATE_SIZE);
    self.dueDateIconView.frame = dueDateFrame;

    CGFloat workflowNameX = dueDateFrame.origin.x + dueDateFrame.size.width + HEADER_MARGIN/2;
    CGRect taskNameFrame = CGRectMake(workflowNameX, dueDateFrame.origin.y, self.view.frame.size.width - workflowNameX - 20, 36);
    self.workflowNameLabel.frame = taskNameFrame;

    [self calculateSubHeaderFrames];

    // Separator
    self.headerSeparator.frame = CGRectMake((self.view.frame.size.width - self.headerSeparator.image.size.width) / 2, 100,
            self.headerSeparator.image.size.width, self.headerSeparator.image.size.height);

    // Task table
    CGRect tasksLabelFrame = CGRectMake(10, self.headerSeparator.frame.origin.y + self.headerSeparator.frame.size.height,
            self.view.frame.size.width - 10, 20);
    self.tasksLabel.frame = tasksLabelFrame;

    CGRect taskTableFrame = CGRectMake(0, tasksLabelFrame.origin.y + tasksLabelFrame.size.height,
            self.view.frame.size.width,
            (self.workflowItem.tasks.count <= 3) ? CELL_HEIGHT_TASK_CELL * self.workflowItem.tasks.count : 3 * CELL_HEIGHT_TASK_CELL + 10);
    self.taskTable.frame = taskTableFrame;

    // Document table
    CGRect documentsLabelFrame = CGRectMake(tasksLabelFrame.origin.x, taskTableFrame.origin.y + taskTableFrame.size.height,
            tasksLabelFrame.size.width, tasksLabelFrame.size.height);
    self.documentsLabel.frame = documentsLabelFrame;

    CGFloat documentTableY = documentsLabelFrame.origin.y + documentsLabelFrame.size.height;
    CGRect documentTableFrame = CGRectMake(0, documentTableY, self.view.frame.size.width, self.view.frame.size.height - documentTableY);
    self.documentTable.frame = documentTableFrame;
}

- (void)calculateSubHeaderFrames
{
    CGFloat subHeaderMargin = 25.0;

    CGRect priorityIconFrame = CGRectMake(self.workflowNameLabel.frame.origin.x,
            self.workflowNameLabel.frame.origin.y + self.workflowNameLabel.frame.size.height,
            self.priorityIcon.image.size.width, self.priorityIcon.image.size.height);
    self.priorityIcon.frame = priorityIconFrame;

    CGRect priorityLabelFrame = CGRectMake(priorityIconFrame.origin.x + priorityIconFrame.size.width + 4,
            priorityIconFrame.origin.y,
            [self.priorityLabel.text sizeWithFont:self.priorityLabel.font].width,
            priorityIconFrame.size.height);
    self.priorityLabel.frame = priorityLabelFrame;

    CGRect workflowTypeLabelFrame = CGRectMake(priorityLabelFrame.origin.x + priorityLabelFrame.size.width + subHeaderMargin,
            priorityLabelFrame.origin.y,
            [self.workflowTypeLabel.text sizeWithFont:self.workflowTypeLabel.font].width,
            priorityLabelFrame.size.height);
    self.workflowTypeLabel.frame = workflowTypeLabelFrame;

    CGRect initiatorFrame = CGRectMake(workflowTypeLabelFrame.origin.x + workflowTypeLabelFrame.size.width + subHeaderMargin,
            workflowTypeLabelFrame.origin.y, self.initiatorIcon.image.size.width, self.initiatorIcon.image.size.height);
    self.initiatorIcon.frame = initiatorFrame;

    CGRect initiatorLabelFrame = CGRectMake(initiatorFrame.origin.x + initiatorFrame.size.width + 4,
            initiatorFrame.origin.y,
            [self.initiatorLabel.text sizeWithFont:self.initiatorLabel.font].width,
            initiatorFrame.size.height);
    self.initiatorLabel.frame = initiatorLabelFrame;
}

- (void)displayWorkflowDetails
{
    // Task header
    self.workflowNameLabel.text = self.workflowItem.message;

    switch (self.workflowItem.workflowType)
    {
        case WORKFLOW_TYPE_TODO:
            self.workflowTypeLabel.text = NSLocalizedString(@"task.detail.workflow.todo", nil);
            break;
        case WORKFLOW_TYPE_REVIEW:
            self.workflowTypeLabel.text = NSLocalizedString(@"task.detail.workflow.review.and.approve", nil);
            break;
    }

    NSString *priority = nil;
    switch (self.workflowItem.priority)
    {
        case 1:
            priority = NSLocalizedString(@"workflow.priority.low", nil);
            break;
        case 3:
            priority = NSLocalizedString(@"workflow.priority.high", nil);
            break;
        default:
            priority = NSLocalizedString(@"workflow.priority.medium", nil);
    }
    self.priorityLabel.text = priority;
    self.initiatorLabel.text = self.workflowItem.initiatorFullName;

    // Due date
    if (self.workflowItem.dueDate)
    {
        self.dueDateIconView.date = self.workflowItem.dueDate;
    }

    // Size all labels according to text
    [self.workflowNameLabel appendDotsIfTextDoesNotFit];
    [self calculateSubHeaderFrames];
}

#pragma mark - UITableView delegate methods (document and task table)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView.tag == TAG_DOCUMENT_TABLE)
    {
        return self.workflowItem.documents.count;
    }
    else if (tableView.tag == TAG_TASK_TABLE)
    {
        return self.workflowItem.tasks.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == TAG_DOCUMENT_TABLE)
    {
        static NSString *CellIdentifier = @"Cell";
        TaskDocumentViewCell * cell = (TaskDocumentViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[TaskDocumentViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }

        DocumentItem *documentItem = [self.workflowItem.documents objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.nameLabel.text = documentItem.name;
        cell.nameLabel.font = [UIFont systemFontOfSize:16];
        cell.attachmentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"task.detail.attachment", nil), indexPath.row + 1, self.workflowItem.documents.count];

        cell.thumbnailImageView.image = nil; // Need to set it to nil. Otherwise if cell was cached, the old image is seen for a brief moment
        NodeThumbnailHTTPRequest *request = [NodeThumbnailHTTPRequest httpRequestNodeThumbnail:documentItem.nodeRef
                                                                                   accountUUID:self.workflowItem.accountUUID
                                                                                      tenantID:self.workflowItem.tenantId];

        cell.infoButton.tag = indexPath.row;
        [cell.infoButton addTarget:self action:@selector(showDocumentMetaData:) forControlEvents:UIControlEventTouchUpInside];

        request.secondsToCache = 3600;
        request.downloadCache = [ASIDownloadCache sharedCache];
        [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
        [cell.thumbnailImageView setImageWithRequest:request];

        return cell;
    }
    else
    {
        static NSString *CellIdentifier = @"Cell";
        WorkflowTaskViewCell *cell = (WorkflowTaskViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[WorkflowTaskViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }

        TaskItem *taskItem = [self.workflowItem.tasks objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.assigneeFullName.text = taskItem.ownerFullName;
        cell.taskTitleLabel.text = taskItem.description;
        cell.dueDateLabel.text = formatDateTimeFromDate(taskItem.dueDate);
        cell.commentTextView.text = taskItem.comment;

        AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
                httpRequestAvatarForUserName:taskItem.ownerUserName
                                 accountUUID:self.workflowItem.accountUUID
                                    tenantID:self.workflowItem.tenantId];
        avatarHTTPRequest.suppressAllErrors = YES;
        avatarHTTPRequest.secondsToCache = 86400; // a day
        avatarHTTPRequest.downloadCache = [ASIDownloadCache sharedCache];
        [avatarHTTPRequest setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
        [cell.assigneePicture setImageWithRequest:avatarHTTPRequest];

        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (tableView.tag == TAG_DOCUMENT_TABLE) ? CELL_HEIGHT_DOCUMENT_CELL : CELL_HEIGHT_TASK_CELL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == TAG_DOCUMENT_TABLE)
    {
        DocumentItem *documentItem = [self.workflowItem.documents objectAtIndex:indexPath.row];
        [self startObjectByIdRequest:documentItem.nodeRef];
    }
}

#pragma mark - MBProgressHUD Helper Methods
- (void)startHUD
{
	if (!self.generalHud)
    {
        self.generalHud = createAndShowProgressHUDForView(self.navigationController.view);
	}
}

- (void)stopHUD
{
	if (self.generalHud)
    {
        stopProgressHUD(self.generalHud);
		self.generalHud = nil;
	}
}

#pragma mark - Document metadata

- (void)showDocumentMetaData:(UIButton *)button
{
    DocumentItem *documentItem = [self.workflowItem.documents objectAtIndex:button.tag];
    self.objectByIdRequest = [ObjectByIdRequest defaultObjectById:documentItem.nodeRef
                                                      accountUUID:self.workflowItem.accountUUID
                                                         tenantID:self.workflowItem.tenantId];
    self.objectByIdRequest.suppressAllErrors = YES;
    [self.objectByIdRequest setCompletionBlock:^{

        [self stopHUD];

        MetaDataTableViewController *metaDataViewController =
                [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                        cmisObject:self.objectByIdRequest.repositoryItem
                                                       accountUUID:self.workflowItem.accountUUID
                                                          tenantID:self.workflowItem.tenantId];
        [metaDataViewController setCmisObjectId:self.objectByIdRequest.repositoryItem.guid];
        [metaDataViewController setMetadata:self.objectByIdRequest.repositoryItem.metadata];

        metaDataViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        metaDataViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [metaDataViewController.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                 target:self
                                                                                                 action:@selector(documentMetaDataCancelButtonTapped:)] autorelease]];
        self.metaDataViewController = metaDataViewController;
        [metaDataViewController release];

        [IpadSupport presentModalViewController:metaDataViewController withNavigation:nil];
    }];
    [self.objectByIdRequest setFailedBlock:^{
        [self stopHUD];
        NSLog(@"Could not fetch metadata for node %@", documentItem.nodeRef);
    }];

    self.objectByIdRequest.suppressAllErrors = YES;

    [self startHUD];
    [self.objectByIdRequest startAsynchronous];
}

- (void)documentMetaDataCancelButtonTapped:(id)sender
{
    [self.metaDataViewController dismissModalViewControllerAnimated:YES];
}


#pragma mark - Document download

- (void)startObjectByIdRequest:(NSString *)objectId
{
    self.objectByIdRequest = [ObjectByIdRequest defaultObjectById:objectId
                                                      accountUUID:self.workflowItem.accountUUID
                                                         tenantID:self.workflowItem.tenantId];
    [self.objectByIdRequest setDidFinishSelector:@selector(startDownloadRequest:)];
    [self.objectByIdRequest setDidFailSelector:@selector(objectByIdRequestFailed:)];
    [self.objectByIdRequest setDelegate:self];
    self.objectByIdRequest.suppressAllErrors = YES;

    [self startHUD];
    [self.objectByIdRequest startAsynchronous];
}

- (void)objectByIdRequestFailed: (ASIHTTPRequest *)request
{
    self.objectByIdRequest = nil;
}

- (void)startDownloadRequest:(ObjectByIdRequest *)request
{
    RepositoryItem *repositoryNode = request.repositoryItem;

    if(repositoryNode.contentLocation && request.responseStatusCode < 400)
    {
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

    if(request.responseStatusCode >= 400)
    {
        [self objectByIdNotFoundDialog];
    }

    [self stopHUD];
    self.objectByIdRequest = nil;
}

- (void)objectByIdNotFoundDialog
{
    UIAlertView *objectByIdNotFound = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"activities.document.notfound.title", @"Document not found")
                                                                  message:NSLocalizedString(@"activities.document.notfound.message", @"The document could not be found")
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                                        otherButtonTitles:nil] autorelease];
	[objectByIdNotFound show];
}

#pragma mark - DownloadProgressBar Delegate

- (void)download:(DownloadProgressBar *)downloadProgressBar completeWithPath:(NSString *)filePath
{
	DocumentViewController *documentViewController = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
	[documentViewController setCmisObjectId:downloadProgressBar.cmisObjectId];
    [documentViewController setContentMimeType:[downloadProgressBar cmisContentStreamMimeType]];
    [documentViewController setHidesBottomBarWhenPushed:YES];
    [documentViewController setSelectedAccountUUID:[downloadProgressBar selectedAccountUUID]];
    [documentViewController setTenantID:downloadProgressBar.tenantID];
    [documentViewController setShowReviewButton:NO];

    DownloadMetadata *fileMetadata = downloadProgressBar.downloadMetadata;
    NSString *filename;

    if(fileMetadata.key) {
        filename = fileMetadata.key;
    } else {
        filename = downloadProgressBar.filename;
    }

    [documentViewController setFileName:filename];
    [documentViewController setFilePath:filePath];
    [documentViewController setFileMetadata:fileMetadata];

	[IpadSupport addFullScreenDetailController:documentViewController withNavigation:self.navigationController
                                     andSender:self backButtonTitle:NSLocalizedString(@"Close", nil)];
	[documentViewController release];
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down {
	[self.documentTable deselectRowAtIndexPath:[self.documentTable indexPathForSelectedRow] animated:YES];
}


#pragma mark - Device rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self calculateSubViewFrames];
}

@end
