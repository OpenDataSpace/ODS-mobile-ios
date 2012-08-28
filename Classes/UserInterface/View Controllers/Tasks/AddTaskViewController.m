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
//  AddTaskViewController.m
//

#import "AddTaskViewController.h"
#import "Theme.h"
#import "DocumentPickerViewController.h"
#import "DocumentPickerSelection.h"
#import "DatePickerViewController.h"
#import "PeoplePickerViewController.h"
#import "TaskManager.h"
#import "TaskAttachmentsViewController.h"

@interface AddTaskViewController () <DocumentPickerViewControllerDelegate, DatePickerDelegate, PeoplePickerDelegate>

@property (nonatomic, retain) NSDate *dueDate;
@property (nonatomic, retain) Person *assignee;
@property (nonatomic, retain) NSMutableArray *attachments;
@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic) AlfrescoTaskType taskType;

@property (nonatomic, retain) DocumentPickerViewController *documentPickerViewController;

@end

@implementation AddTaskViewController

@synthesize documentPickerViewController = _documentPickerViewController;
@synthesize dueDate = _dueDate;
@synthesize assignee = _assignee;
@synthesize attachments = _attachments;


- (void)dealloc
{
    [_documentPickerViewController release];
    [_dueDate release];
    [_assignee release];
    [_attachments release];
    [_accountUuid release];
    [_tenantID release];
    [super dealloc];
}
@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;
@synthesize taskType = _taskType;

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid tenantID:(NSString *)tenantID taskType:(AlfrescoTaskType)taskType
{
    self = [super initWithStyle:style];
    if (self) {
        self.accountUuid = uuid;
        self.tenantID = tenantID;
        self.taskType = taskType;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [Theme setThemeForUITableViewController:self];
    self.navigationItem.title = NSLocalizedString(@"task.create.title", nil);
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancelEdit:)] autorelease]];
    
    UIBarButtonItem *createButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(createTask:)] autorelease];
    [createButton setTitle:NSLocalizedString(@"task.create.button", nil)];
    [self.navigationItem setRightBarButtonItem:createButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // When navigation controller is popped to this controller, reload the data to reflect any changes
    [self.tableView reloadData];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)createTask:(id)sender
{
    TaskItem *task = [[[TaskItem alloc] init] autorelease];
    UITableViewCell *titleCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITextField *titleField = (UITextField *) [titleCell viewWithTag:101];
    task.title = titleField.text;
    task.ownerUserName = self.assignee.userName;
    task.taskType = self.taskType;
    [[TaskManager sharedManager] startTaskCreateRequestForTask:task accountUUID:self.accountUuid tenantID:self.tenantID];
    //[self dismissModalViewControllerAnimated:YES];
}

