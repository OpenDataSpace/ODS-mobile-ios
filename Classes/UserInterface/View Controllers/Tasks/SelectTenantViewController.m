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
//  SelectTenantViewController.m
//

#import "SelectTenantViewController.h"
#import "RepositoryServices.h"
#import "Theme.h"
#import "SelectTaskTypeViewController.h"

@interface SelectTenantViewController ()

@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSArray *repositories;

@end

@implementation SelectTenantViewController

@synthesize addTaskDelegate = _addTaskDelegate;
@synthesize accountUuid = _accountUuid;
@synthesize repositories = _repositories;

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid
{
    self = [super initWithStyle:style];
    if (self) {
        self.accountUuid = uuid;
    }
    return self;
}

- (void)dealloc
{
    [_accountUuid release];
    [_repositories release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [Theme setThemeForUITableViewController:self];
    [self setTitle:NSLocalizedString(@"task.choose.tenant.title", nil)];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancel:)] autorelease]];
    
    RepositoryServices *repoService = [RepositoryServices shared];
    self.repositories = [repoService getRepositoryInfoArrayForAccountUUID:self.accountUuid];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.repositories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    cell.textLabel.text = ([repositoryInfo tenantID] != nil) ? repositoryInfo.tenantID : repositoryInfo.repositoryName;
    cell.imageView.image = [UIImage imageNamed:kNetworkIcon_ImageName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    SelectTaskTypeViewController *taskTypeController = [[SelectTaskTypeViewController alloc] initWithStyle:UITableViewStyleGrouped 
                                                                                                   account:self.accountUuid tenantID:repositoryInfo.tenantID];
    taskTypeController.addTaskDelegate = self.addTaskDelegate;
    [self.navigationController pushViewController:taskTypeController animated:YES];
    [taskTypeController release];
}

@end
