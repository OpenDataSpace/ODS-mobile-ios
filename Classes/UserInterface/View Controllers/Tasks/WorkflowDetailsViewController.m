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
#import <QuartzCore/QuartzCore.h>
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

#define HEADER_MARGIN_IPAD 20.0
#define HEADER_MARGIN_IPHONE 10.0
#define DUEDATE_SIZE 60.0
#define CELL_HEIGHT_TASK_CELL_IPAD 100.0
#define CELL_HEIGHT_TASK_CELL_IPHONE 140.0

#define TAG_TASK_TABLE 0
#define TAG_DOCUMENT_TABLE 1

@interface WorkflowDetailsViewController () <UITableViewDataSource, UITableViewDelegate, TaskManagerDelegate>

// Header
@property (nonatomic, retain) UILabel *workflowNameLabel;
@property (nonatomic, retain) UITextView *workflowNameTextView;
@property (nonatomic) BOOL isWorkflowNameShortened;
@property (nonatomic, retain) DateIconView *dueDateIconView;
@property (nonatomic, retain) UIImageView *headerSeparator;
@property (nonatomic, retain) UIImageView *priorityIcon;
@property (nonatomic, retain) UILabel *priorityLabel;
@property (nonatomic, retain) UILabel *workflowTypeLabel;
@property (nonatomic, retain) UIImageView *initiatorIcon;
@property (nonatomic, retain) UILabel *initiatorLabel;

// More button
@property (nonatomic) BOOL moreDetailsShowing;
@property (nonatomic, retain) UIView *moreBackgroundView;
@property (nonatomic, retain) UIButton *moreIcon;
@property (nonatomic, retain) UIButton *moreButton;

// Table switch buttons
@property (nonatomic, retain) UIButton *showTasksButton;
@property (nonatomic, retain) UIImageView *buttonDivider;
@property (nonatomic, retain) UIButton *showDocumentsButton;

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
@synthesize moreBackgroundView = _moreBackgroundView;
@synthesize moreIcon = _moreIcon;
@synthesize moreButton = _moreButton;
@synthesize isWorkflowNameShortened = _isWorkflowNameShortened;
@synthesize workflowNameTextView = _workflowNameTextView;
@synthesize moreDetailsShowing = _moreDetailsShowing;





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
    [_moreBackgroundView release];
    [_moreIcon release];
    [_moreButton release];
    [_workflowNameTextView release];
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
    [self createTableSwitchButtons];
    [self createTaskTable];
    [self createDocumentTable];

    [self createMoreButton];
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
    workflowNameLabel.font = [UIFont systemFontOfSize:(IS_IPAD ? 24 : 18)];
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
    taskButton.titleLabel.font = [UIFont systemFontOfSize:(IS_IPAD ? 16 : 14)];
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
    documentButton.titleLabel.font = self.showTasksButton.titleLabel.font;
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

    if (!IS_IPAD)
    {
        documentTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        documentTableView.layer.borderColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.6].CGColor;
        documentTableView.layer.borderWidth = 1.0;
    }
    else
    {
        documentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }


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