- (void)cancelEdit:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedString(@"task.create.taskTitle", nil);
        UITextField *titleField = [[UITextField alloc] init];
        if (IS_IPAD)
        {
            titleField.frame = CGRectMake(150, 12, 300, 30);
        }
        else 
        {
            titleField.frame = CGRectMake(100, 12, 205, 30);
        }
        titleField.placeholder = NSLocalizedString(@"task.create.taskTitle.placeholder", nil);
        titleField.autocorrectionType = UITextAutocorrectionTypeNo;  
        titleField.autocapitalizationType = UITextAutocapitalizationTypeSentences; 
        titleField.adjustsFontSizeToFitWidth = YES;
        titleField.tag = 101;
        [cell addSubview:titleField];
        [titleField release];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = NSLocalizedString(@"task.create.duedate", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (self.dueDate)
        {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateStyle = NSDateFormatterMediumStyle;
            cell.detailTextLabel.text = [df stringFromDate:self.dueDate];
            [df release];
        }
        else
        {
            cell.detailTextLabel.text = NSLocalizedString(@"task.create.duedate.placeholder", nil);
        }
    }
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = NSLocalizedString(@"task.create.assignee", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (self.assignee)
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", self.assignee.firstName, self.assignee.lastName];
        }
        else
        {
            cell.detailTextLabel.text = NSLocalizedString(@"task.create.assignee.placeholder", nil);
        }
    }
    else if (indexPath.row == 3)
    {
        cell.textLabel.text = NSLocalizedString(@"task.create.attachments", nil);
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (self.attachments != nil && self.attachments.count > 0)
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %@", self.attachments.count,
                      (self.attachments.count > 1) ? [NSLocalizedString(@"task.create.attachments", nil) lowercaseString]
                                                   : [NSLocalizedString(@"task.create.attachment", nil) lowercaseString]];
        }
        else
        {
            cell.detailTextLabel.text = NSLocalizedString(@"task.create.attachments.placeholder", nil);
        }
    }
    else if (indexPath.row == 4)
    {
        cell.textLabel.text = NSLocalizedString(@"task.create.priority", nil);
        NSArray *itemArray = [NSArray arrayWithObjects:NSLocalizedString(@"task.create.priority.high", nil),
                                                       NSLocalizedString(@"task.create.priority.medium", nil),
                                                       NSLocalizedString(@"task.create.priority.low", nil), nil];
        UISegmentedControl *priorityControl = [[UISegmentedControl alloc] initWithItems:itemArray];
        if (IS_IPAD)
        {
            priorityControl.frame = CGRectMake(248, 7, 250, 30);
        }
        else 
        {
            priorityControl.frame = CGRectMake(100, 6, 205, 30);
            [priorityControl setWidth:85.0 forSegmentAtIndex:1];
        }
        priorityControl.segmentedControlStyle = UISegmentedControlStylePlain;
        priorityControl.selectedSegmentIndex = 1;
        [cell addSubview:priorityControl];
        [priorityControl release];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1)
    {
        DatePickerViewController *datePicker = [[DatePickerViewController alloc] initWithNSDate:self.dueDate];
        datePicker.delegate = self;
        datePicker.title = NSLocalizedString(@"task.create.date.picker.title", nil);
        [self.navigationController pushViewController:datePicker animated:YES];
        [datePicker release];
    }
    else if (indexPath.row == 2)
    {
        PeoplePickerViewController *peoplePicker = [[PeoplePickerViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                             account:self.accountUuid tenantID:self.tenantID];
        peoplePicker.delegate = self;
        [self.navigationController pushViewController:peoplePicker animated:YES];
        [peoplePicker release];
    }
    else if (indexPath.row == 3)
    {
        // Instantiate document picker if it doesn't exist yet.
        if (!self.documentPickerViewController)
        {
            DocumentPickerViewController *documentPicker = [DocumentPickerViewController documentPicker];
            documentPicker.selection.selectiontextPrefix = NSLocalizedString(@"document.picker.selection.button.attach", nil);
            documentPicker.delegate = self;

            self.documentPickerViewController = documentPicker;
        }

        // Show document picker directly if no attachment are already chosen
        if (self.attachments == nil || self.attachments.count == 0)
        {
            [self.documentPickerViewController reopenAtLastLocationWithNavigationController:self.navigationController];
        }
        else // Show the attachment overview controller otherwise
        {
            TaskAttachmentsViewController *taskAttachmentsViewController = [[TaskAttachmentsViewController alloc] init];
            taskAttachmentsViewController.attachments = self.attachments;
            taskAttachmentsViewController.documentPickerViewController = self.documentPickerViewController;
            [self.navigationController pushViewController:taskAttachmentsViewController animated:YES];
            [taskAttachmentsViewController release];
        }
    }
}

#pragma mark - DatePicker delegate

- (void)datePicked:(NSDate *)date
{
    self.dueDate = date;
}

#pragma mark - PeoplePicker delegate

- (void)personPicked:(Person *)person
{
    self.assignee = person;
}

#pragma mark - Document picker delegate

- (void)pickingFinished:(DocumentPickerSelection *)selection
{
    if (selection.selectedDocuments.count > 0)
    {
        if (self.attachments == nil)
        {
            self.attachments = [NSMutableArray arrayWithCapacity:selection.selectedDocuments.count];
        }
        [self.attachments addObjectsFromArray:selection.selectedDocuments];
    }
}

@end
