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
#import "UILabel+Utils.h"
#import "Utility.h"
#import "MBProgressHUD.h"
#import "DownloadProgressBar.h"
#import "ObjectByIdRequest.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"
#import "PeoplePickerViewController.h"
#import "TaskManager.h"
#import "ASIHTTPRequest.h"
#import "BarButtonBadge.h"
#import "TaskTakeTransitionHTTPRequest.h"
#import "NSNotificationCenter+CustomNotification.h"

#define HEADER_HEIGHT_IPAD 40.0
#define HEADER_HEIGHT_IPHONE 20.0
#define HEADER_TITLE_MARGIN 10.0
#define TASK_NAME_HEIGHT_IPAD 100.0
#define TASK_NAME_HEIGHT_IPHONE 60.0
#define DOCUMENT_CELL_HEIGHT 120.0
#define FOOTER_HEIGHT 80.0
#define BUTTON_MARGIN 10.0

#define TITLE_FONT_SIZE_IPAD 20
#define TITLE_FONT_SIZE_IPHONE 16
#define TEXT_FONT_SIZE_IPAD 18
#define TEXT_FONT_SIZE_IPHONE 16

@interface TaskDetailsViewController () <UITableViewDataSource, UITableViewDelegate, DownloadProgressBarDelegate, PeoplePickerDelegate, ASIHTTPRequestDelegate>

// Header
@property (nonatomic, retain) UIView *taskDetailsHeaderView;
@property (nonatomic, retain) UILabel *taskDetailsHeaderTitle;
@property (nonatomic, retain) UILabel *taskNameLabel;
@property (nonatomic, retain) AsyncLoadingUIImageView *assigneeImageView;
@property (nonatomic, retain) DateIconView *dueDateIconView;

// Documents
@property (nonatomic, retain) UIView *documentHeaderView;
@property (nonatomic, retain) UILabel *documentHeaderTitle;
@property (nonatomic, retain) UITableView *documentTable;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;
@property (nonatomic, retain) ObjectByIdRequest *objectByIdRequest;

// Buttons
@property (nonatomic, retain) UIView *buttonsBackgroundView;
@property (nonatomic, retain) UIImageView *buttonsSeparator;
@property (nonatomic, retain) UIButton *rejectButton;
@property (nonatomic, retain) UIButton *approveButton;
@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, retain) UIImageView *buttonDivider;
@property (nonatomic, retain) UIButton *reassignButton;

- (void)startObjectByIdRequest:(NSString *)objectId;
- (void)startHUD;
- (void)stopHUD;

@end

@implementation TaskDetailsViewController

@synthesize taskNameLabel = _taskNameLabel;
@synthesize assigneeImageView = _assigneeImageView;
@synthesize documentTable = _documentTable;
@synthesize taskItem = _taskItem;
@synthesize dueDateIconView = _dateIconView;
@synthesize taskDetailsHeaderView = _taskDetailsHeaderView;
@synthesize taskDetailsHeaderTitle = _taskDetailsHeaderTitle;
@synthesize documentHeaderView = _documentHeaderView;
@synthesize documentHeaderTitle = _documentHeaderTitle;
@synthesize HUD = _HUD;
@synthesize downloadProgressBar = _downloadProgressBar;
@synthesize objectByIdRequest = _objectByIdRequest;
@synthesize buttonsBackgroundView = _buttonsBackgroundView;
@synthesize rejectButton = _rejectButton;
@synthesize approveButton = _approveButton;
@synthesize reassignButton = _reassignButton;
@synthesize buttonsSeparator = _buttonsSeparator;
@synthesize doneButton = _doneButton;
@synthesize buttonDivider = _buttonDivider;




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
    [_objectByIdRequest clearDelegatesAndCancel];
    
    [_HUD release];
    [_objectByIdRequest release];
    [_downloadProgressBar release];
    
    [_taskNameLabel release];
    [_assigneeImageView release];
    [_documentTable release];
    [_taskItem release];
    [_dateIconView release];
    [_taskDetailsHeaderView release];
    [_taskDetailsHeaderTitle release];
    [_documentHeaderView release];
    [_documentHeaderTitle release];
    [_buttonsBackgroundView release];
    [_rejectButton release];
    [_approveButton release];
    [_reassignButton release];
    [_buttonsSeparator release];
    [_doneButton release];
    [_buttonDivider release];
    [super dealloc];
}