- (void)createMoreButton
{
    UIView *moreBackgroundView = [[UIView alloc] init];
    moreBackgroundView.backgroundColor = [UIColor whiteColor];
    moreBackgroundView.layer.shadowColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.6].CGColor;
    moreBackgroundView.layer.shadowOffset = CGSizeMake(-1.0, 1.0);
    moreBackgroundView.layer.shadowOpacity = 2.0;
    moreBackgroundView.layer.shadowRadius = 0.7;
    self.moreBackgroundView = moreBackgroundView;
    [self.view addSubview:self.moreBackgroundView];
    [moreBackgroundView release];

    UIButton *moreIconButton = [[UIButton alloc] init];
    [moreIconButton setImage:[UIImage imageNamed:@"triangleDown.png"] forState:UIControlStateNormal];
    [moreIconButton setImage:[UIImage imageNamed:@"triangleUp.png"] forState:UIControlStateSelected];
    [moreIconButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.moreIcon = moreIconButton;
    [self.view addSubview:self.moreIcon];
    [moreIconButton release];

    UIButton *moreButton = [[UIButton alloc] init];
    [moreButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [moreButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    [moreButton setTitle:NSLocalizedString(@"task.detail.more", nil) forState:UIControlStateNormal];
    [moreButton setTitle:NSLocalizedString(@"task.detail.less", nil) forState:UIControlStateSelected];
    [moreButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.moreButton = moreButton;
    [self.view addSubview:self.moreButton];
    [moreButton release];
}

- (void)calculateSubViewFrames
{
    BOOL isIPad = IS_IPAD;

    // Header
    CGFloat headerMargin = isIPad ? HEADER_MARGIN_IPAD : HEADER_MARGIN_IPHONE;
    CGRect dueDateFrame = CGRectMake(headerMargin, headerMargin, DUEDATE_SIZE, DUEDATE_SIZE);
    self.dueDateIconView.frame = dueDateFrame;

    CGFloat workflowNameX = dueDateFrame.origin.x + dueDateFrame.size.width + headerMargin/2;
    CGRect taskNameFrame = CGRectMake(workflowNameX, dueDateFrame.origin.y, self.view.frame.size.width - workflowNameX - 20, 36);
    self.workflowNameLabel.frame = taskNameFrame;

    [self calculateSubHeaderFrames];

    // Separator
    self.headerSeparator.frame = CGRectMake((self.view.frame.size.width - self.headerSeparator.image.size.width) / 2,
            isIPad ? 90 : dueDateFrame.origin.y + dueDateFrame.size.height,
            self.headerSeparator.image.size.width, self.headerSeparator.image.size.height);

    // More button
    CGFloat whitespace = isIPad ? 40.0 : 10.0;
    CGSize moreButtonSize = [[self.moreButton titleForState:UIControlStateNormal] sizeWithFont:self.moreButton.titleLabel.font];
    CGSize moreIconSize = [self.moreIcon imageForState:UIControlStateNormal].size;

    CGRect moreButtonFrame = CGRectMake(self.view.frame.size.width - moreButtonSize.width - moreIconSize.width - whitespace,
            isIPad ? self.initiatorLabel.frame.origin.y : self.headerSeparator.frame.origin.y,
            moreButtonSize.width, moreButtonSize.height);
    self.moreButton.frame = moreButtonFrame;

    CGRect moreIconFrame = CGRectMake(moreButtonFrame.origin.x + moreButtonFrame.size.width,
            moreButtonFrame.origin.y + ((moreButtonFrame.size.height - moreIconSize.height) / 2),
            moreIconSize.width, moreIconSize.height);
    self.moreIcon.frame = moreIconFrame;

    // More button is displayed differently on iPhone as a separate view beneath the header
    if (!isIPad)
    {
        CGFloat backgroundX = moreButtonFrame.origin.x - whitespace;
        CGRect moreBackgroundFrame = CGRectMake(backgroundX, moreButtonFrame.origin.y,
                self.view.frame.size.width - backgroundX, moreButtonSize.height + 4.0);
        self.moreBackgroundView.frame = moreBackgroundFrame;
    }

    // Table buttons
    CGFloat dividerY = self.headerSeparator.frame.origin.y + self.headerSeparator.frame.size.height + ((isIPad) ? 10 : 0);
    CGRect dividerFrame = CGRectMake((self.view.frame.size.width - self.buttonDivider.image.size.width) / 2,
            dividerY, self.buttonDivider.image.size.width, self.buttonDivider.image.size.height);
    self.buttonDivider.frame = dividerFrame;

    CGRect showTaskButtonFrame = CGRectMake(0, dividerFrame.origin.y, dividerFrame.origin.x - 10, dividerFrame.size.height);
    self.showTasksButton.frame = showTaskButtonFrame;

    CGRect showDocumentsButtonFrame = CGRectMake(dividerFrame.origin.x + dividerFrame.size.width + 10, dividerFrame.origin.y,
            self.view.frame.size.width - (dividerFrame.origin.x + dividerFrame.size.width), dividerFrame.size.height);
    self.showDocumentsButton.frame = showDocumentsButtonFrame;

    // Task table
    CGFloat taskTableY = dividerFrame.origin.y + dividerFrame.size.height + ((isIPad) ? 5 : 1);
    CGRect taskTableFrame = CGRectMake(0, taskTableY, self.view.frame.size.width, self.view.frame.size.height - taskTableY);
    self.taskTable.frame = taskTableFrame;

    // Document table
    self.documentTable.frame = taskTableFrame;

    // Documents loading label
    self.documentsLoadingLabel.frame = taskTableFrame;
}

- (void)calculateSubHeaderFrames
{
    if (IS_IPAD)
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
    self.isWorkflowNameShortened = [self.workflowNameLabel appendDotsIfTextDoesNotFit];
    [self calculateSubHeaderFrames];

    // On ipad, we currently ony show the workflow name ... so remove the more button if it is not shortened
    if (!self.isWorkflowNameShortened && IS_IPAD)
    {
        self.moreButton.hidden = YES;
        self.moreIcon.hidden = YES;
    }
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

- (void)moreButtonTapped
{
    self.moreDetailsShowing = !self.moreDetailsShowing;
    IS_IPAD ? [self handleMoreButtonTappedIpad] : [self handleMoreButtonTappedIphone];
}

- (void)handleMoreButtonTappedIphone
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];

    // Remove more button and icon
    [self.moreButton removeFromSuperview];
    [self.moreIcon removeFromSuperview];

        // Switching the label (which has numberoflines and appending dots at the end capabilities)
    // to a textview (needed if text is huge and scrolling is needed)
    UITextView *workflowNameTextView = [[UITextView alloc] init];
    workflowNameTextView.frame = self.workflowNameLabel.frame;
    workflowNameTextView.font = self.workflowNameLabel.font;
    workflowNameTextView.text = self.workflowItem.message;
    workflowNameTextView.contentInset = UIEdgeInsetsMake(-11,-8,0,0);
    workflowNameTextView.editable = NO;
    self.workflowNameTextView = workflowNameTextView;
    [self.view addSubview:self.workflowNameTextView];
    [workflowNameTextView release];

    // Label can now be removed (no going back for iphone)
    [self.workflowNameLabel removeFromSuperview];
    [self calculateDetailFramesForIphone];


    [UIView commitAnimations];
}

- (void)calculateDetailFramesForIphone
{
    CGSize workflowNameSize = [self.workflowNameTextView.text sizeWithFont:self.workflowNameTextView.font
                                                      constrainedToSize:CGSizeMake(self.workflowNameTextView.frame.size.width, CGFLOAT_MAX)];
    CGRect workflowNameFrame = CGRectMake(self.workflowNameTextView.frame.origin.x,
            self.dueDateIconView.frame.origin.y + 5.0,
            self.view.frame.size.width - self.workflowNameTextView.frame.origin.x - 10.0,
            MIN(workflowNameSize.height, self.view.frame.size.height / 3));
    self.workflowNameTextView.frame = workflowNameFrame;

    // Details: priority, workflow type and initiator
    CGFloat taskNameBottomY = workflowNameFrame.origin.y + workflowNameFrame.size.height;
    CGFloat dueDateBottomY = self.dueDateIconView.frame.origin.y + self.dueDateIconView.frame.size.height;
    CGRect priorityIconFrame = CGRectMake(10.0,
            10.0 + MAX(taskNameBottomY, dueDateBottomY),
            self.priorityIcon.image.size.width,
            self.priorityIcon.image.size.height);
    self.priorityIcon.frame = priorityIconFrame;

    CGRect priorityLabelFrame = CGRectMake(priorityIconFrame.origin.x + priorityIconFrame.size.width + 5,
            priorityIconFrame.origin.y,
            [self.priorityLabel.text sizeWithFont:self.priorityLabel.font].width,
            priorityIconFrame.size.height);
    self.priorityLabel.frame = priorityLabelFrame;

    CGRect workflowTypeFrame = CGRectMake(priorityLabelFrame.origin.x + priorityLabelFrame.size.width + 20.0,
            priorityLabelFrame.origin.y,
            [self.workflowTypeLabel.text sizeWithFont:self.workflowTypeLabel.font].width,
            priorityLabelFrame.size.height);
    self.workflowTypeLabel.frame = workflowTypeFrame;

    CGRect initiatorIconFrame = CGRectMake(priorityIconFrame.origin.x,
            priorityIconFrame.origin.y + priorityIconFrame.size.height + 5,
            self.initiatorIcon.image.size.width, self.initiatorIcon.image.size.height);
    self.initiatorIcon.frame = initiatorIconFrame;

    CGRect initiatorLabel = CGRectMake(initiatorIconFrame.origin.x + initiatorIconFrame.size.width + 5,
            initiatorIconFrame.origin.y,
            [self.initiatorLabel.text sizeWithFont:self.initiatorLabel.font].width,
            initiatorIconFrame.size.height);
    self.initiatorLabel.frame = initiatorLabel;

    // Enlarge the background
    self.moreBackgroundView.frame = CGRectMake(0, 0, self.view.frame.size.width,
            initiatorLabel.origin.y + initiatorLabel.size.height + 5.0);
    [self.moreBackgroundView removeFromSuperview];
    [self.view insertSubview:self.moreBackgroundView belowSubview:self.dueDateIconView];

    // Move the divider
    self.headerSeparator.frame = CGRectMake(self.headerSeparator.frame.origin.x,
            self.moreBackgroundView.frame.origin.y + self.moreBackgroundView.frame.size.height,
            self.headerSeparator.frame.size.width, self.headerSeparator.frame.size.height);

    // Move the switch buttons
    self.buttonDivider.frame = CGRectMake(self.buttonDivider.frame.origin.x,
            self.headerSeparator.frame.origin.y + self.headerSeparator.frame.size.height,
            self.buttonDivider.frame.size.width, self.buttonDivider.frame.size.height);
    self.showTasksButton.frame = CGRectMake(self.showTasksButton.frame.origin.x,
            self.buttonDivider.frame.origin.y,
            self.showTasksButton.frame.size.width, self.showTasksButton.frame.size.height);
    self.showDocumentsButton.frame = CGRectMake(self.showDocumentsButton.frame.origin.x,
            self.buttonDivider.frame.origin.y,
            self.showDocumentsButton.frame.size.width, self.showDocumentsButton.frame.size.height);

    // Shrink the tables
    self.documentTable.frame = CGRectMake(self.documentTable.frame.origin.x,
            self.buttonDivider.frame.origin.y + self.buttonDivider.frame.size.height,
            self.documentTable.frame.size.width,
            self.documentTable.frame.size.height);

    self.taskTable.frame = self.documentTable.frame;
}

- (void)handleMoreButtonTappedIpad
{
    // 'more' button becomes 'less' button and vice versa
    self.moreButton.selected = !self.moreButton.selected;
    self.moreIcon.selected = !self.moreIcon.selected;

    if (self.moreButton.selected) // Expanding (ie showing more details)
    {
        [self createDetailViewForIpad];
    }
    else // Collapse (ie show less details)
    {
        [self.moreBackgroundView removeFromSuperview];;
        self.moreBackgroundView = nil;
    }
}

- (void)createDetailViewForIpad
{
    // the new content is placed on a 'floating' uiview
    UIView *moreBackgroundView = [[UIView alloc] init];
    moreBackgroundView.backgroundColor = [UIColor whiteColor];
    self.moreBackgroundView = moreBackgroundView;
    [self.view insertSubview:self.moreBackgroundView aboveSubview:self.documentTable];
    [moreBackgroundView release];

    // Add Full description (if necessary)
    CGFloat x = self.dueDateIconView.frame.origin.x;
    CGFloat height = 0;
    if (self.isWorkflowNameShortened)
    {
        height = [self addDetailLabel:NSLocalizedString(@"task.detail.full.description", nil) fontSize:13 multiLine:NO x:x y:0];
        height = [self addDetailTextView:self.workflowItem.message fontSize:15 x:x y:(height + 2.0)];
    }

    // Now we know all the heights of the subviews, so we can create the frame of the background
    self.moreBackgroundView.frame = CGRectMake(0,
            self.headerSeparator.frame.origin.y,
            self.view.frame.size.width, height + 10.0);
    self.moreBackgroundView.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    self.moreBackgroundView.layer.shadowRadius = 3.0;
    self.moreBackgroundView.layer.shadowOpacity = 3.0;
    self.moreBackgroundView.layer.shadowOffset = CGSizeMake(0, 5.0);
}

- (CGFloat)addDetailLabel:(NSString *)text fontSize:(CGFloat)fontSize multiLine:(BOOL)multiLine x:(CGFloat)x y:(CGFloat)y
{
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:fontSize];
    if (multiLine)
    {
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
    }
    label.text = text;

    CGSize size;
    if (multiLine)
    {
        size = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(self.view.frame.size.width - 80, CGFLOAT_MAX)];
    }
    else
    {
        size = [label.text sizeWithFont:label.font];
    }
    CGRect frame = CGRectMake(x, y, size.width, size.height);
    label.frame = frame;

    [self.moreBackgroundView addSubview:label];
    [label release];

    return frame.origin.y + frame.size.height;
}

