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
//  SelectTaskTypeViewController.m
//

#import "SelectTaskTypeViewController.h"
#import "AddTaskViewController.h"
#import "Theme.h"

@interface SelectTaskTypeViewController ()

@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;

@end

@implementation SelectTaskTypeViewController

@synthesize addTaskDelegate = _addTaskDelegate;
@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [super initWithStyle:style];
    if (self) {
        self.accountUuid = uuid;
        self.tenantID = tenantID;
    }
    return self;
}

- (void)dealloc
{
    [_accountUuid release];
    [_tenantID release];
    [super dealloc]; 
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUITableViewController:self];
    [self setTitle:NSLocalizedString(@"task.choose.tasktype.title", nil)];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancel:)] autorelease]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (indexPath.section == 0)
    {
        cell.textLabel.text = @"Todo";
    }
    else 
    {
        cell.textLabel.text = @"Review";
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoWorkflowType workflowType;
    if (indexPath.section == 0)
    {
        workflowType = WORKFLOW_TYPE_TODO;
    }
    else 
    {
        workflowType = WORKFLOW_TYPE_REVIEW;
    }
    
    AddTaskViewController *taskController = [[AddTaskViewController alloc] initWithStyle:UITableViewStyleGrouped account:self.accountUuid 
                                                         tenantID:self.tenantID workflowType:workflowType];
    taskController.addTaskDelegate = self.addTaskDelegate;
    
    [self.navigationController pushViewController:taskController animated:YES];
    [taskController release];
}

@end
