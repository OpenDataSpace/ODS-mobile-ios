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
#import "ObjectByIdRequest.h"
#import "WorkflowItem.h"
#import "MetaDataTableViewController.h"
#import "DocumentViewController.h"
#import "DocumentItem.h"
#import "ASIDownloadCache.h"
#import "AsyncLoadingUIImageView.h"
#import "UILabel+Utils.h"
#import "TaskManager.h"
#import "WorkflowTaskViewCell.h"
#import "AvatarHTTPRequest.h"
#import "DocumentTableDelegate.h"
#import "TTTAttributedLabel.h"

#define HEADER_MARGIN 20.0
#define DUEDATE_SIZE 60.0
#define CELL_HEIGHT_TASK_CELL 100.0

#define TAG_TASK_TABLE 0
#define TAG_DOCUMENT_TABLE 1

@interface WorkflowDetailsViewController () <UITableViewDataSource, UITableViewDelegate, TaskManagerDelegate>

// Header
@property (nonatomic, retain) UILabel *workflowNameLabel;
@property (nonatomic, retain) DateIconView *dueDateIconView;
@property (nonatomic, retain) UIImageView *headerSeparator;
@property (nonatomic, retain) UIImageView *priorityIcon;
@property (nonatomic, retain) UILabel *priorityLabel;
@property (nonatomic, retain) UILabel *workflowTypeLabel;
@property (nonatomic, retain) UIImageView *initiatorIcon;
@property (nonatomic, retain) UILabel *initiatorLabel;

// Table switch buttons
@property (nonatomic, retain) UIButton *showTasksButton;
@property (nonatomic, retain) UIImageView *buttonDivider;
@property (nonatomic, retain) UIButton *showDocumentsButton;
@property (nonatomic) NSInteger currentTableTag;

// Tasks
@property (nonatomic, retain) UITableView *taskTable;
@property BOOL isFetchingAttachments;

// Documents
@property (nonatomic, retain) UITableView *documentTable;
@property (nonatomic, retain) UILabel *documentsLoadingLabel;
@property (nonatomic, retain) DocumentTableDelegate *documentTableDelegate;

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
@synthesize workflowTypeLabel = _workflowTypeLabel;
@synthesize isFetchingAttachments = _isFetchingAttachments;
@synthesize documentsLoadingLabel = _documentsLoadingLabel;
@synthesize showTasksButton = _showTasksButton;
@synthesize showDocumentsButton = _showDocumentsButton;
@synthesize buttonDivider = _buttonDivider;
@synthesize documentTableDelegate = _documentTableDelegate;

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
    [_workflowItem release];
    [_workflowTypeLabel release];
    [_documentsLoadingLabel release];
    [_showTasksButton release];
    [_showDocumentsButton release];
    [_buttonDivider release];
    [_documentTableDelegate release];
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

    // Hide navigation bar if it still would be visible
    if (IS_IPAD)
    {
        [self.navigationController setNavigationBarHidden:YES];
    }

    [self createDueDateView];
    [self createWorkflowNameLabel];
    [self createPriorityViews];
    [self createWorkflowTypeLabel];
    [self createInitiatorViews];
    [self createTableSwitchButtons];
    [self createTaskTable];
    [self createDocumentTable];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

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

    self.isFetchingAttachments = NO;
    self.documentsLoadingLabel.hidden = YES;

    // Update document title count
    [self.showDocumentsButton setTitle:[NSString stringWithFormat:@"%@ (%d)",
          NSLocalizedString(@"workflow.document.table.title", nil), self.workflowItem.documents.count] forState:UIControlStateNormal];

    // Reload document table
    self.documentTableDelegate.documents = self.workflowItem.documents;
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