// I'd rather do this in viewDidLoad, but viewDidAppear is the only place where the view frame is correct.
// See very good explanation at http://stackoverflow.com/questions/6757018/why-am-i-having-to-manually-set-my-views-frame-in-viewdidload
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.view.backgroundColor = [UIColor whiteColor];

    [self createTaskDetailsHeader];
    [self createTaskNameLabel];
    [self createAssigneeView];
    [self createDueDateView];
    [self createDocumentHeader];
    [self createDocumentTable];
    [self createTransitionButtons];

    // Calculate frames of all components
    [self calculateSubViewFrames];

    // Show and load task task details
    [self showTask];
}

#pragma mark - SubView creation

- (void)createTaskDetailsHeader
{
    UIView *taskDetailsHeaderView = [[UIView alloc] init];
    taskDetailsHeaderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    self.taskDetailsHeaderView = taskDetailsHeaderView;
    [self.view addSubview:self.taskDetailsHeaderView];
    [taskDetailsHeaderView release];

    UILabel *taskDetailsHeaderTitle = [[UILabel alloc] init];
    taskDetailsHeaderTitle.backgroundColor = [UIColor clearColor];
    taskDetailsHeaderTitle.textColor = [UIColor whiteColor];
    taskDetailsHeaderTitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(IS_IPAD ? TITLE_FONT_SIZE_IPAD : TITLE_FONT_SIZE_IPHONE)];
    taskDetailsHeaderTitle.text = NSLocalizedString(@"task.details.header", nil);
    self.taskDetailsHeaderTitle = taskDetailsHeaderTitle;
    [self.view addSubview:self.taskDetailsHeaderTitle];
    [taskDetailsHeaderTitle release];
}

- (void)createTaskNameLabel
{
    UILabel *taskNameLabel = [[UILabel alloc] init];
    taskNameLabel.lineBreakMode = UILineBreakModeWordWrap;
    taskNameLabel.numberOfLines = 0;
    self.taskNameLabel = taskNameLabel;
    [self.view addSubview:self.taskNameLabel];
    [taskNameLabel release];
}

- (void)createAssigneeView
{
    AsyncLoadingUIImageView *assigneeImageView = [[AsyncLoadingUIImageView alloc] init];
    [assigneeImageView setContentMode:UIViewContentModeScaleToFill];
    [assigneeImageView.layer setMasksToBounds:YES];
    [assigneeImageView.layer setCornerRadius:10];
    assigneeImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    assigneeImageView.layer.borderWidth = 1.0;
    self.assigneeImageView = assigneeImageView;
    [self.view addSubview:self.assigneeImageView];
    [assigneeImageView release];
}

- (void)createDueDateView
{
    DateIconView *dateIconView = [[DateIconView alloc] init];
    self.dueDateIconView = dateIconView;
    [self.view addSubview:self.dueDateIconView];
    [dateIconView release];
}

- (void)createDocumentHeader
{
    UIView *documentHeaderView = [[UIView alloc] init];
    documentHeaderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    self.documentHeaderView = documentHeaderView;
    [self.view addSubview:self.documentHeaderView];
    [documentHeaderView release];

    UILabel *documentHeaderTitle = [[UILabel alloc] init];
    documentHeaderTitle.backgroundColor = [UIColor clearColor];
    documentHeaderTitle.textColor = [UIColor whiteColor];
    documentHeaderTitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(IS_IPAD ? TITLE_FONT_SIZE_IPAD : TITLE_FONT_SIZE_IPHONE)];
    documentHeaderTitle.text = NSLocalizedString(@"task.detail.document", nil);
    self.documentHeaderTitle = documentHeaderTitle;
    [self.view addSubview:self.documentHeaderTitle];
    [documentHeaderTitle release];
}

