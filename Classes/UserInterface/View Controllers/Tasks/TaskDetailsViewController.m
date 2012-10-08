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

#import <QuartzCore/QuartzCore.h>
#import "TaskDetailsViewController.h"
#import "AvatarHTTPRequest.h"
#import "TaskItem.h"
#import "DateIconView.h"
#import "Utility.h"
#import "MBProgressHUD.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"
#import "PeoplePickerViewController.h"
#import "TaskManager.h"
#import "ASIHTTPRequest.h"
#import "TaskTakeTransitionHTTPRequest.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "ReadUnreadManager.h"
#import "UILabel+Utils.h"
#import "DocumentTableDelegate.h"

#define IPAD_HEADER_MARGIN 20.0
#define IPHONE_HEADER_MARGIN 10.0
#define DUEDATE_SIZE 60.0
#define FOOTER_HEIGHT_IPHONE 50.0
#define FOOTER_HEIGHT_IPAD 80.0
#define IPAD_BUTTON_MARGIN 10.0
#define IPHONE_BUTTON_MARGIN 5.0

@interface TaskDetailsViewController () <PeoplePickerDelegate, UITextFieldDelegate, ASIHTTPRequestDelegate, UIGestureRecognizerDelegate>

// Header
@property (nonatomic, retain) UILabel *taskNameLabel;
@property (nonatomic, retain) UITextView *taskNameTextView; // Will be used if name is really, really big.
@property (nonatomic) BOOL isTaskNameShortened;
@property (nonatomic, retain) DateIconView *dueDateIconView;
@property (nonatomic, retain) UIImageView *headerSeparator;
@property (nonatomic, retain) UIImageView *priorityIcon;
@property (nonatomic, retain) UILabel *priorityLabel;
@property (nonatomic, retain) UILabel *workflowNameLabel;
@property (nonatomic, retain) UIImageView *assigneeIcon;
@property (nonatomic, retain) UILabel *assigneeLabel;

// Details hidden behind 'more' button
@property (nonatomic) BOOL moreDetailsShowing;
@property (nonatomic, retain) UIView *moreBackgroundView;
@property (nonatomic, retain) UIImageView *moreIcon;
@property (nonatomic, retain) UIButton *moreButton;

// Documents
@property (nonatomic, retain) UITableView *documentTable;
@property (nonatomic, retain) DocumentTableDelegate *documentTableDelegate;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) UIImageView *noDocumentsImageView;
@property (nonatomic, retain) UILabel *noDocumentsLabel;

// Transitions and reassign buttons
@property (nonatomic, retain) UIView *footerView;
@property (nonatomic, retain) UITextField *commentTextField;
@property (nonatomic, retain) UIButton *commentButton;
@property (nonatomic, retain) UIImageView *buttonsSeparator;
@property (nonatomic, retain) UIButton *rejectButton;
@property (nonatomic, retain) UIButton *approveButton;
@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, retain) UIImageView *buttonDivider;
@property (nonatomic, retain) UIButton *reassignButton;

// Keyboard handling
@property (nonatomic) BOOL commentKeyboardShown;
@property (nonatomic) CGRect keyboardFrame;

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
@synthesize keyboardFrame = _keyboardFrame;
@synthesize documentTableDelegate = _documentTableDelegate;
@synthesize commentButton = _commentButton;
@synthesize moreIcon = _moreIcon;
@synthesize moreButton = _moreButton;
@synthesize moreBackgroundView = _moreBackgroundView;
@synthesize isTaskNameShortened = _isTaskNameShortened;
@synthesize moreDetailsShowing = _moreDetailsShowing;
@synthesize taskNameTextView = _taskNameTextView;
@synthesize noDocumentsImageView = _noDocumentsImageView;
@synthesize noDocumentsLabel = _noDocumentsLabel;



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
    [_documentTableDelegate release];
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
    [_commentButton release];
    [_moreIcon release];
    [_moreButton release];
    [_moreBackgroundView release];
    [_taskNameTextView release];
    [_noDocumentsImageView release];
    [_noDocumentsLabel release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    self.view.clipsToBounds = YES;

    if (!IS_IPAD) // on iphone show reassign button
    {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"task.detail.reassign.button", nil)
                                                                                   style:UIBarButtonItemStyleBordered
                                                                                  target:self action:@selector(reassignButtonTapped:)] autorelease];
    }

    [self createDueDateView];
    [self createTaskNameLabel];
    [self createPriorityViews];
    [self createWorkflowNameLabel];
    [self createAssigneeViews];
    [self createDocumentTable];
    [self createTransitionButtons];
    [self createMoreButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Notification registration
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardDidShowNotification:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNotification:)
                                                    name:UIKeyboardWillHideNotification object:nil];

    // Calculate frames of all components
    [self calculateSubViewFrames];
    [self showDetailsIfNeeded];

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
    taskNameLabel.font = [UIFont systemFontOfSize:((IS_IPAD) ? 24 : 20)];

    if (IS_IPAD)
    {
        taskNameLabel.numberOfLines = 2;
    }
    else
    {
        taskNameLabel.numberOfLines = 0;
        taskNameLabel.lineBreakMode = UILineBreakModeWordWrap;
    }

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

