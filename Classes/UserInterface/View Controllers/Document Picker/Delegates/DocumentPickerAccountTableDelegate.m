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
// AccountDelegate 
//
#import "DocumentPickerAccountTableDelegate.h"
#import "AccountInfo.h"
#import "DocumentPickerViewController.h"
#import "AccountManager.h"
#import "Utility.h"
#import "DocumentPickerSelection.h"

@interface DocumentPickerAccountTableDelegate ()

@property (nonatomic, retain) NSArray *accounts;
@property (nonatomic, retain) MBProgressHUD *progressHud;

@end

@implementation DocumentPickerAccountTableDelegate

@synthesize accounts = _accounts;
@synthesize progressHud = _HUD;
@synthesize documentPickerViewController = _documentPickerViewController;

#pragma mark Init & Dealloc

- (void)dealloc
{
    [_accounts release];
    [_HUD release];
    [super dealloc];
}

#pragma mark Data loading

- (void)loadDataForTableView:(UITableView *)tableView
{
    if (self.accounts == nil)
    {
        // On the main thread, display the HUD
        self.progressHud = createAndShowProgressHUDForView(tableView);

        // On a background thread, fetch the data
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long) NULL), ^(void)
        {
            self.accounts = [[AccountManager sharedManager] activeAccounts];

            // On the main thread, remove the HUD again
            dispatch_async(dispatch_get_main_queue(), ^(void)
            {
                [tableView reloadData];
                stopProgressHUD(self.progressHud);
            });

        });
    }
}

#pragma mark Table view datasource and delegate methods

- (void)tableViewDidLoad:(UITableView *)tableView
{
    if (self.documentPickerViewController.selection.isAccountSelectionEnabled)
    {
        [tableView setEditing:YES];
        [tableView setAllowsMultipleSelectionDuringEditing:YES];

        if (self.documentPickerViewController.selection.isMultiSelectionEnabled)
        {
            [tableView setAllowsMultipleSelection:YES];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.accounts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

// General cell rendering, will simply do a switch based on the current state to the appropriate rendering method
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AccountCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    AccountInfo *account = [self.accounts objectAtIndex:indexPath.row];
    cell.textLabel.text = account.description;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageNamed:([account isMultitenant] ? kCloudIcon_ImageName : kServerIcon_ImageName)];
    cell.selected = [self isAccountSelected:account];

    return cell;
}

- (BOOL)isAccountSelected:(AccountInfo *)accountToCheck
{
    for (AccountInfo *account in self.documentPickerViewController.selection.selectedAccounts)
    {
        if ([account.uuid isEqualToString:accountToCheck.uuid])
        {
            return YES;
        }
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountInfo *selectedAccount = [self.accounts objectAtIndex:indexPath.row];
    if (self.documentPickerViewController.selection.isAccountSelectionEnabled) // If the document picker is configured to select accounts
    {
        [self.documentPickerViewController.selection addAccount:selectedAccount];
    }
    else // We should go one level below accounts
    {
        DocumentPickerViewController *newDocumentPickerViewController =
            [DocumentPickerViewController documentPickerForAccount:selectedAccount];
        newDocumentPickerViewController.selection = self.documentPickerViewController.selection; // copying setting for selection, and already selected items
        [self.documentPickerViewController.navigationController pushViewController:newDocumentPickerViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.documentPickerViewController.selection.isAccountSelectionEnabled) // If the document picker is configured to select accounts
    {
        AccountInfo *selectedAccount = [self.accounts objectAtIndex:indexPath.row];
        [self.documentPickerViewController.selection removeAccount:selectedAccount];
    }
}

- (NSString *)titleForTable
{
    return NSLocalizedString(@"Accounts", nil);
}

@end