- (void)createDocumentTable
{
    UITableView *documentTableView = [[UITableView alloc] init];
    documentTableView.delegate = self;
    documentTableView.dataSource = self;
    documentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.documentTable = documentTableView;
    [self.view addSubview:self.documentTable];
    [documentTableView release];
}

- (void)createTransitionButtons
{
    // Background
    UIView *buttonsBackground = [[UIView alloc] init];
    buttonsBackground.backgroundColor = [UIColor whiteColor];
    buttonsBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    self.buttonsBackgroundView = buttonsBackground;
    [buttonsBackground release];
    [self.view addSubview:self.buttonsBackgroundView];

    // Gray line above buttons
    UIImageView *separator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"taskDetailsHorizonalLine.png"]];
    self.buttonsSeparator = separator;
    [separator release];
    [self.view addSubview:self.buttonsSeparator];

    // Comment box

    // Transition buttons
    if (self.taskItem.taskType == TASK_TYPE_REVIEW)
    {
        UIButton *rejectButton = [self taskButtonWithTitle:NSLocalizedString(@"task.detail.reject.button", nil)
                                                     image:@"RejectButton.png" action:@selector(transitionButtonTapped:)];
        self.rejectButton = rejectButton;
        [rejectButton release];
        [self.view addSubview:self.rejectButton];

        UIButton *approveButton = [self taskButtonWithTitle:NSLocalizedString(@"task.detail.approve.button", nil)
                                                      image:@"ApproveButton.png" action:@selector(transitionButtonTapped:)];
        self.approveButton = approveButton;
        [approveButton release];
        [self.view addSubview:self.approveButton];
    }
    else
    {
        UIButton *doneButton = [self taskButtonWithTitle:NSLocalizedString(@"task.detail.done.button", nil)
                                                   image:@"ApproveButton.png" action:@selector(transitionButtonTapped:)];
        self.doneButton = doneButton;
        [doneButton release];
        [self.view addSubview:self.doneButton];
    }

    // Divider between buttons
    UIImageView *dividerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"buttonDivide.png"]];
    self.buttonDivider = dividerImage;
    [dividerImage release];
    [self.view addSubview:self.buttonDivider];

    // Reassign button
    UIButton *reassignButton = [self taskButtonWithTitle:NSLocalizedString(@"task.detail.reassign.button", nil)
                                                       image:@"ReassignButton.png" action:@selector(reassignButtonTapped:)];
    [reassignButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.reassignButton = reassignButton;
    [reassignButton release];
    [self.view addSubview:self.reassignButton];
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
    CGRect taskDetailsHeaderFrame = CGRectMake(0, 0, self.view.frame.size.width, (IS_IPAD ? HEADER_HEIGHT_IPAD : HEADER_HEIGHT_IPHONE));
    self.taskDetailsHeaderView.frame = taskDetailsHeaderFrame;

    CGRect taskDetailsHeaderTitleFrame = CGRectMake(HEADER_TITLE_MARGIN, taskDetailsHeaderFrame.origin.y,
            taskDetailsHeaderFrame.size.width - HEADER_TITLE_MARGIN,  taskDetailsHeaderFrame.size.height);
    self.taskDetailsHeaderTitle.frame = taskDetailsHeaderTitleFrame;

    CGRect taskNameFrame = CGRectMake(20, taskDetailsHeaderFrame.origin.y + taskDetailsHeaderFrame.size.height + 10,
            self.view.frame.size.width / 2, IS_IPAD ? TASK_NAME_HEIGHT_IPAD : TASK_NAME_HEIGHT_IPHONE);
    self.taskNameLabel.frame = taskNameFrame;

    CGFloat assigneeImageSize = 60;
    CGRect assigneeFrame = CGRectMake( (IS_IPAD ? self.view.frame.size.width - 3 * assigneeImageSize
                                                : self.view.frame.size.width - 2 * assigneeImageSize - 20) ,
                taskNameFrame.origin.y + taskNameFrame.size.height/2 - assigneeImageSize/2,
                assigneeImageSize, assigneeImageSize);
    self.assigneeImageView.frame = assigneeFrame;

    CGRect dueDateFrame = CGRectMake(assigneeFrame.origin.x + assigneeFrame.size.width + (IS_IPAD ? assigneeImageSize/2 : 10),
            assigneeFrame.origin.y,  assigneeImageSize, assigneeImageSize);
    self.dueDateIconView.frame = dueDateFrame;

    // Document detail header
    CGRect documentHeaderFrame = CGRectMake(0, taskNameFrame.origin.y + taskNameFrame.size.height + 10,
            self.view.frame.size.width, taskDetailsHeaderFrame.size.height);
    self.documentHeaderView.frame = documentHeaderFrame;

    CGRect documentHeaderTitleFrame = CGRectMake(HEADER_TITLE_MARGIN, documentHeaderFrame.origin.y,
            documentHeaderFrame.size.width - HEADER_TITLE_MARGIN, documentHeaderFrame.size.height);
    self.documentHeaderTitle.frame = documentHeaderTitleFrame;

    // Document table
    CGRect documentTableFrame = CGRectMake(0,
            documentHeaderFrame.origin.y + documentHeaderFrame.size.height, self.view.frame.size.width,
            self.view.frame.size.height - documentHeaderFrame.origin.y - documentHeaderFrame.size.height - FOOTER_HEIGHT);
    self.documentTable.frame = documentTableFrame;

    // Panel at the bottom with buttons
    CGRect footerFrame = CGRectMake(0, documentTableFrame.origin.y + documentTableFrame.size.height,
            self.view.frame.size.width, FOOTER_HEIGHT);
    self.buttonsBackgroundView.frame = footerFrame;

    self.buttonsSeparator.frame = CGRectMake((footerFrame.size.width - self.buttonsSeparator.image.size.width)/2,
            footerFrame.origin.y, self.buttonsSeparator.image.size.width, self.buttonsSeparator.image.size.height);

    CGSize buttonImageSize = [self.reassignButton backgroundImageForState:UIControlStateNormal].size;
    CGRect reassignButtonFrame = CGRectMake(footerFrame.size.width - BUTTON_MARGIN - buttonImageSize.width,
            footerFrame.origin.y + (footerFrame.size.height - buttonImageSize.height) / 2, buttonImageSize.width, buttonImageSize.height);
    self.reassignButton.frame = reassignButtonFrame;

    CGSize dividerSize = self.buttonDivider.image.size;
    CGRect dividerFrame = CGRectMake(reassignButtonFrame.origin.x - BUTTON_MARGIN - dividerSize.width,
            footerFrame.origin.y + (footerFrame.size.height - dividerSize.height) / 2, dividerSize.width, dividerSize.height);
    self.buttonDivider.frame = dividerFrame;

    UIButton *happyPathButton = (self.approveButton != nil) ? self.approveButton : self.doneButton;
    buttonImageSize = [happyPathButton backgroundImageForState:UIControlStateNormal].size;
    CGRect happyPathButtonFrame = CGRectMake(dividerFrame.origin.x - BUTTON_MARGIN - buttonImageSize.width,
            footerFrame.origin.y + (footerFrame.size.height - buttonImageSize.height) / 2, buttonImageSize.width, buttonImageSize.height);
    happyPathButton.frame = happyPathButtonFrame;

    if (self.rejectButton)
    {
        buttonImageSize = [self.rejectButton backgroundImageForState:UIControlStateNormal].size;
        self.rejectButton.frame = CGRectMake(happyPathButtonFrame.origin.x - BUTTON_MARGIN - buttonImageSize.width,
                    footerFrame.origin.y + (footerFrame.size.height - buttonImageSize.height) / 2, buttonImageSize.width, buttonImageSize.height);
    }

}