- (void)createMoreButton
{
    UIView *moreBackgroundView = [[UIView alloc] init];
    moreBackgroundView.backgroundColor = [UIColor whiteColor];
    moreBackgroundView.layer.shadowColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.6].CGColor;
    moreBackgroundView.layer.shadowOffset = CGSizeMake(-1.0, 1.0);
    moreBackgroundView.layer.shadowOpacity = 2.0;
    moreBackgroundView.layer.shadowRadius = 0.7;
    self.moreBackgroundView = moreBackgroundView;
    [self.view insertSubview:self.moreBackgroundView aboveSubview:((self.documentTable) ? self.documentTable : self.headerSeparator)];
    [moreBackgroundView release];

    UIImageView *moreIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"triangleDown.png"]];
    self.moreIcon = moreIcon;
    [self.view insertSubview:self.moreIcon aboveSubview:self.moreBackgroundView];
    [moreIcon release];

    UIButton *moreButton = [[UIButton alloc] init];
    [moreButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [moreButton.titleLabel setFont:[UIFont systemFontOfSize:(IS_IPAD) ? 13 : 15]];
    [moreButton setTitle:NSLocalizedString(@"task.detail.more", nil) forState:UIControlStateNormal];
    [moreButton setTitle:NSLocalizedString(@"task.detail.less", nil) forState:UIControlStateSelected];
    [moreButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.moreButton = moreButton;
    [self.view insertSubview:self.moreButton aboveSubview:self.moreBackgroundView];
    [moreButton release];

    // To make it easier for the users with fat fingers, we make the whole ui view tappable
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreButtonTapped)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.moreBackgroundView addGestureRecognizer:tapGestureRecognizer];
    [self.moreIcon addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
}

