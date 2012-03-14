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
#import "AccountManager.h"
#import "NSNotificationCenter+CustomNotification.h"

@interface AccountSettingsActions (private)
- (void)navigateToAccountDetails:(AccountInfo *)account withNavigation:(UINavigationController *)navigation;
@end

@implementation AccountSettingsActions
@synthesize controller = _controller;

- (void)dealloc
{
    [_controller release];
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
    [[AccountManager sharedManager] removeAccountInfo:deletedAccount];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[deletedAccount uuid], @"uuid", kAccountUpdateNotificationDelete, @"type", nil];
    [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:userInfo];
}

- (void)rightButtonActionWithDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller
{
    AccountTypeViewController *newAccountController = [[AccountTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [newAccountController setDelegate:self];
    
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
#pragma mark Private methods
- (void)navigateToAccountDetails:(AccountInfo *)account withNavigation:(UINavigationController *)navigation {
    AccountViewController *viewAccountController = [[AccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [viewAccountController setIsEdit:NO];
    [viewAccountController setDelegate:self];
    [viewAccountController setAccountInfo:account];
    
    [IpadSupport pushDetailController:viewAccountController withNavigation:navigation andSender:self];
    [viewAccountController release];
}
@end
