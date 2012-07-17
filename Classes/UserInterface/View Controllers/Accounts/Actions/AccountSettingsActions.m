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
//
//  AccountSettingsActions.m
//

#import "AccountSettingsActions.h"
#import "AccountInfo.h"
#import "AccountViewController.h"
#import "IpadSupport.h"
#import "AccountManager+FileProtection.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "AwaitingVerificationViewController.h"
#import "AppProperties.h"

@interface AccountSettingsActions (private)
- (void)deleteAccount:(AccountInfo *)accountInfo;
- (void)navigateToAccountDetails:(AccountInfo *)account withNavigation:(UINavigationController *)navigation;
@end

@implementation AccountSettingsActions
@synthesize controller = _controller;
@synthesize selectedAccount = _selectedAccount;

- (void)dealloc
{
    [_controller release];
    [_selectedAccount release];
    [super dealloc];
}
/*
 The user selected an account. We have to retrieve the account information from the datasource and then navigate into the account details
 */
- (void)rowWasSelectedAtIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller
{
    NSArray *accounts = [datasource objectForKey:@"accounts"];
    AccountInfo *account = [accounts objectAtIndex:indexPath.row];
    [self navigateToAccountDetails:account withNavigation:[controller navigationController] ];
    [controller setSelectedAccountUUID:[account uuid]];
}

- (void)commitEditingForIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource
{
    NSArray *accounts = [datasource objectForKey:@"accounts"];
    AccountInfo *deletedAccount = [accounts objectAtIndex:indexPath.row];
    //Retrieving an updated accountInfo object for the uuid since it might contain an outdated isQualifyingAccount property
    deletedAccount = [[AccountManager sharedManager] accountInfoForUUID:[deletedAccount uuid]];
    
    if([deletedAccount isQualifyingAccount] && [[AccountManager sharedManager] numberOfQualifyingAccounts] == 1)
    {
        [self setSelectedAccount:deletedAccount];
        UIAlertView *deletePrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"dataProtection.lastAccount.title", @"Data Protection") 
                                                                message:NSLocalizedString(@"dataProtection.lastAccount.message", @"Last qualifying account...") 
                                                               delegate:self 
                                                      cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                                                      otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
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
}

- (void)rightButtonActionWithDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller
{
    BOOL allowCloudAccounts = [[AppProperties propertyForKey:kAccountsAllowCloudAccounts] boolValue];
    UIViewController *newAccountController = nil;
    
    if(allowCloudAccounts)
    {
        AccountTypeViewController *accountTypeController = [[AccountTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [accountTypeController setDelegate:self];
        newAccountController = accountTypeController;
    }
    else {
        AccountViewController *accountViewController = [[AccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [accountViewController setIsEdit:YES];
        [accountViewController setIsNew:YES];
        [accountViewController setDelegate:self];
        
        AccountInfo *newAccount = [[AccountInfo alloc] init];
        [newAccount setProtocol:kFDHTTP_Protocol];
        [newAccount setPort:kFDHTTP_DefaultPort];
        [accountViewController setAccountInfo:newAccount];
        [newAccount release];
        
        newAccountController = accountViewController;
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newAccountController];
    
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [controller presentModalViewController:navController animated:YES];
    
    [navController release];
    [newAccountController release];
    [self setController:controller];
}

#pragma mark -
#pragma mark AccountViewControllerDelegate
- (void)accountControllerDidCancel:(AccountViewController *)accountViewController {
    [self.controller dismissModalViewControllerAnimated:YES];
}

- (void)accountControllerDidFinishSaving:(AccountViewController *)accountViewController {
    [self.controller dismissModalViewControllerAnimated:YES];
    [self navigateToAccountDetails:[accountViewController accountInfo] withNavigation:[self.controller navigationController]]; 
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 1) {
        //Retrieving an updated accountInfo object for the uuid since it might contain an outdated isQualifyingAccount property
        AccountInfo *deletedAccount = [[AccountManager sharedManager] accountInfoForUUID:[self.selectedAccount uuid]];
        [self deleteAccount:deletedAccount];
    } 
}


#pragma mark -
#pragma mark Private methods
- (void)navigateToAccountDetails:(AccountInfo *)account withNavigation:(UINavigationController *)navigation {
    if([account accountStatus] == FDAccountStatusAwaitingVerification)
    {
        AwaitingVerificationViewController *viewController = [[AwaitingVerificationViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [viewController setSelectedAccountUUID:[account uuid]];
        [viewController setIsSettings:YES];
        [IpadSupport pushDetailController:viewController withNavigation:navigation andSender:self];
        [viewController release];
    }
    else
    {
        AccountViewController *viewAccountController = [[AccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [viewAccountController setIsEdit:NO];
        [viewAccountController setDelegate:self];
        [viewAccountController setAccountInfo:account];
        
        [IpadSupport pushDetailController:viewAccountController withNavigation:navigation andSender:self];
        [viewAccountController release];
    }
}
@end