- (void)createDocumentTable
{
    if (self.taskItem.documentItems.count > 0)
    {
        UITableView *documentTableView = [[UITableView alloc] init];
        documentTableView.separatorStyle = IS_IPAD ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;

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

        self.documentTable = documentTableView;
        [self.view addSubview:self.documentTable];
        [documentTableView release];
    }
    else
    {
        UIImageView *noDocumentsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"noTaskDocuments.png"]];
        self.noDocumentsImageView = noDocumentsImageView;
        [self.view addSubview:self.noDocumentsImageView];
        [noDocumentsImageView release];

        UILabel *noDocumentLabel = [[UILabel alloc] init];
        noDocumentLabel.font = [UIFont systemFontOfSize:18];
        noDocumentLabel.text = NSLocalizedString(@"task.detail.no.documents", nil);
        noDocumentLabel.textColor = [UIColor lightGrayColor];
        noDocumentLabel.textAlignment = UITextAlignmentCenter;
        self.noDocumentsLabel = noDocumentLabel;
        [self.view addSubview:self.noDocumentsLabel];
        [noDocumentLabel release];
    }
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

    // Comment text field
    UITextField *commentTextField = [[UITextField alloc] init];
    commentTextField.returnKeyType = UIReturnKeyDone;
    commentTextField.placeholder = NSLocalizedString(@"task.detail.comment.placeholder", nil);
    commentTextField.borderStyle = UITextBorderStyleRoundedRect;
    commentTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    commentTextField.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    commentTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    commentTextField.delegate = self;

    self.commentTextField = commentTextField;
    [commentTextField release];
    [self.footerView addSubview:self.commentTextField];

    // On the iphone, there is not enough room for the comment field, hence we use an icon
    // We do keep the comment text field around, as we will show it when tapped on the icon
    if (!IS_IPAD)
    {
        self.commentTextField.hidden = YES;
        UIButton *commentButton = [[UIButton alloc] init];
        [commentButton setImage:[UIImage imageNamed:@"taskComment.png"] forState:UIControlStateNormal];
        [commentButton addTarget:self action:@selector(commentButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        self.commentButton = commentButton;
        [commentButton release];
        [self.footerView addSubview:self.commentButton];
    }

    // Transition buttons
    if (self.taskItem.taskType == AlfrescoTaskTypeReview)
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

    if (IS_IPAD)
    {
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
    }

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
    BOOL isIPad = IS_IPAD;

    // Header
    CGFloat headerMargin = (isIPad) ? IPAD_HEADER_MARGIN : IPHONE_HEADER_MARGIN;
    CGRect dueDateFrame = CGRectMake(headerMargin, headerMargin, DUEDATE_SIZE, DUEDATE_SIZE);
    self.dueDateIconView.frame = dueDateFrame;

    CGFloat taskNameX = dueDateFrame.origin.x + dueDateFrame.size.width + headerMargin/2;
    CGRect taskNameFrame = CGRectMake(taskNameX, dueDateFrame.origin.y, self.view.frame.size.width - taskNameX - 20, isIPad ? 36 : 60);
    self.taskNameLabel.frame = taskNameFrame;

    [self calculateSubHeaderFrames];

    // Separator
    self.headerSeparator.frame = CGRectMake((self.view.frame.size.width - self.headerSeparator.image.size.width) / 2,
            isIPad ? 90 : dueDateFrame.origin.y + dueDateFrame.size.height + IPHONE_HEADER_MARGIN,
            self.headerSeparator.image.size.width, self.headerSeparator.image.size.height);

    // More button
    CGFloat whitespace = isIPad ? 40.0 : 10.0;
    CGSize moreButtonSize = [[self.moreButton titleForState:UIControlStateNormal] sizeWithFont:self.moreButton.titleLabel.font];
    CGSize moreIconSize = self.moreIcon.image.size;

    CGRect moreButtonFrame = CGRectMake(self.view.frame.size.width - moreButtonSize.width - moreIconSize.width - whitespace,
            isIPad ? self.assigneeLabel.frame.origin.y : self.headerSeparator.frame.origin.y,
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

    // Document table
    CGFloat documentTableY = self.headerSeparator.frame.origin.y + self.headerSeparator.frame.size.height;
    if (!IS_IPAD)
    {
        documentTableY += self.moreBackgroundView.frame.size.height;
    }
    CGFloat availableHeight = self.view.frame.size.height - documentTableY - ((isIPad) ? FOOTER_HEIGHT_IPAD : FOOTER_HEIGHT_IPHONE);
    if (self.documentTable)
    {
        CGRect documentTableFrame = CGRectMake(0, documentTableY, self.view.frame.size.width, availableHeight);
        self.documentTable.frame = documentTableFrame;
    }

    if (self.noDocumentsImageView)
    {
        CGSize noDocumentsImageSize = self.noDocumentsImageView.image.size;
        CGFloat noDocumentsHeight = IS_IPAD ? (documentTableY + (availableHeight/2) - noDocumentsImageSize.height + 15.0) : (documentTableY + 40.0);
        CGRect noDocumentsImageFrame = CGRectMake((self.view.frame.size.width - noDocumentsImageSize.width) / 2,
                noDocumentsHeight,
                noDocumentsImageSize.width,
                noDocumentsImageSize.height);
        self.noDocumentsImageView.frame = noDocumentsImageFrame;

        self.noDocumentsLabel.frame = CGRectMake(0, noDocumentsImageFrame.origin.y + noDocumentsImageFrame.size.height,
                self.view.frame.size.width, 30);
    }

    // Panel at the bottom with buttons
    [self calculateFooterFrame];
}

- (void)calculateSubHeaderFrames
{
    if (IS_IPAD)
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
}

- (CGRect)calculateFooterFrame
{
    // Footer UIView
    CGFloat footerY = self.view.frame.size.height - ((IS_IPAD) ? FOOTER_HEIGHT_IPAD : FOOTER_HEIGHT_IPHONE);

    // If keyboard is shown, the comment text field (and buttons for ipad) float to just above the keyboard
    if (self.commentKeyboardShown)
    {
        CGRect properlyRotatedCoords = [[self.view superview] convertRect:self.keyboardFrame fromView:nil];
        footerY = footerY - properlyRotatedCoords.size.height;
        if (!IS_IPAD)
        {
             // On iphone, the tab bar is displayed at the bottom, which isn't the case on the ipad.
            footerY = footerY + 49; // 49pts = height of tabbar
        }
    }

    CGRect footerFrame = CGRectMake(0, footerY, self.view.frame.size.width, ((IS_IPAD) ? FOOTER_HEIGHT_IPAD : FOOTER_HEIGHT_IPHONE));
    self.footerView.frame = footerFrame;

    // Buttons
    self.buttonsSeparator.frame = CGRectMake((footerFrame.size.width - self.buttonsSeparator.image.size.width)/2,
            footerFrame.origin.y,
            self.buttonsSeparator.image.size.width,
            self.buttonsSeparator.image.size.height);

    CGFloat buttonMargin = (IS_IPAD) ? IPAD_BUTTON_MARGIN : IPHONE_BUTTON_MARGIN;
    CGRect dividerFrame = CGRectNull;

    // On the iPad, the reassign button is shown at the right bottom,
    // with a divider image left to it, to separate it from the transition buttons
    if (IS_IPAD)
    {
        CGSize buttonImageSize = [self.reassignButton backgroundImageForState:UIControlStateNormal].size;
        CGRect reassignButtonFrame = CGRectMake(footerFrame.size.width - buttonMargin - buttonImageSize.width,
                (footerFrame.size.height - buttonImageSize.height) / 2,
                buttonImageSize.width,  buttonImageSize.height);
        self.reassignButton.frame = reassignButtonFrame;

        CGSize dividerSize = self.buttonDivider.image.size;
        dividerFrame = CGRectMake(reassignButtonFrame.origin.x - buttonMargin - dividerSize.width,
                (footerFrame.size.height - dividerSize.height) / 2,
                dividerSize.width, dividerSize.height);
        self.buttonDivider.frame = dividerFrame;
    }

    // The 'approve' or 'done' buttons are placed as first from the right.
    // On the iPad however, there is already a reassign button + divider image
    UIButton *rightTransitionButton = (self.rejectButton) ? self.rejectButton : self.doneButton;
    CGSize buttonImageSize = [rightTransitionButton backgroundImageForState:UIControlStateNormal].size;
    CGRect rightTransitionFrame = CGRectMake(
            (IS_IPAD ? dividerFrame.origin.x : footerFrame.size.width)- buttonMargin - buttonImageSize.width,
            (footerFrame.size.height - buttonImageSize.height) / 2,
            buttonImageSize.width, buttonImageSize.height);
    rightTransitionButton.frame = rightTransitionFrame;

    // When the workflow is a 'review and approve' workflow, the reject button will have been created before
    if (self.approveButton)
    {
        buttonImageSize = [self.rejectButton backgroundImageForState:UIControlStateNormal].size;
        self.approveButton.frame = CGRectMake(rightTransitionFrame.origin.x - buttonMargin - buttonImageSize.width,
                (footerFrame.size.height - buttonImageSize.height) / 2,
                buttonImageSize.width, buttonImageSize.height);
    }

    // Comment text box on iPad
    UIButton *leftMostButton = (self.approveButton != nil) ? self.approveButton : rightTransitionButton;
    if (IS_IPAD)
    {
        CGRect commentTextFieldFrame = CGRectMake(2 * buttonMargin,
                leftMostButton.frame.origin.y,
                leftMostButton.frame.origin.x - (3 * buttonMargin),
                leftMostButton.frame.size.height);
        self.commentTextField.frame = commentTextFieldFrame;
    }
    // A comment icon on the iPhone
    else
    {
        self.commentTextField.frame = CGRectMake(2 * buttonMargin,
                    leftMostButton.frame.origin.y, footerFrame.size.width - 4 * buttonMargin, 32);
    }

    if (self.commentButton)
    {
        CGSize commentButtonImageSize = [self.commentButton imageForState:UIControlStateNormal].size;
        self.commentButton.frame = CGRectMake(20,
                (footerFrame.size.height - commentButtonImageSize.height) / 2,
                commentButtonImageSize.width, commentButtonImageSize.height);
    }

    return footerFrame;
}

#pragma mark - Instance methods

- (void)showTask
{
    // Task header
    self.taskNameLabel.text = self.taskItem.description;
    self.assigneeLabel.text = self.taskItem.ownerFullName;

    self.priorityLabel.text = [NSString stringWithFormat:@"%@ %@", self.taskItem.priority, NSLocalizedString(@"task.detail.priority", nil)];
    if (self.taskItem.priorityInt == 1)
    {
        self.priorityIcon.image = [UIImage imageNamed:@"HighPriorityHeader.png"];
    }
    else if (self.taskItem.priorityInt == 2)
    {
        self.priorityIcon.image = [UIImage imageNamed:@"MedPriorityHeader.png"];
    }
    else
    {
        self.priorityIcon.image = [UIImage imageNamed:@"LowPriorityHeader.png"];
    }

    switch (self.taskItem.workflowType)
    {
        case AlfrescoWorkflowTypeTodo:
            self.workflowNameLabel.text = NSLocalizedString(@"task.detail.workflow.todo", nil);
            break;
        case AlfrescoWorkflowTypeReview:
            self.workflowNameLabel.text = NSLocalizedString(@"task.detail.workflow.review.and.approve", nil);
            break;
    }

    // Due date
    if (self.taskItem.dueDate)
    {
        self.dueDateIconView.date = self.taskItem.dueDate;
    }

    // Size all labels according to text
    self.isTaskNameShortened = [self.taskNameLabel appendDotsIfTextDoesNotFit];
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
        displayErrorMessageWithTitle(request.error.localizedDescription, NSLocalizedString(@"connectionErrorMessage", nil));
    }];

    [self startHUD];
    self.HUD.labelText = NSLocalizedString(@"task.detail.completing", nil);

    [request startAsynchronous];
}

