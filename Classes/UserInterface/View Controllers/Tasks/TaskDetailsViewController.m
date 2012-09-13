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
// TaskDetailsViewController 
//

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "TaskDetailsViewController.h"
#import "AsyncLoadingUIImageView.h"
#import "AvatarHTTPRequest.h"
#import "TaskItem.h"
#import "DateIconView.h"
#import "TaskDocumentViewCell.h"
#import "NodeThumbnailHTTPRequest.h"
#import "DocumentItem.h"
#import "ASIDownloadCache.h"
#import "Utility.h"
#import "MBProgressHUD.h"
#import "DownloadProgressBar.h"
#import "ObjectByIdRequest.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"
#import "PeoplePickerViewController.h"
#import "TaskManager.h"
#import "ASIHTTPRequest.h"
#import "TaskTakeTransitionHTTPRequest.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "ReadUnreadManager.h"
#import "UILabel+Utils.h"
#import "MetaDataTableViewController.h"
#import "DocumentTableDelegate.h"

#define HEADER_MARGIN 20.0
#define DUEDATE_SIZE 60.0
#define FOOTER_HEIGHT 80.0
#define BUTTON_MARGIN 10.0

@interface TaskDetailsViewController () <PeoplePickerDelegate, ASIHTTPRequestDelegate>

// Header
@property (nonatomic, retain) UILabel *taskNameLabel;
@property (nonatomic, retain) DateIconView *dueDateIconView;
@property (nonatomic, retain) UIImageView *headerSeparator;
@property (nonatomic, retain) UIImageView *priorityIcon;
@property (nonatomic, retain) UILabel *priorityLabel;
@property (nonatomic, retain) UILabel *workflowNameLabel;
@property (nonatomic, retain) UIImageView *assigneeIcon;
@property (nonatomic, retain) UILabel *assigneeLabel;

// Documents
@property (nonatomic, retain) UITableView *documentTable;
@property (nonatomic, retain) DocumentTableDelegate *documentTableDelegate;
@property (nonatomic, retain) MBProgressHUD *HUD;

// Transitions and reassign buttons
@property (nonatomic, retain) UIView *footerView;
@property (nonatomic, retain) UITextField *commentTextField;
@property (nonatomic, retain) UIImageView *buttonsSeparator;
@property (nonatomic, retain) UIButton *rejectButton;
@property (nonatomic, retain) UIButton *approveButton;
@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, retain) UIImageView *buttonDivider;
@property (nonatomic, retain) UIButton *reassignButton;

// Keyboard handling
@property (nonatomic) BOOL commentKeyboardShown;
@property (nonatomic) CGSize keyboardSize;

@end

@implementation TaskDetailsViewController

@synthesize taskItem = _taskItem;
@synthesize taskNameLabel = _taskNameLabel;
@synthesize dueDateIconView = _dueDateIconView;
@synthesize headerSeparator = _headerSeparator;
@synthesize priorityIcon = _priorityIcon;
@synthesize priorityLabel = _priorityLabel;
@synthesize workflowNameLabel = _workflowNameLabel;
@synthesize assigneeIcon = _assigneeIcon;
@synthesize assigneeLabel = _assigneeLabel;
@synthesize documentTable = _documentTable;
@synthesize HUD = _HUD;
@synthesize footerView = _footerView;
@synthesize commentTextField = _commentTextField;
@synthesize buttonsSeparator = _buttonsSeparator;
@synthesize rejectButton = _rejectButton;
@synthesize approveButton = _approveButton;
@synthesize doneButton = _doneButton;
@synthesize buttonDivider = _buttonDivider;
@synthesize reassignButton = _reassignButton;
@synthesize commentKeyboardShown = _commentKeyboardShown;
@synthesize keyboardSize = _keyboardSize;


#pragma mark - View lifecycle

- (id)initWithTaskItem:(TaskItem *)taskItem
{
    self = [super init];
    if (self)
    {
        _taskItem = [taskItem retain];
    }

    return self;
}

