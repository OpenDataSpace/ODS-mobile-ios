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
//  TaskFilterViewController.m
//

#import "TaskFilterViewController.h"
#import "Theme.h"

NSString * const kFilterMyTasks = @"filter_mytasks";
NSString * const kFilterTasksStartedByMe = @"filter_startedbymetasks";

@interface TaskFilterViewController ()

@end

@implementation TaskFilterViewController

@synthesize delegate = _delegate;
@synthesize currentFilter = _currentFilter;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [_currentFilter release];
    
    [super dealloc];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedString(@"tasks.view.mytasks.title", nil);
        if ([self.currentFilter isEqualToString:kFilterMyTasks])
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else 
    {
        cell.textLabel.text = NSLocalizedString(@"tasks.view.startedbymetasks.title", nil);
        if ([self.currentFilter isEqualToString:kFilterTasksStartedByMe])
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[self.tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    if (indexPath.row == 0)
    {
        [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] setAccessoryType:UITableViewCellAccessoryNone];
    }
    else 
    {
        [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    if (self.delegate)
    {
        if (indexPath.row == 0)
        {
            [self.delegate filterTasks:kFilterMyTasks];
        }
        else 
        {
            [self.delegate filterTasks:kFilterTasksStartedByMe];
        }
        self.delegate = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