- (void)commentButtonTapped
{
    self.commentButton.hidden = YES;
    self.commentTextField.hidden = NO;

    [self hideTransitionButtons:YES];

    [self.commentTextField becomeFirstResponder];
}

- (void)moreButtonTapped
{
    self.moreDetailsShowing = !self.moreDetailsShowing;
    IS_IPAD ? [self handleMoreButtonTappedIpad] : [self handleMoreButtonTappedIphone];
}

- (void)handleMoreButtonTappedIpad
{
    // 'more' button becomes 'less' button and vice versa
    self.moreButton.selected = !self.moreButton.selected;

    if (self.moreButton.selected) // Expanding (ie showing more details)
    {
        [self createDetailViewForIpad];
        self.moreIcon.image = [UIImage imageNamed:@"triangleUp.png"];
    }
    else // Collapse (ie show less details)
    {
        self.moreIcon.image = [UIImage imageNamed:@"triangleDown.png"];
        [self.moreBackgroundView removeFromSuperview];;
        self.moreBackgroundView = nil;
    }
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
    UITextView *taskNameTextView = [[UITextView alloc] init];
    taskNameTextView.frame = self.taskNameLabel.frame;
    taskNameTextView.font = self.taskNameLabel.font;
    taskNameTextView.text = self.taskItem.description;
    taskNameTextView.contentInset = UIEdgeInsetsMake(-11,-8,0,0);
    taskNameTextView.editable = NO;
    self.taskNameTextView = taskNameTextView;
    [self.view addSubview:self.taskNameTextView];
    [taskNameTextView release];

    // Label can now be removed (no going back for iphone)
    [self.taskNameLabel removeFromSuperview];
    [self calculateDetailFramesForIphone];

    [UIView commitAnimations];
}

