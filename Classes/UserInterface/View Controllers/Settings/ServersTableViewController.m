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
//  ServersTableViewController.m
//

#import "ServersTableViewController.h"
#import "IFPreferencesModel.h"
#import "IFMultilineCellController.h"
#import "IFTextViewTableView.h"
#import "TableViewHeaderView.h"
#import "ThemeProperties.h"
#import "TableCellViewController.h"
#import "AccountInfo.h"
#import "IpadSupport.h"
#import "Utility.h"
#import "AccountManager+FileProtection.h"
#import "AccountTypeViewController.h"
#import "NSNotificationCenter+CustomNotification.h"

@interface ServersTableViewController(private)
- (void)navigateToAccountDetails:(AccountInfo *)account;
- (void)deleteAccount:(AccountInfo *)accountInfo;
@end


@implementation ServersTableViewController
@synthesize userAccounts;

#pragma mark - Memory Managment

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [userAccounts release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void) viewDidUnload 
{
    [super viewDidUnload];
    
    [self setModel:nil];
    
    //IFGenericTableViewController
    [tableGroups release];
    tableGroups = nil;
    [tableFooters release];
    tableGroups = nil;
    [tableHeaders release];
    tableHeaders = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationAccountListUpdated object:nil];
}

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
    
    [self setTitle:NSLocalizedString(@"Accounts", @"Accounts - Server View Title Page")];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                               target:self action:@selector(addServerButtonClicked:)];
    
    [self setUserAccounts:[[AccountManager sharedManager] allAccounts]];
    [[self navigationItem] setRightBarButtonItem:addButton];
    [addButton release];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                 name:kNotificationAccountListUpdated object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(!IS_IPAD) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (id)init
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        
    }
    return self;
}

#pragma mark Handlers

- (void)addServerButtonClicked:(id)sender
{
    AccountTypeViewController *newAccountController = [[AccountTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [newAccountController setDelegate:self];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newAccountController];
    
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentModalViewController:navController animated:YES];
    
    [navController release];
    [newAccountController release];
}

#pragma mark -
#pragma mark AccountViewControllerDelegate
- (void)accountControllerDidCancel:(AccountViewController *)accountViewController {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)accountControllerDidFinishSaving:(AccountViewController *)accountViewController {
    /*[userAccounts addObject:[accountViewController accountInfo]];
    [self updateAndReload];*/
    [self dismissModalViewControllerAnimated:YES];
    [self navigateToAccountDetails:[accountViewController accountInfo]]; 
}

#pragma mark - GenericTableView
- (void)constructTableGroups
{
    NSMutableArray *groups =  [NSMutableArray array];
    
    NSMutableArray *accountsGroup = [NSMutableArray array];
    NSInteger index = 0;
    
    for(AccountInfo *detail in userAccounts) 
    {        
        NSString *iconImageName = ([detail isMultitenant] ? kCloudIcon_ImageName : kServerIcon_ImageName);
        
        TableCellViewController *accountCell = [[TableCellViewController alloc] initWithAction:@selector(performTapAccount:) 
                                                                                      onTarget:self];
        [accountCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [accountCell setTag:index];
        [accountCell.textLabel setText:[detail description]];
        [[accountCell imageView]setImage:[UIImage imageNamed:iconImageName]];
        
        [accountsGroup addObject:accountCell];
        [accountCell release];
        index++;
        
        [self.tableView setAllowsSelection:YES];
    }
    
    if([userAccounts count] > 0) 
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
    if([sender isKindOfClass:[TableCellViewController class]]) {
        TableCellViewController *cell = (TableCellViewController *)sender;    
        AccountInfo *selectedAccount = [userAccounts objectAtIndex:cell.tag];
        //Retrieving an updated accountInfo object for the uuid since it might contain an outdated isQualifyingAccount property
        AccountInfo *updatedAccount = [[AccountManager sharedManager] accountInfoForUUID:[selectedAccount uuid]];
        [self navigateToAccountDetails:updatedAccount];
    }
}

- (void)navigateToAccountDetails:(AccountInfo *)account {
    AccountViewController *viewAccountController = [[AccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [viewAccountController setIsEdit:NO];
    [viewAccountController setDelegate:self];
    [viewAccountController setAccountInfo:account];
    
    [IpadSupport pushDetailController:viewAccountController withNavigation:[self navigationController] andSender:self];
    [viewAccountController release];
}

#pragma mark - UITableViewDelegate Methods

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section 
{
    NSString *sectionTitle = [tableFooters objectAtIndex:section];
	if ((nil == sectionTitle))
		return nil;
    
    //The height gets adjusted if it is less than the needed height
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) 
                                                                            label:sectionTitle] autorelease];
    [headerView setBackgroundColor:[ThemeProperties browseFooterColor]];
    [headerView.textLabel setTextColor:[ThemeProperties browseFooterTextColor]];
    
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *sectionTitle = [tableFooters objectAtIndex:section];
	if ((nil == sectionTitle))
		return 0.0f;
	
	TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) 
                                                                            label:sectionTitle] autorelease];
	return headerView.frame.size.height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    AccountInfo *selectedAccount = [userAccounts objectAtIndex:indexPath.row];
    //Retrieving an updated accountInfo object for the uuid since it might contain an outdated isQualifyingAccount property
    AccountInfo *deletedAccount = [[AccountManager sharedManager] accountInfoForUUID:[selectedAccount uuid]];
    
    if([deletedAccount isQualifyingAccount] && [[AccountManager sharedManager] numberOfQualifyingAccounts] == 1)
    {
        UIAlertView *deletePrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"dataProtection.lastAccount.title", @"Data Protection") 
                                                  message:NSLocalizedString(@"dataProtection.lastAccount.message", @"Last qualifying account...") 
                                                 delegate:self 
                                        cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                                        otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
        [deletePrompt setTag:indexPath.row];
        [deletePrompt show];
    } 
    else 
    {
        [self deleteAccount:deletedAccount];
    }
}

- (void)deleteAccount:(AccountInfo *)accountInfo
{
    [[AccountManager sharedManager] removeAccountInfo:accountInfo];
    [self handleAccountListUpdated:nil];
    
    // Raising the kAccountUpdateNotificationDelete event
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[accountInfo uuid], @"uuid", kAccountUpdateNotificationDelete, @"type", nil];
    [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:userInfo];
}

#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) {
        NSInteger accountIndex = [alertView tag];
        //Delete account
        AccountInfo *selectedAccount = [userAccounts objectAtIndex:accountIndex];
        //Retrieving an updated accountInfo object for the uuid since it might contain an outdated isQualifyingAccount property
        AccountInfo *deletedAccount = [[AccountManager sharedManager] accountInfoForUUID:[selectedAccount uuid]];
        [self deleteAccount:deletedAccount];
    } 
}

#pragma mark - Notification Center methods
- (void)handleAccountListUpdated:(id)sender
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:sender waitUntilDone:NO];
        return;
    }
    
    [self setUserAccounts:[[AccountManager sharedManager] allAccounts]];
    [self updateAndReload];
}


@end