- (void)createTableSwitchButtons
{
    // Show tasks button
    UIButton *taskButton = [[UIButton alloc] init];
    taskButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    taskButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [taskButton setTitle:NSLocalizedString(@"workflow.task.table.title", nil) forState:UIControlStateNormal];
    [taskButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [taskButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [taskButton addTarget:self action:@selector(switchTables:) forControlEvents:UIControlEventTouchUpInside];
    taskButton.selected = YES;
    self.showTasksButton = taskButton;
    [taskButton release];
    [self.view addSubview:self.showTasksButton];

    // Button divider
    UIImageView *buttonDivider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"buttonDivide.png"]];
    self.buttonDivider = buttonDivider;
    [buttonDivider release];
    [self.view addSubview:self.buttonDivider];

    // Show documents button
    UIButton *documentButton = [[UIButton alloc] init];
    documentButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    documentButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [documentButton setTitle:NSLocalizedString(@"workflow.document.table.title", nil) forState:UIControlStateNormal];
    [documentButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [documentButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [documentButton addTarget:self action:@selector(switchTables:) forControlEvents:UIControlEventTouchUpInside];
    self.showDocumentsButton = documentButton;
    [documentButton release];
    [self.view addSubview:self.showDocumentsButton];
}

- (void)createTaskTable
{
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
    // Table
    UITableView *documentTableView = [[UITableView alloc] init];
    documentTableView.tag = TAG_DOCUMENT_TABLE;

    DocumentTableDelegate *tableDelegate = [[DocumentTableDelegate alloc] init];
    tableDelegate.tableView = documentTableView;
    tableDelegate.navigationController = self.navigationController;
    tableDelegate.viewBlockedByLoadingHud = self.navigationController.view;
    tableDelegate.accountUUID = self.workflowItem.accountUUID;
    tableDelegate.tenantID = self.workflowItem.tenantId;
    self.documentTableDelegate = tableDelegate;
    [tableDelegate release];

    documentTableView.delegate = self.documentTableDelegate;
    documentTableView.dataSource = self.documentTableDelegate;

    documentTableView.hidden = YES;
    documentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.documentTable = documentTableView;
    [self.view addSubview:self.documentTable];
    [documentTableView release];

    // Loading label
    UILabel *documentsLoadingLabel = [[UILabel alloc] init];
    documentsLoadingLabel.text = NSLocalizedString(@"workflow.documents.loading", nil);
    documentsLoadingLabel.textColor = [UIColor lightGrayColor];
    documentsLoadingLabel.font = [UIFont systemFontOfSize:14];
    documentsLoadingLabel.backgroundColor = [UIColor clearColor];
    documentsLoadingLabel.textAlignment = UITextAlignmentCenter;
    self.documentsLoadingLabel = documentsLoadingLabel;
    [self.view addSubview:self.documentsLoadingLabel];
    [documentsLoadingLabel release];

    self.documentTable.hidden = YES; // Will become visible when docs are loaded
    self.documentsLoadingLabel.hidden = YES;
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
    self.headerSeparator.frame = CGRectMake((self.view.frame.size.width - self.headerSeparator.image.size.width) / 2, 90,
            self.headerSeparator.image.size.width, self.headerSeparator.image.size.height);

    // Table buttons
    CGRect dividerFrame = CGRectMake((self.view.frame.size.width - self.buttonDivider.image.size.width) / 2,
            self.headerSeparator.frame.origin.y + self.headerSeparator.frame.size.height + 10,
            self.buttonDivider.image.size.width, self.buttonDivider.image.size.height);
    self.buttonDivider.frame = dividerFrame;

    CGRect showTaskButtonFrame = CGRectMake(0, dividerFrame.origin.y, dividerFrame.origin.x - 10, dividerFrame.size.height);
    self.showTasksButton.frame = showTaskButtonFrame;

    CGRect showDocumentsButtonFrame = CGRectMake(dividerFrame.origin.x + dividerFrame.size.width + 10, dividerFrame.origin.y,
            self.view.frame.size.width - (dividerFrame.origin.x + dividerFrame.size.width), dividerFrame.size.height);
    self.showDocumentsButton.frame = showDocumentsButtonFrame;

    // Task table
    CGFloat taskTableY = dividerFrame.origin.y + dividerFrame.size.height + 5;
    CGRect taskTableFrame = CGRectMake(0, taskTableY, self.view.frame.size.width, self.view.frame.size.height - taskTableY);
    self.taskTable.frame = taskTableFrame;

    // Document table
    self.documentTable.frame = taskTableFrame;

    // Documents loading label
    self.documentsLoadingLabel.frame = taskTableFrame;
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

    // Workflow type
    switch (self.workflowItem.workflowType)
    {
        case WORKFLOW_TYPE_TODO:
            self.workflowTypeLabel.text = NSLocalizedString(@"task.detail.workflow.todo", nil);
            break;
        case WORKFLOW_TYPE_REVIEW:
            self.workflowTypeLabel.text = NSLocalizedString(@"task.detail.workflow.review.and.approve", nil);
            break;
    }

    // Priority
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

    // Table titles with counter
    [self.showTasksButton setTitle:[NSString stringWithFormat:@"%@ (%d)",
          NSLocalizedString(@"workflow.task.table.title", nil), self.workflowItem.tasks.count] forState:UIControlStateNormal];

    // Size all labels according to text
    [self.workflowNameLabel appendDotsIfTextDoesNotFit];
    [self calculateSubHeaderFrames];
}

#pragma mark Instance methods

- (void)switchTables:(UIButton *)sender
{
    // Reset all states
    self.showTasksButton.selected = NO;
    self.showDocumentsButton.selected = NO;

    self.documentTable.hidden = YES;
    self.taskTable.hidden = YES;
    self.documentsLoadingLabel.hidden = YES;

    // Change state depending on clicked button
    if (sender == self.showTasksButton)
    {
        self.showTasksButton.selected = YES;
        self.taskTable.hidden = NO;
    }
    else if (sender == self.showDocumentsButton)
    {
        self.showDocumentsButton.selected = YES;
        self.documentTable.hidden = NO;

        if (self.workflowItem.documents == nil)
        {
            self.documentsLoadingLabel.hidden = NO;
        }
    }
}

#pragma mark - UITableView delegate methods (document and task table)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.workflowItem.tasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    WorkflowTaskViewCell *cell = (WorkflowTaskViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[WorkflowTaskViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    TaskItem *taskItem = [self.workflowItem.tasks objectAtIndex:indexPath.row];

    // Cell text. Some serious string juggling coming up now!
    NSString *actionText = nil;
    if (taskItem.taskType == TASK_TYPE_REVIEW && taskItem.completionDate != nil)
    {
        if ([taskItem.outcome isEqualToString:@"Approve"])
        {
            actionText = NSLocalizedString(@"workflow.task.user.approved", nil);
        }
        else
        {
            actionText = NSLocalizedString(@"workflow.task.user.rejected", nil);
        }
    }
    else if (taskItem.completionDate != nil)
    {
        actionText = [NSString stringWithFormat:NSLocalizedString(@"workflow.task.user.completed.task", nil), relativeDateFromDate(taskItem.completionDate)];
    }
    else
    {
        actionText = NSLocalizedString(@"workflow.task.user.not.completed.task", nil);
    }

    NSString *commentText = @"";
    if (taskItem.completionDate != nil)
    {
        commentText = [NSString stringWithFormat:@"%@ %@",
             (taskItem.comment) ? NSLocalizedString(@"workflow.task.user.commented", nil) : NSLocalizedString(@"workflow.task.user.no.comment", nil),
             (taskItem.comment) ? [NSString stringWithFormat:@"\"%@\"", taskItem.comment] : @""];
    }

    NSString *text = [NSString stringWithFormat:@"%@ %@%@", taskItem.ownerFullName, actionText, commentText];

    [cell.taskTextLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {

        // Making the action bold
        NSRange boldRange = [[mutableAttributedString string] rangeOfString:actionText];
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:cell.taskTextLabel.font.pointSize];
        CTFontRef font = CTFontCreateWithName((CFStringRef) boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        if (font)
        {
            [mutableAttributedString addAttribute:(NSString *) kCTFontAttributeName value:(id) font range:boldRange];
            CFRelease(font);
        }

        // The comment text is grey
        if (taskItem.comment)
        {
            NSRange commentRange = [[mutableAttributedString string] rangeOfString:taskItem.comment];
            [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor grayColor].CGColor range:commentRange];
        }

        return mutableAttributedString;
    }];

    // Cell icon
    if (taskItem.taskType == TASK_TYPE_REVIEW && taskItem.outcome != nil && taskItem.completionDate != nil)
    {
        if ([taskItem.outcome isEqualToString:@"Approve"])
        {
            cell.iconImageView.image = [UIImage imageNamed:@"taskApproved.png"];
        }
        else if ([taskItem.outcome isEqualToString:@"Reject"])
        {
            cell.iconImageView.image = [UIImage imageNamed:@"taskRejected.png"];
        }
    }

    // Cell picture
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT_TASK_CELL;
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
