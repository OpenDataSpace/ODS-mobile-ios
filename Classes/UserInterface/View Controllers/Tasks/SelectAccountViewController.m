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
//  SelectAccountViewController.m
//

#import "SelectAccountViewController.h"
#import "MBProgressHUD.h"
#import "Theme.h"
#import "Utility.h"
#import "AccountManager.h"
#import "AccountInfo.h"
#import "RepositoryServices.h"
#import "SelectTenantViewController.h"
#import "SelectTaskTypeViewController.h"

@interface SelectAccountViewController ()

@property (nonatomic, retain) MBProgressHUD *HUD;

- (void) startHUD;
- (void) stopHUD;

@end

@implementation SelectAccountViewController

@synthesize HUD = _HUD;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [_HUD release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUITableViewController:self];
    [self setTitle:@"Choose account"];
    
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[AccountManager sharedManager] activeAccounts].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    AccountInfo *account = [[[AccountManager sharedManager] activeAccounts] objectAtIndex:indexPath.row];
    cell.textLabel.text = account.description;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageNamed:([account isMultitenant] ? kCloudIcon_ImageName : kServerIcon_ImageName)];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryServices *repoService = [RepositoryServices shared];
    AccountInfo *account = [[[AccountManager sharedManager] activeAccounts] objectAtIndex:indexPath.row];
    if([[account vendor] isEqualToString:kFDAlfresco_RepositoryVendorName] && 
       [repoService getRepositoryInfoArrayForAccountUUID:account.uuid]) 
    {
        if ([account isMultitenant])
        {
            SelectTenantViewController *tenantController = [[SelectTenantViewController alloc] initWithStyle:UITableViewStyleGrouped account:account.uuid];
            [self.navigationController pushViewController:tenantController animated:YES];
            [tenantController release];
        }
        else 
        {
            SelectTaskTypeViewController *taskTypeController = [[SelectTaskTypeViewController alloc] initWithStyle:UITableViewStyleGrouped 
                                                                                                           account:account.uuid tenantID:nil];
            [self.navigationController pushViewController:taskTypeController animated:YES];
            [taskTypeController release];
        }
    }
}

#pragma mark - Internal methods



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

@end