- (void)calculateDetailFramesForIphone
{
    // Size the text view, to maximum half of screen
    CGSize taskNameSize = [self.taskNameTextView.text sizeWithFont:self.taskNameTextView.font
                                        constrainedToSize:CGSizeMake(self.taskNameTextView.frame.size.width, CGFLOAT_MAX)];
    CGRect taskNameFrame =  CGRectMake(self.taskNameTextView.frame.origin.x,
            self.dueDateIconView.frame.origin.y + 5.0,
            self.view.frame.size.width - self.taskNameTextView.frame.origin.x - 10.0,
            MIN(taskNameSize.height, self.view.frame.size.height / 3));
    self.taskNameTextView.frame = taskNameFrame;

    // Details: priority, workflow type and assigne
    CGFloat taskNameBottomY = taskNameFrame.origin.y + taskNameFrame.size.height;
    CGFloat dueDateBottomY = self.dueDateIconView.frame.origin.y + self.dueDateIconView.frame.size.height;
    CGRect priorityIconFrame = CGRectMake(IPHONE_HEADER_MARGIN,
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
            [self.workflowNameLabel.text sizeWithFont:self.workflowNameLabel.font].width,
            priorityLabelFrame.size.height);
    self.workflowNameLabel.frame = workflowTypeFrame;

    CGRect assigneeIconFrame = CGRectMake(priorityIconFrame.origin.x,
            priorityIconFrame.origin.y + priorityIconFrame.size.height + 5,
            self.assigneeIcon.image.size.width, self.assigneeIcon.image.size.height);
    self.assigneeIcon.frame = assigneeIconFrame;

    CGRect assigneeLabelFrame = CGRectMake(assigneeIconFrame.origin.x + assigneeIconFrame.size.width + 5,
            assigneeIconFrame.origin.y,
            [self.assigneeLabel.text sizeWithFont:self.assigneeLabel.font].width,
            assigneeIconFrame.size.height);
    self.assigneeLabel.frame = assigneeLabelFrame;

    // Enlarge the background
    self.moreBackgroundView.frame = CGRectMake(0, 0, self.view.frame.size.width,
            assigneeLabelFrame.origin.y + assigneeLabelFrame.size.height + 5.0);
    [self.moreBackgroundView removeFromSuperview];
    [self.view insertSubview:self.moreBackgroundView belowSubview:self.dueDateIconView];

    // Move the divider
    self.headerSeparator.frame = CGRectMake(self.headerSeparator.frame.origin.x,
            self.moreBackgroundView.frame.origin.y + self.moreBackgroundView.frame.size.height,
            self.headerSeparator.frame.size.width, self.headerSeparator.frame.size.height);

    // Shrink the document table
    self.documentTable.frame = CGRectMake(self.documentTable.frame.origin.x,
            self.headerSeparator.frame.origin.y + self.headerSeparator.frame.size.height,
            self.documentTable.frame.size.width,
            self.documentTable.frame.size.height);
}

