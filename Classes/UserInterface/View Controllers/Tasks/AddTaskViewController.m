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
#import "TableViewHeaderView.h"
#import "Theme.h"
#import "ThemeProperties.h"
#import "DocumentPickerViewController.h"
#import "DocumentPickerSelection.h"
#import "DatePickerViewController.h"
#import "PeoplePickerViewController.h"
#import "TaskManager.h"
#import "AccountManager.h"

@interface AddTaskViewController () <DatePickerDelegate, PeoplePickerDelegate>

@end

@implementation AddTaskViewController

@synthesize dueDate = _dueDate;
@synthesize assignee = _assignee;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [Theme setThemeForUITableViewController:self];
    [self setTitle:@"Create new task"];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancelEdit:)] autorelease]];
    
    UIBarButtonItem *createButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(createTask:)] autorelease];
    [createButton setTitle:@"Create"];
    [self.navigationItem setRightBarButtonItem:createButton];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)createTask:(id)sender
{
    TaskItem *task = [[TaskItem alloc] init];
    UITableViewCell *titleCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITextField *titleField = (UITextField *) [titleCell viewWithTag:101];
    task.title = titleField.text;
    task.ownerUserName = self.assignee.userName;
    AccountInfo *account = [[[AccountManager sharedManager] activeAccounts] objectAtIndex:0];
    [[TaskManager sharedManager] startTaskCreateRequestForTask:task accountUUID:account.uuid tenantID:nil];
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
        cell.textLabel.text = @"Title";
        UITextField *titleField = [[UITextField alloc] init];
        if (IS_IPAD)
        {
            titleField.frame = CGRectMake(150, 12, 300, 30);
        }
        else 
        {
            titleField.frame = CGRectMake(100, 12, 205, 30);
        }
        titleField.placeholder = @"Title text";
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
        cell.textLabel.text = @"Due on";
        cell.detailTextLabel.text = @"No date";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = @"Assign to";
        cell.detailTextLabel.text = @"No assignee";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 3)
    {
        cell.textLabel.text = @"Attachments";
        cell.detailTextLabel.text = @"No attachments";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 4)
    {
        cell.textLabel.text = @"Priority";
        NSArray *itemArray = [NSArray arrayWithObjects: @"High", @"Medium", @"Low", nil];
        UISegmentedControl *priorityControl = [[UISegmentedControl alloc] initWithItems:itemArray];
        if (IS_IPAD)
        {
            priorityControl.frame = CGRectMake(150, 7, 300, 30);
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
        DatePickerViewController *datePicker = [[DatePickerViewController alloc] initWithStyle:UITableViewStyleGrouped andNSDate:self.dueDate];
        datePicker.delegate = self;
        datePicker.title = @"Choose due date";
        [self.navigationController pushViewController:datePicker animated:YES];
    }
    else if (indexPath.row == 2)
    {
        PeoplePickerViewController *peoplePicker = [[PeoplePickerViewController alloc] initWithStyle:UITableViewStylePlain];
        peoplePicker.delegate = self;
        [self.navigationController pushViewController:peoplePicker animated:YES];
    }
    else if (indexPath.row == 3)
    {
        DocumentPickerViewController *documentPicker = [DocumentPickerViewController documentPicker];
        documentPicker.selection.selectiontextPrefix = NSLocalizedString(@"document.picker.selection.button.attach", nil);
        [self.navigationController pushViewController:documentPicker animated:YES];
    }
}

#pragma mark - DatePicker delegate

- (void)datePicked:(NSDate *)date
{
    self.dueDate = date;
    UITableViewCell *dueCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterMediumStyle;
    dueCell.detailTextLabel.text = [df stringFromDate:date];
}

#pragma mark - PeoplePicker delegate

- (void)personPicked:(Person *)person
{
    self.assignee = person;
    UITableViewCell *dueCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    dueCell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", person.firstName, person.lastName];
}

@end