- (void)dealloc
{
    [_HUD release];
    [_taskNameLabel release];
    [_priorityIcon release];
    [_priorityLabel release];
    [_workflowNameLabel release];
    [_assigneeIcon release];
    [_assigneeLabel release];
    [_documentTable release];
    [_taskItem release];
    [_dueDateIconView release];
    [_footerView release];
    [_rejectButton release];
    [_approveButton release];
    [_reassignButton release];
    [_buttonsSeparator release];
    [_doneButton release];
    [_buttonDivider release];
    [_headerSeparator release];
    [_commentTextField release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    [self createDueDateView];
    [self createTaskNameLabel];
    [self createPriorityViews];
    [self createWorkflowNameLabel];
    [self createAssigneeViews];
    [self createDocumentTable];
    [self createTransitionButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Hide navigation bar
    if (IS_IPAD)
    {
        [self.navigationController setNavigationBarHidden:YES];
    }

    // Notification registration
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShowNotification:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNotification:)
                                                    name:UIKeyboardWillHideNotification object:nil];

    // Calculate frames of all components
    [self calculateSubViewFrames];

    // Show and load task task details
    [self showTask];

    // Remove any selection in the document table (eg when popping back to this controller)
    NSIndexPath *selectedRow = [self.documentTable indexPathForSelectedRow];
    if (selectedRow)
    {
        [self.documentTable deselectRowAtIndexPath:selectedRow animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SubView creation

- (void)createTaskNameLabel
{
    UILabel *taskNameLabel = [[UILabel alloc] init];
    taskNameLabel.lineBreakMode = UILineBreakModeClip;
    taskNameLabel.font = [UIFont systemFontOfSize:24];
    taskNameLabel.numberOfLines = 1;
    self.taskNameLabel = taskNameLabel;
    [self.view addSubview:self.taskNameLabel];
    [taskNameLabel release];

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

- (void)createWorkflowNameLabel
{
    UILabel *workflowNameLabel = [[UILabel alloc] init];
    workflowNameLabel.font = [UIFont systemFontOfSize:13];
    self.workflowNameLabel = workflowNameLabel;
    [self.view addSubview:workflowNameLabel];
    [workflowNameLabel release];
}

- (void)createAssigneeViews
{
    // Icon
    UIImageView *assigneeIcon= [[UIImageView alloc] init];
    assigneeIcon.image = [UIImage imageNamed:@"taskAssignee.png"];
    self.assigneeIcon = assigneeIcon;
    [self.view addSubview:self.assigneeIcon];
    [assigneeIcon release];

    // Label
    UILabel *assigneeLabel = [[UILabel alloc] init];
    assigneeLabel.font = [UIFont systemFontOfSize:13];
    self.assigneeLabel = assigneeLabel;
    [self.view addSubview:self.assigneeLabel];
    [assigneeLabel release];
}

- (void)createDocumentTable
{
    UITableView *documentTableView = [[UITableView alloc] init];

    DocumentTableDelegate *tableDelegate = [[DocumentTableDelegate alloc] init];
    tableDelegate.documents = self.taskItem.documentItems;
    tableDelegate.tableView = documentTableView;
    tableDelegate.navigationController = self.navigationController;
    tableDelegate.viewBlockedByLoadingHud = self.navigationController.view;
    tableDelegate.accountUUID = self.taskItem.accountUUID;
    tableDelegate.tenantID = self.taskItem.tenantId;
    self.documentTableDelegate = tableDelegate;
    [tableDelegate release];

    documentTableView.delegate = self.documentTableDelegate;
    documentTableView.dataSource = self.documentTableDelegate;

    documentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.documentTable = documentTableView;
    [self.view addSubview:self.documentTable];
    [documentTableView release];
}

- (void)createTransitionButtons
{
    // Background
    UIView *footerView = [[UIView alloc] init];
    footerView.backgroundColor = [UIColor whiteColor];
    footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    self.footerView = footerView;
    [footerView release];
    [self.view addSubview:self.footerView];

    // Comment box
    UITextField *commentTextField = [[UITextField alloc] init];
    commentTextField.placeholder = NSLocalizedString(@"task.detail.comment.placeholder", nil);
    commentTextField.borderStyle = UITextBorderStyleRoundedRect;
    commentTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    commentTextField.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    commentTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    self.commentTextField = commentTextField;
    [commentTextField release];
    [self.footerView addSubview:self.commentTextField];

    // Transition buttons
    if (self.taskItem.taskType == TASK_TYPE_REVIEW)
    {
        UIButton *rejectButton = [self taskButtonWithTitle:NSLocalizedString(@"task.detail.reject.button", nil)
                                                     image:@"RejectButton.png" action:@selector(transitionButtonTapped:)];
        self.rejectButton = rejectButton;
        [self.footerView addSubview:self.rejectButton];

        UIButton *approveButton = [self taskButtonWithTitle:NSLocalizedString(@"task.detail.approve.button", nil)
                                                      image:@"ApproveButton.png" action:@selector(transitionButtonTapped:)];
        self.approveButton = approveButton;
        [self.footerView addSubview:self.approveButton];
    }
    else
    {
        UIButton *doneButton = [self taskButtonWithTitle:NSLocalizedString(@"task.detail.done.button", nil)
                                                   image:@"ApproveButton.png" action:@selector(transitionButtonTapped:)];
        self.doneButton = doneButton;
        [self.footerView addSubview:self.doneButton];
    }

    // Divider between buttons
    UIImageView *dividerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"buttonDivide.png"]];
    self.buttonDivider = dividerImage;
    [dividerImage release];
    [self.footerView addSubview:self.buttonDivider];

    // Reassign button
    UIButton *reassignButton = [self taskButtonWithTitle:NSLocalizedString(@"task.detail.reassign.button", nil)
                                                       image:@"ReassignButton.png" action:@selector(reassignButtonTapped:)];
    [reassignButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.reassignButton = reassignButton;
    [self.footerView addSubview:self.reassignButton];

    // Gray line above buttons
    UIImageView *separator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"taskDetailsHorizonalLine.png"]];
    self.buttonsSeparator = separator;
    [separator release];
    [self.view addSubview:self.buttonsSeparator];

}

- (UIButton *)taskButtonWithTitle:(NSString *)title image:(NSString *)imageName action:(SEL)action
{
    UIButton *button = [[[UIButton alloc] init] autorelease];
    [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 30, 0, 0);
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)calculateSubViewFrames
{
    // Header
    CGRect dueDateFrame = CGRectMake(HEADER_MARGIN, HEADER_MARGIN, DUEDATE_SIZE, DUEDATE_SIZE);
    self.dueDateIconView.frame = dueDateFrame;

    CGFloat taskNameX = dueDateFrame.origin.x + dueDateFrame.size.width + HEADER_MARGIN/2;
    CGRect taskNameFrame = CGRectMake(taskNameX, dueDateFrame.origin.y, self.view.frame.size.width - taskNameX - 20, 36);
    self.taskNameLabel.frame = taskNameFrame;

    [self calculateSubHeaderFrames];

    // Separator
    self.headerSeparator.frame = CGRectMake((self.view.frame.size.width - self.headerSeparator.image.size.width) / 2, 90,
            self.headerSeparator.image.size.width, self.headerSeparator.image.size.height);

    // Document table
    CGFloat documentTableHeight = self.headerSeparator.frame.origin.y + self.headerSeparator.frame.size.height;
    CGRect documentTableFrame = CGRectMake(0, documentTableHeight,
            self.view.frame.size.width, self.view.frame.size.height - documentTableHeight - FOOTER_HEIGHT);
    self.documentTable.frame = documentTableFrame;

    // Panel at the bottom with buttons
    CGRect footerFrame = [self calculateFooterFrame];

    CGSize buttonImageSize = [self.reassignButton backgroundImageForState:UIControlStateNormal].size;
    CGRect reassignButtonFrame = CGRectMake(footerFrame.size.width - BUTTON_MARGIN - buttonImageSize.width,
            (footerFrame.size.height - buttonImageSize.height) / 2, buttonImageSize.width, buttonImageSize.height);
    self.reassignButton.frame = reassignButtonFrame;

    CGSize dividerSize = self.buttonDivider.image.size;
    CGRect dividerFrame = CGRectMake(reassignButtonFrame.origin.x - BUTTON_MARGIN - dividerSize.width,
            (footerFrame.size.height - dividerSize.height) / 2, dividerSize.width, dividerSize.height);
    self.buttonDivider.frame = dividerFrame;

    UIButton *happyPathButton = (self.approveButton != nil) ? self.approveButton : self.doneButton;
    buttonImageSize = [happyPathButton backgroundImageForState:UIControlStateNormal].size;
    CGRect happyPathButtonFrame = CGRectMake(dividerFrame.origin.x - BUTTON_MARGIN - buttonImageSize.width,
            (footerFrame.size.height - buttonImageSize.height) / 2, buttonImageSize.width, buttonImageSize.height);
    happyPathButton.frame = happyPathButtonFrame;

    if (self.rejectButton)
    {
        buttonImageSize = [self.rejectButton backgroundImageForState:UIControlStateNormal].size;
        self.rejectButton.frame = CGRectMake(happyPathButtonFrame.origin.x - BUTTON_MARGIN - buttonImageSize.width,
                    (footerFrame.size.height - buttonImageSize.height) / 2, buttonImageSize.width, buttonImageSize.height);
    }

    // Comment text box
    UIButton *leftMostButton = (self.rejectButton != nil) ? self.rejectButton : happyPathButton;
    CGRect commentTextFieldFrame = CGRectMake(2* BUTTON_MARGIN, leftMostButton.frame.origin.y,
            leftMostButton.frame.origin.x - (3 * BUTTON_MARGIN), leftMostButton.frame.size.height);
    self.commentTextField.frame = commentTextFieldFrame;
}

- (void)calculateSubHeaderFrames
{
    CGFloat subHeaderMargin = 25.0;

    CGRect priorityIconFrame = CGRectMake(self.taskNameLabel.frame.origin.x,
            self.taskNameLabel.frame.origin.y + self.taskNameLabel.frame.size.height,
            self.priorityIcon.image.size.width, self.priorityIcon.image.size.height);
    self.priorityIcon.frame = priorityIconFrame;

    CGRect priorityLabelFrame = CGRectMake(priorityIconFrame.origin.x + priorityIconFrame.size.width + 4,
            priorityIconFrame.origin.y,
            [self.priorityLabel.text sizeWithFont:self.priorityLabel.font].width,
            priorityIconFrame.size.height);
    self.priorityLabel.frame = priorityLabelFrame;

    CGRect workflowNameFrame = CGRectMake(priorityLabelFrame.origin.x + priorityLabelFrame.size.width + subHeaderMargin,
            priorityLabelFrame.origin.y,
            [self.workflowNameLabel.text sizeWithFont:self.workflowNameLabel.font].width,
            priorityLabelFrame.size.height);
    self.workflowNameLabel.frame = workflowNameFrame;

    CGRect assigneeIconFrame = CGRectMake(workflowNameFrame.origin.x + workflowNameFrame.size.width + subHeaderMargin,
            workflowNameFrame.origin.y, self.assigneeIcon.image.size.width, self.assigneeIcon.image.size.height);
    self.assigneeIcon.frame = assigneeIconFrame;

    CGRect assigneeLabelFrame = CGRectMake(assigneeIconFrame.origin.x + assigneeIconFrame.size.width + 4,
            assigneeIconFrame.origin.y,
            [self.assigneeLabel.text sizeWithFont:self.assigneeLabel.font].width,
            assigneeIconFrame.size.height);
    self.assigneeLabel.frame = assigneeLabelFrame;
}

- (CGRect)calculateFooterFrame
{
    CGRect documentTableFrame = self.documentTable.frame;
    CGFloat footerY = documentTableFrame.origin.y + documentTableFrame.size.height;
    if (self.commentKeyboardShown)
    {
        // Note we're not using height, here. It seems to be a bug where height and width are switched
        // See http://stackoverflow.com/questions/4213878/what-is-the-height-of-ipads-onscreen-keyboard
        footerY = footerY - self.keyboardSize.width;
    }

    CGRect footerFrame = CGRectMake(0, footerY, self.view.frame.size.width, FOOTER_HEIGHT);
    self.footerView.frame = footerFrame;

    self.buttonsSeparator.frame = CGRectMake((footerFrame.size.width - self.buttonsSeparator.image.size.width)/2,
            footerFrame.origin.y, self.buttonsSeparator.image.size.width, self.buttonsSeparator.image.size.height);

    return footerFrame;
}

#pragma mark - Instance methods

- (void)showTask
{
    // Task header
    self.taskNameLabel.text = self.taskItem.description;
    self.priorityLabel.text = [NSString stringWithFormat:@"%@ %@", self.taskItem.priority, NSLocalizedString(@"task.detail.priority", nil)];
    self.assigneeLabel.text = self.taskItem.ownerFullName;

    switch (self.taskItem.workflowType)
    {
        case WORKFLOW_TYPE_TODO:
            self.workflowNameLabel.text = NSLocalizedString(@"task.detail.workflow.todo", nil);
            break;
        case WORKFLOW_TYPE_REVIEW:
            self.workflowNameLabel.text = NSLocalizedString(@"task.detail.workflow.review.and.approve", nil);
            break;
    }

    // Due date
    if (self.taskItem.dueDate)
    {
        self.dueDateIconView.date = self.taskItem.dueDate;
    }

    // Size all labels according to text
    [self.taskNameLabel appendDotsIfTextDoesNotFit];
    [self calculateSubHeaderFrames];
}

- (void)reassignButtonTapped:(id)sender
{
    PeoplePickerViewController *peopleController = [[PeoplePickerViewController alloc] initWithAccount:self.taskItem.accountUUID tenantID:self.taskItem.tenantId];
    peopleController.delegate = self;
    peopleController.isMultipleSelection = NO;
    peopleController.modalPresentationStyle = UIModalPresentationFormSheet;
    peopleController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [IpadSupport presentModalViewController:peopleController withNavigation:nil];
    [peopleController release];
}

- (void)transitionButtonTapped:(id)sender
{
    NSString *outcome = nil;
    if (sender == self.approveButton)
    {
        outcome = @"Approve";
    }
    else if (sender == self.rejectButton)
    {
        outcome = @"Reject";
    }

    // Remove keyboard if still visible
    if ([self.commentTextField isFirstResponder])
    {
        [self.commentTextField resignFirstResponder];
    }

    TaskTakeTransitionHTTPRequest *request = [TaskTakeTransitionHTTPRequest taskTakeTransitionRequestForTask:self.taskItem
          outcome:outcome comment:self.commentTextField.text accountUUID:self.taskItem.accountUUID tenantID:self.taskItem.tenantId];
    [request setCompletionBlock:^ {
        [self stopHUD];

        // The table view will listen to the following notifications and update itself
        [[NSNotificationCenter defaultCenter] postTaskCompletedNotificationWithUserInfo:
                [NSDictionary dictionaryWithObject:self.taskItem.taskId forKey:@"taskId"]];
        
        [[ReadUnreadManager sharedManager] removeReadStatusForTaskId:self.taskItem.taskId];
    }];
    [request setFailedBlock:^ {
        [self stopHUD];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"connectionErrorMessage", nil)
                                                        message:request.error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"okayButtonText", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }];

    [self startHUD];
    self.HUD.labelText = NSLocalizedString(@"task.detail.completing", nil);

    [request startAsynchronous];
}

