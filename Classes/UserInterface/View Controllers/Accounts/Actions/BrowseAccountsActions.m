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
//  BrowseAccountsActions.m
//

#import "BrowseAccountsActions.h"
#import "RepositoriesViewController.h"
#import "RootViewController.h"
#import "IpadSupport.h"
#import "AwaitingVerificationViewController.h"

@implementation BrowseAccountsActions

#pragma mark - FDTableViewActionsProtocol methods
/*
 The user selected an account. We have to retrieve the account information from the datasource and then navigate into browsing the account.
 Depending on the account, we can navigate into a networks controller (cloud account) or directly to Browsing the files (RootViewController)
 */
- (void)rowWasSelectedAtIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller
{
    NSArray *accounts = [datasource objectForKey:@"accounts"];
    AccountInfo *account = [accounts objectAtIndex:indexPath.row];
    [BrowseAccountsActions advanceToNextViewController:account withController:controller animated:YES];
    [controller setSelectedAccountUUID:[account uuid]];
}

/*
 We want to check if there's only one account in the datasource, if there is only one we want to navigate into the only account.
 This method will be called at the start of the FDGenericTableViewController (viewDidLoad) and every time there's an update in the AccountList
 add, delete, update.
 */
- (void)datasourceChanged:(NSDictionary *)datasource inController:(FDGenericTableViewController *)controller notification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *uuid = [userInfo objectForKey:@"uuid"];
    
    // We want to reset to the root view controller in the case we are browsing the account affected by the update
    if(!controller.selectedAccountUUID || [controller.selectedAccountUUID isEqualToString:uuid] || [[userInfo objectForKey:@"reset"] boolValue]) 
    {
        [controller.navigationController popToRootViewControllerAnimated:NO];
        [controller setSelectedAccountUUID:nil];
        [IpadSupport clearDetailController];
    }
    
    NSArray *accounts = [datasource objectForKey:@"accounts"];
    
    // We have to be careful when pushing a new controller. We want to make sure the FDGenericTableViewController is the current controller
    // (the last object in the navigation's viewControllers stack)
    NSArray *controllers = [controller.navigationController viewControllers];
    UIViewController *visibleController = [controllers lastObject];
    if([accounts count] == 1 && [visibleController isEqual:controller])
    {
        [BrowseAccountsActions advanceToNextViewController:[accounts objectAtIndex:0] withController:controller animated:NO];
    }
}

#pragma mark - Utility method
/*
 Utility method to navigate into an account.
 */
+ (void)advanceToNextViewController:(AccountInfo *)account withController:(FDGenericTableViewController *)controller animated:(BOOL)animated
{
    [controller.navigationItem setTitle:NSLocalizedString(@"Accounts", @"Accounts")];
    
    if([account accountStatus] == FDAccountStatusAwaitingVerification)
    {
        AwaitingVerificationViewController *viewController = [[AwaitingVerificationViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [viewController setSelectedAccountUUID:[account uuid]];
        [IpadSupport pushDetailController:viewController withNavigation:controller.navigationController andSender:self];
        [viewController release];
    }
    else if ([account isMultitenant]) 
    {
        RepositoriesViewController *viewController = [[RepositoriesViewController alloc] initWithAccountUUID:[account uuid]];
        [viewController setViewTitle:[account description]];
        [[controller navigationController] pushViewController:viewController animated:animated];
        [viewController release];
    }
    else
    {
        RootViewController *nextController = [[RootViewController alloc] initWithNibName:kFDRootViewController_NibName bundle:nil];
        [nextController setSelectedAccountUUID:[account uuid]];
        [[nextController navigationItem] setTitle:[account description]];
        
        [[controller navigationController] pushViewController:nextController animated:animated];
        [nextController release];
    }
}

@end
