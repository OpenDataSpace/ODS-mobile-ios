//
//  SelectAccountViewController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 28/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
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
