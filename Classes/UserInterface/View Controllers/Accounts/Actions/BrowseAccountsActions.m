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

@interface BrowseAccountsActions(private)
- (void)advanceToNextViewController:(AccountInfo *)account withController:(FDGenericTableViewController *)controller animated:(BOOL)animated;
@end

@implementation BrowseAccountsActions

- (void)rowWasSelectedAtIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller
{
    NSArray *accounts = [datasource objectForKey:@"accounts"];
    AccountInfo *account = [accounts objectAtIndex:indexPath.row];
    [self advanceToNextViewController:account withController:controller animated:YES];
    [controller setSelectedAccountUUID:[account uuid]];
}

- (void)advanceToNextViewController:(AccountInfo *)account withController:(FDGenericTableViewController *)controller animated:(BOOL)animated
{
    [controller.navigationItem setTitle:NSLocalizedString(@"Accounts", @"Accounts")];
    
    if ([account isMultitenant]) 
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
