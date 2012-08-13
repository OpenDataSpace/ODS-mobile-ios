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

@interface TaskDetailsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UILabel *taskNameLabel;
@property (nonatomic, retain) AsyncLoadingUIImageView *assigneeImageView;
@property (nonatomic, retain) UITableView *documentTable;

@end

@implementation TaskDetailsViewController

@synthesize taskNameLabel = _taskNameLabel;
@synthesize assigneeImageView = _assigneeImageView;
@synthesize documentTable = _documentTable;


#pragma mark - View lifecycle

- (void)dealloc
{
    [_taskNameLabel release];
    [_assigneeImageView release];
    [_documentTable release];
    [super dealloc];
}

- (void)loadView
{
    self.view.backgroundColor = [UIColor whiteColor];

    // Task detail header
    CGRect taskDetailsHeaderFrame = CGRectMake(0, 0, self.view.frame.size.width, 20);
    UIView *taskDetailsHeaderView = [[UIView alloc] initWithFrame:taskDetailsHeaderFrame];
    taskDetailsHeaderView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:taskDetailsHeaderView];
    [taskDetailsHeaderView release];

    UILabel *taskDetailsHeaderTitle = [[UILabel alloc] initWithFrame:taskDetailsHeaderFrame];
    taskDetailsHeaderTitle.backgroundColor = [UIColor clearColor];
    taskDetailsHeaderTitle.textColor = [UIColor whiteColor];
    taskDetailsHeaderTitle.text = @"Task details";
    [self.view addSubview:taskDetailsHeaderTitle];
    [taskDetailsHeaderTitle release];

    // Task name
    CGRect taskNameFrame = CGRectMake(20, taskDetailsHeaderView.frame.origin.y + taskDetailsHeaderView.frame.size.height + 10,
    self.view.frame.size.width / 2, 100);
    UILabel *taskNameLabel = [[UILabel alloc] initWithFrame:taskNameFrame];
    self.taskNameLabel = taskNameLabel;
    [self.view addSubview:self.taskNameLabel];
    [taskNameLabel release];

    // Task assignee
    CGRect assigneeFrame = CGRectMake(taskNameFrame.origin.x + taskNameFrame.size.width + 20, taskNameFrame.origin.y, 60, 60);
    AsyncLoadingUIImageView *assigneeImageView = [[AsyncLoadingUIImageView alloc] initWithFrame:assigneeFrame];
    [assigneeImageView setContentMode:UIViewContentModeScaleToFill];
    [assigneeImageView.layer setMasksToBounds:YES];
    [assigneeImageView.layer setCornerRadius:10];
    self.assigneeImageView = assigneeImageView;
    [assigneeImageView release];

    // Document detail header
    CGRect documentHeaderFrame = CGRectMake(0, taskNameFrame.origin.y + taskNameFrame.size.height + 10,
            self.view.frame.size.width, taskDetailsHeaderFrame.size.height);
    UIView *documentHeaderView = [[UIView alloc] initWithFrame:documentHeaderFrame];
    documentHeaderView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:documentHeaderView];
    [documentHeaderView release];

    UILabel *documentHeaderTitle = [[UILabel alloc] initWithFrame:documentHeaderFrame];
    documentHeaderTitle.backgroundColor = [UIColor clearColor];
    documentHeaderTitle.textColor = [UIColor whiteColor];
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

}

#pragma mark Instance methods

- (void)showTask:(TaskItem *)task
{
        // Set url for async loading assignee avatar picture
    // TODO: set params!
    AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest httpRequestAvatarForUserName:nil accountUUID:nil tenantID:nil];
    [self.assigneeImageView setImageWithRequest:avatarHTTPRequest];
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