- (void)createDetailViewForIpad
{
    // the new content is placed on a 'floating' uiview
    UIView *moreBackgroundView = [[UIView alloc] init];
    moreBackgroundView.backgroundColor = [UIColor whiteColor];
    self.moreBackgroundView = moreBackgroundView;
    [self.view insertSubview:self.moreBackgroundView aboveSubview:((self.documentTable) ? self.documentTable : self.noDocumentsImageView)];
    [moreBackgroundView release];

    // Add Full description (if necessary)
    CGFloat x = self.dueDateIconView.frame.origin.x;
    CGFloat height = 0;
    if (self.isTaskNameShortened)
    {
        height = [self addDetailLabel:NSLocalizedString(@"task.detail.full.description", nil) fontSize:13 multiLine:NO x:x y:0];
        height = [self addDetailTextView:self.taskItem.description fontSize:15 x:x y:(height + 2.0)];
    }

    // Initiator
    height = [self addDetailLabel:NSLocalizedString(@"task.detail.initiator", nil) fontSize:13 multiLine:NO x:x y:(height + 5.0)];
    height = [self addDetailLabel:self.taskItem.initiatorFullName fontSize:15 multiLine:NO x:x y:(height + 1.0)];

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



#pragma mark UITextFieldDelegate: comment text field handling

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.commentButton)
    {
        self.commentButton.hidden = NO;
        self.commentTextField.hidden = YES;
    }

    [self hideTransitionButtons:NO];

    [textField resignFirstResponder];
    return YES;
}

- (void)hideTransitionButtons:(BOOL)hidden
{
    if (self.approveButton)
    {
        self.approveButton.hidden = hidden;
    }

    if (self.rejectButton)
    {
        self.rejectButton.hidden = hidden;
    }

    if (self.doneButton)
    {
        self.doneButton.hidden = hidden;
    }
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
        self.keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

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

    // Special care for 'more details'
    [self showDetailsIfNeeded];

}

- (void)showDetailsIfNeeded
{
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

// When the collapse/expand functionality (arrow button in left top) is used, the split view controller requests to re-layout the subviews.
// Hence, we can recalculate the subview frames by overriding this method.
//- (void)viewDidLayoutSubviews
//{
//    [super viewDidLayoutSubviews];
//    [self calculateSubViewFrames];
//}

@end
