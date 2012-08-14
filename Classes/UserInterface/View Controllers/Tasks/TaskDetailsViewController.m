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

#define HEADER_HEIGHT 40
#define HEADER_TITLE_MARGIN 10

@interface TaskDetailsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UILabel *taskNameLabel;
@property (nonatomic, retain) AsyncLoadingUIImageView *assigneeImageView;
@property (nonatomic, retain) DateIconView *dueDateIconView;
@property (nonatomic, retain) UITableView *documentTable;

@end

@implementation TaskDetailsViewController

@synthesize taskNameLabel = _taskNameLabel;
@synthesize assigneeImageView = _assigneeImageView;
@synthesize documentTable = _documentTable;
@synthesize taskItem = _taskItem;
@synthesize dueDateIconView = _dateIconView;




#pragma mark - View lifecycle

- (void)dealloc
{
    [_taskNameLabel release];
    [_assigneeImageView release];
    [_documentTable release];
    [_taskItem release];
    [_dateIconView release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    // Task detail header
    CGRect taskDetailsHeaderFrame = CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT);
    UIView *taskDetailsHeaderView = [[UIView alloc] initWithFrame:taskDetailsHeaderFrame];
    taskDetailsHeaderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    [self.view addSubview:taskDetailsHeaderView];
    [taskDetailsHeaderView release];

    CGRect taskDetailsHeaderTitleFrame = CGRectMake(HEADER_TITLE_MARGIN, taskDetailsHeaderFrame.origin.y,
            taskDetailsHeaderFrame.size.width - HEADER_TITLE_MARGIN, taskDetailsHeaderFrame.size.height);
    UILabel *taskDetailsHeaderTitle = [[UILabel alloc] initWithFrame:taskDetailsHeaderTitleFrame];
    taskDetailsHeaderTitle.backgroundColor = [UIColor clearColor];
    taskDetailsHeaderTitle.textColor = [UIColor whiteColor];
    taskDetailsHeaderTitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    taskDetailsHeaderTitle.text = @"Task details";
    [self.view addSubview:taskDetailsHeaderTitle];
    [taskDetailsHeaderTitle release];

    // Task name
    CGRect taskNameFrame = CGRectMake(20, taskDetailsHeaderView.frame.origin.y + taskDetailsHeaderView.frame.size.height + 10,
    self.view.frame.size.width / 2, 100);
    UILabel *taskNameLabel = [[UILabel alloc] initWithFrame:taskNameFrame];
    taskNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    taskNameLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.taskNameLabel = taskNameLabel;
    [self.view addSubview:self.taskNameLabel];
    [taskNameLabel release];

    // Task assignee
    CGFloat assigneeImageSize = 60;
    CGRect assigneeFrame = CGRectMake(taskNameFrame.origin.x + taskNameFrame.size.width + 20,
            taskNameFrame.origin.y + taskNameFrame.size.height/2 - assigneeImageSize/2, assigneeImageSize, assigneeImageSize);
    AsyncLoadingUIImageView *assigneeImageView = [[AsyncLoadingUIImageView alloc] initWithFrame:assigneeFrame];
    [assigneeImageView setContentMode:UIViewContentModeScaleToFill];
    [assigneeImageView.layer setMasksToBounds:YES];
    [assigneeImageView.layer setCornerRadius:10];
    assigneeImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    assigneeImageView.layer.borderWidth = 1.0;
    self.assigneeImageView = assigneeImageView;
    [self.view addSubview:self.assigneeImageView];
    [assigneeImageView release];

    // Due date
    CGRect dueDateFrame = CGRectMake(assigneeFrame.origin.x + assigneeFrame.size.width + 30,
           assigneeFrame.origin.y, assigneeImageSize, assigneeImageSize);
    DateIconView *dateIconView = [[DateIconView alloc] initWithFrame:dueDateFrame];
    self.dueDateIconView = dateIconView;
    [self.view addSubview:self.dueDateIconView];
    [dateIconView release];

    // Document detail header
    CGRect documentHeaderFrame = CGRectMake(0, taskNameFrame.origin.y + taskNameFrame.size.height + 10,
            self.view.frame.size.width, taskDetailsHeaderFrame.size.height);
    UIView *documentHeaderView = [[UIView alloc] initWithFrame:documentHeaderFrame];
    documentHeaderView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
    [self.view addSubview:documentHeaderView];
    [documentHeaderView release];

    CGRect documentHeaderTitleFrame = CGRectMake(HEADER_TITLE_MARGIN, documentHeaderFrame.origin.y,
            documentHeaderFrame.size.width - HEADER_TITLE_MARGIN, documentHeaderFrame.size.height);
    UILabel *documentHeaderTitle = [[UILabel alloc] initWithFrame:documentHeaderTitleFrame];
    documentHeaderTitle.backgroundColor = [UIColor clearColor];
    documentHeaderTitle.textColor = [UIColor whiteColor];
    documentHeaderTitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    documentHeaderTitle.text = @"Documents";
    [self.view addSubview:documentHeaderTitle];
    [documentHeaderTitle release];

    // Document table
    CGRect documentTableFrame = CGRectMake(0, documentHeaderFrame.origin.y + documentHeaderFrame.size.height + 10,
            self.view.frame.size.width, self.view.frame.size.height - documentHeaderFrame.origin.y);
    UITableView *documentTableView = [[UITableView alloc] initWithFrame:documentTableFrame];
    documentTableView.delegate = self;
    documentTableView.dataSource = self;
    self.documentTable = documentTableView;
    [documentTableView release];

    // Show and load task task details
    [self showTask];
}

#pragma mark Instance methods

- (void)showTask
{
    self.taskNameLabel.text = self.taskItem.title;

    // Set url for async loading assignee avatar picture
    AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
            httpRequestAvatarForUserName:self.taskItem.ownerUserName
                             accountUUID:self.taskItem.accountUUID
                                tenantID:self.taskItem.tenantId];
    [self.assigneeImageView setImageWithRequest:avatarHTTPRequest];

    // Due date
    if (self.taskItem.dueDate)
    {
        self.dueDateIconView.date = self.taskItem.dueDate;
    } else
    {
        self.dueDateIconView.hidden = YES;
    }
}

#pragma mark UITableView delegate methods (document table)

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


@end