#pragma mark - Instance methods

- (void)showTask
{
    // Task name
    self.taskNameLabel.text = self.taskItem.description;
    [self.taskNameLabel fitTextToLabelUsingFont:@"HelveticaNeue-Light"
                                defaultFontSize:(IS_IPAD ? TEXT_FONT_SIZE_IPAD : TEXT_FONT_SIZE_IPHONE)
                                    minFontSize:8];

    // Set url for async loading of assignee avatar picture
    AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
            httpRequestAvatarForUserName:self.taskItem.ownerUserName
                             accountUUID:self.taskItem.accountUUID
                                tenantID:self.taskItem.tenantId];
    avatarHTTPRequest.secondsToCache = 86400; // a day
    avatarHTTPRequest.downloadCache = [ASIDownloadCache sharedCache];
    [avatarHTTPRequest setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [self.assigneeImageView setImageWithRequest:avatarHTTPRequest];

    // Due date
    if (self.taskItem.dueDate)
    {
        self.dueDateIconView.date = self.taskItem.dueDate;
    }
    else
    {
        self.dueDateIconView.hidden = YES;
    }
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

    TaskTakeTransitionHTTPRequest *request = [TaskTakeTransitionHTTPRequest taskTakeTransitionRequestForTask:self.taskItem
                                        outcome:outcome accountUUID:self.taskItem.accountUUID tenantID:self.taskItem.tenantId];
    [request setCompletionBlock:^ {
        [self stopHUD];

        // The table view will listen to the following notifications and update itself
        [[NSNotificationCenter defaultCenter] postTaskCompletedNotificationWithUserInfo:
                [NSDictionary dictionaryWithObject:self.taskItem.taskId forKey:@"taskId"]];
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

- (void)requestFinished:(ASIHTTPRequest *)request
{
    AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
                                            httpRequestAvatarForUserName:self.taskItem.ownerUserName
                                            accountUUID:self.taskItem.accountUUID
                                            tenantID:self.taskItem.tenantId];
    avatarHTTPRequest.secondsToCache = 86400; // a day
    avatarHTTPRequest.downloadCache = [ASIDownloadCache sharedCache];
    [avatarHTTPRequest setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [self.assigneeImageView setImageWithRequest:avatarHTTPRequest];
    
    self.HUD.labelText = NSLocalizedString(@"task.assignee.updated", nil);
    [self.HUD hide:YES afterDelay:0.5];
}

#pragma mark - Document download

- (void)startObjectByIdRequest:(NSString *)objectId
{
    self.objectByIdRequest = [ObjectByIdRequest defaultObjectById:objectId 
                                                      accountUUID:self.taskItem.accountUUID 
                                                         tenantID:self.taskItem.tenantId];
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

#pragma mark - UITableView delegate methods (document table)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.taskItem.documentItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TaskDocumentViewCell * cell = (TaskDocumentViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[TaskDocumentViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    DocumentItem *documentItem = [self.taskItem.documentItems objectAtIndex:indexPath.row];
    cell.nameLabel.text = documentItem.name;
    cell.nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(IS_IPAD ? TEXT_FONT_SIZE_IPAD : TEXT_FONT_SIZE_IPHONE)];

    cell.thumbnailImageView.image = nil; // Need to set it to nil. Otherwise if cell was cached, the old image is seen for a brief moment
    NodeThumbnailHTTPRequest *request = [NodeThumbnailHTTPRequest httpRequestNodeThumbnail:documentItem.nodeRef
                                                                               accountUUID:self.taskItem.accountUUID
                                                                                  tenantID:self.taskItem.tenantId];
    request.secondsToCache = 3600;
    request.downloadCache = [ASIDownloadCache sharedCache];
    [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
    [cell.thumbnailImageView setImageWithRequest:request];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return DOCUMENT_CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DocumentItem *documentItem = [self.taskItem.documentItems objectAtIndex:indexPath.row];
    [self startObjectByIdRequest:documentItem.nodeRef];
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

// When the collapse/expand functionality is used, the split view controller requests to re-layout the subviews.
// Hence, we can recalculate the subview frames by overriding this method.
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self calculateSubViewFrames];
}


@end
