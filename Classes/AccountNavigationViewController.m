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
//  AccountNavigationViewController.m
//


#import "AccountNavigationViewController.h"
#import "TableCellViewController.h"
#import "IFTextViewTableView.h"
#import "RootViewController.h"
#import "Theme.h"
#import "TableViewHeaderView.h"
#import "ThemeProperties.h"
#import "AccountInfo.h"
#import "AccountManager.h"
#import "RepositoriesViewController.h"
#import "CMISServiceManager.h"

@interface AccountNavigationViewController () // Private
- (void)advanceToNextViewController:(AccountInfo *)account animated:(BOOL)animated;
- (void)handleAccountListUpdated:(id)sender;
@end

@implementation AccountNavigationViewController
@synthesize userAccounts = _userAccounts;
@synthesize selectedAccountUUID = _selectedAccountUUID;


- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_userAccounts release];
    [_selectedAccountUUID release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self setUserAccounts:nil];
}


#pragma mark - View lifecycle

- (void)loadView
{
	// NOTE: This code circumvents the normal loading of the UITableView and replaces it with an instance
	// of IFTextViewTableView (which includes a workaround for the hit testing problems in a UITextField.)
	// Check the header file for IFTextViewTableView to see why this is important.
	//
	// Since there is no style accessor on UITableViewController (to obtain the value passed in with the
	// initWithStyle: method), the value is hard coded for this use case. Too bad.
    
	self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setUserAccounts:[[AccountManager sharedManager] allAccounts]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBrowseDocuments:) 
                                                 name:kBrowseDocumentsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                 name:kNotificationAccountListUpdated object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self navigationItem] setTitle:NSLocalizedString(@"account.navigation.view.title", @"Account Nav view title")];
    
    [self setUserAccounts:[[AccountManager sharedManager] allAccounts]]; 
    if([self.userAccounts count] == 1) 
    {
        [self advanceToNextViewController:[self.userAccounts objectAtIndex:0] animated:NO];
    }

    [Theme setThemeForUIViewController:self]; 
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - UITableViewDelegate Methods

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
	if ((nil == sectionTitle))
		return nil;
    
    //The height gets adjusted if it is less than the needed height
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
    [headerView setBackgroundColor:[ThemeProperties browseHeaderColor]];
    [headerView.textLabel setTextColor:[ThemeProperties browseHeaderTextColor]];
    
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
	if ((nil == sectionTitle))
		return 0.0f;
	
	TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
	return headerView.frame.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}


#pragma mark - IFGenericTableView Impl

- (void)constructTableGroups 
{
    // Arrays for section headers, bodies and footers
	NSMutableArray *groups =  [NSMutableArray array];
    NSMutableArray *accountsGroup = [NSMutableArray array];
    NSInteger index = 0;
    
    for(AccountInfo *detail in self.userAccounts) 
    {
        NSString *iconImageName = ([detail isMultitenant] ? kCloudIcon_ImageName : kServerIcon_ImageName);
        
        TableCellViewController *accountCell = [[TableCellViewController alloc] initWithAction:@selector(performTapAccount:) 
                                                                                      onTarget:self];
        [accountCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [accountCell setTag:index];
        [accountCell.textLabel setText:[detail description]];
        [accountCell.imageView setImage:[UIImage imageNamed:iconImageName]];
        
        [accountsGroup addObject:accountCell];
        [accountCell release];
        index++;
    }
    
    if([self.userAccounts count] > 0) 
    {
        [groups addObject:accountsGroup];
    } 
    else 
    {
        TableCellViewController *cell;
        cell = [[TableCellViewController alloc] initWithAction:nil onTarget:nil];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [[cell textLabel] setText:NSLocalizedString(@"serverlist.cell.noaccounts", @"No Accounts")];
        [cell setShouldResizeTextToFit:YES];
        
        NSMutableArray *group = [NSMutableArray array];
        [group addObject:cell];
        [cell release];
        
        [groups addObject:group];
        [self.tableView setAllowsSelection:NO];
    }
    
    [tableGroups release];
    tableGroups = [groups retain];
	
	[self assignFirstResponderHostToCellControllers];
}

- (void)performTapAccount:(id)sender 
{
    if([sender isKindOfClass:[TableCellViewController class]]) 
    {
        TableCellViewController *cell = (TableCellViewController *)sender;
        AccountInfo *selectedAccount = [self.userAccounts objectAtIndex:cell.tag];
        [self advanceToNextViewController:selectedAccount animated:YES];
        [self setSelectedAccountUUID:[selectedAccount uuid]];
    }
}

- (void)advanceToNextViewController:(AccountInfo *)account animated:(BOOL)animated
{
    [self setSelectedAccountUUID:[account uuid]];
    [self.navigationItem setTitle:NSLocalizedString(@"Accounts", @"Accounts")];
    
    if ([account isMultitenant]) 
    {
        RepositoriesViewController *viewController = [[RepositoriesViewController alloc] initWithAccountUUID:[account uuid]];
        [viewController setViewTitle:[account description]];
        [[self navigationController] pushViewController:viewController animated:animated];
        [viewController release];
    }
    else 
    {
        RootViewController *nextController = [[RootViewController alloc] initWithNibName:kFDRootViewController_NibName bundle:nil];
        [nextController setSelectedAccountUUID:[account uuid]];
        [[nextController navigationItem] setTitle:[account description]];
        
        [[self navigationController] pushViewController:nextController animated:animated];
        [nextController release];
    }
}


- (void)handleAccountListUpdated:(NSNotification *) notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSString *uuid = [userInfo objectForKey:@"uuid"];
    if(!self.selectedAccountUUID || [self.selectedAccountUUID isEqualToString:uuid] || [[userInfo objectForKey:@"reset"] boolValue]) 
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self setSelectedAccountUUID:nil];
    }
    
    [self setUserAccounts:[[AccountManager sharedManager] allAccounts]];
    [self updateAndReload];
}

- (void)handleBrowseDocuments:(NSNotification *)notification 
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleBrowseDocuments:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    NSString *uuidToBrowse = [[notification userInfo] objectForKey:@"accountUUID"];
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:uuidToBrowse];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self advanceToNextViewController:accountInfo animated:NO];
    
    [[self tabBarController] setSelectedViewController:[self navigationController]];
}

@end