#pragma mark - People picker delegate

- (void)personsPicked:(NSArray *)persons
{
    if (persons.count != 1) return;
    
    [self startHUD];
    Person *person = [persons objectAtIndex:0];
    self.taskItem.ownerUserName = person.userName;
    self.taskItem.ownerFullName = [NSString stringWithFormat:@"%@ %@", person.firstName, person.lastName];
    [[TaskManager sharedManager] startTaskUpdateRequestForTask:self.taskItem accountUUID:self.taskItem.accountUUID tenantID:self.taskItem.tenantId delegate:self];
}

#pragma mark - ASI Request delegate

// Assignee update
- (void)requestFinished:(ASIHTTPRequest *)request
{
    self.assigneeLabel.text = self.taskItem.ownerFullName;

    self.HUD.labelText = NSLocalizedString(@"task.assignee.updated", nil);
    [self.HUD hide:YES afterDelay:0.5];
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

#pragma mark Keyboard show/hide handling

- (void)handleKeyboardDidShowNotification:(NSNotification *)notification
{
    [self handleKeyboardNotification:notification keyboardVisible:YES];
}

- (void)handleKeyboardWillHideNotification:(NSNotification *)notification
{
    [self handleKeyboardNotification:notification keyboardVisible:NO];
}

- (void)handleKeyboardNotification:(NSNotification *)notification keyboardVisible:(BOOL)keyboardVisible
{
    if ([self.commentTextField isFirstResponder])
    {
        self.commentKeyboardShown = keyboardVisible;
        self.keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

        // Show/remove shadows
        if (keyboardVisible)
        {
            self.footerView.layer.shadowColor = [UIColor blackColor].CGColor;
            self.footerView.layer.shadowRadius = 20.0;
            self.footerView.layer.shadowOpacity = 10.0;
            self.footerView.layer.shadowOffset = CGSizeMake(0, 20.0);
        }
        else
        {
            self.footerView.layer.shadowRadius = 0;
            self.footerView.layer.shadowOpacity = 0;
            self.footerView.layer.shadowOffset = CGSizeMake(0, 0);
        }

        // Enable/disable certain views
        self.documentTable.scrollEnabled = !keyboardVisible;
        self.documentTable.userInteractionEnabled = !keyboardVisible;
        self.documentTable.alpha = keyboardVisible ? 0.35 : 1.0;
        self.buttonsSeparator.hidden = keyboardVisible;

        // Move panel up or down
        [self calculateFooterFrame];
    }
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

// When the collapse/expand functionality (arrow button in left top) is used, the split view controller requests to re-layout the subviews.
// Hence, we can recalculate the subview frames by overriding this method.
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self calculateSubViewFrames];
}


@end
