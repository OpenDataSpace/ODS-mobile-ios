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

@end

@implementation DocumentPickerAccountTableDelegate

@synthesize accounts = _accounts;


#pragma mark Init & Dealloc

- (void)dealloc
{
    [_accounts release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [super setDelegate:self];
    }
    return self;
}

#pragma mark Methods from superclass that are overriden

- (NSInteger)tableCount
{
    return self.accounts.count;
}


- (void)loadData
{
    // On a background thread, fetch the data
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long) NULL), ^(void)
    {
        self.accounts = [[AccountManager sharedManager] activeAccounts];

        // On the main thread, remove the HUD again
        dispatch_async(dispatch_get_main_queue(), ^(void)
        {
            [self.tableView reloadData];
            stopProgressHUD(self.progressHud);
        });

    });
}

- (BOOL)isDataAvailable
{
    return self.accounts != nil;
}

- (void)customizeTableViewCell:(UITableViewCell *)tableViewCell forIndexPath:(NSIndexPath *)indexPath
{
    AccountInfo *account = [self.accounts objectAtIndex:indexPath.row];
    tableViewCell.textLabel.text = account.description;
    tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    tableViewCell.imageView.image = [UIImage imageNamed:([account isMultitenant] ? kCloudIcon_ImageName : kServerIcon_ImageName)];
}

- (BOOL)isSelectionEnabled
{
    return self.documentPickerViewController.selection.isAccountSelectionEnabled;
}

- (BOOL)isSelected:(NSIndexPath *)indexPath
{
    AccountInfo *account = [self.accounts objectAtIndex:indexPath.row];
    return [self.documentPickerViewController.selection containsAccount:account];
}

#pragma mark Table view datasource and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.accounts.count;
}

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountInfo *selectedAccount = [self.accounts objectAtIndex:indexPath.row];
    if (self.documentPickerViewController.selection.isAccountSelectionEnabled) // If the document picker is configured to select accounts
    {
        [self.documentPickerViewController.selection addAccount:selectedAccount];
    }
    else // We should go one level below accounts
    {
        [self goOneLevelDeeperWithDocumentPicker:[DocumentPickerViewController documentPickerForAccount:selectedAccount]];
    }
}

- (void)didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
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

- (void)clearCachedData
{
    self.accounts = nil;
}


@end