- (CGFloat)addDetailTextView:(NSString *)text fontSize:(CGFloat)fontSize x:(CGFloat)x y:(CGFloat)y
{
    UITextView *textView = [[UITextView alloc] init];
    textView.font = [UIFont systemFontOfSize:fontSize];
    textView.text = text;
    textView.contentInset = UIEdgeInsetsMake(-11,-8,0,0);

    CGSize size = [textView.text sizeWithFont:textView.font constrainedToSize:CGSizeMake(self.view.frame.size.width - 80, CGFLOAT_MAX)];
    CGRect frame = CGRectMake(x, y, size.width, MIN(size.height, self.view.frame.size.height / 2));
    textView.frame = frame;

    [self.moreBackgroundView addSubview:textView];
    [textView release];

    return frame.origin.y + frame.size.height;
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

    // Avert your eyes! Here be Core Text!
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
    return IS_IPAD ? CELL_HEIGHT_TASK_CELL_IPAD : CELL_HEIGHT_TASK_CELL_IPHONE;
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

    // Special care needed for detail view
    if (self.moreDetailsShowing)
    {
        if (IS_IPAD)
        {
            [self.moreBackgroundView removeFromSuperview];
            [self createDetailViewForIpad];
        }
        else
        {
            [self calculateDetailFramesForIphone];
        }
    }
}

@end
