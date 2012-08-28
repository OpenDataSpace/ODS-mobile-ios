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
// DocumentPickerRepositoryTableDelegate 
//
#import "DocumentPickerRepositoryTableDelegate.h"
#import "AccountInfo.h"
#import "Utility.h"
#import "CMISServiceManager.h"
#import "RepositoryServices.h"
#import "DocumentPickerViewController.h"
#import "DocumentPickerSelection.h"


@interface DocumentPickerRepositoryTableDelegate () <CMISServiceManagerListener>

@property (nonatomic, retain) NSArray *repositories;

@end


@implementation DocumentPickerRepositoryTableDelegate

@synthesize documentPickerViewController = _documentPickerViewController;
@synthesize account = _account;
@synthesize repositories = _repositories;

#pragma mark Object lifecycle

- (void)dealloc
{
    [_account release];
    [_repositories release];
    [super dealloc];
}

- (id)initWithAccount:(AccountInfo *)account
{
    self = [super init];
    if (self)
    {
        [super setDelegate:self];
        _account = [account retain];
    }

    return self;
}

#pragma mark DocumentPickerTableDelegateFunctionality protocol impl

- (NSInteger)tableCount
{
    return self.repositories.count;;
}

- (BOOL)isDataAvailable
{
    return self.repositories != nil;
}

- (void)loadData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long) NULL), ^(void)
    {
        self.repositories = [[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:self.account.uuid];

        if (!self.repositories)
        {
            [[CMISServiceManager sharedManager] loadServiceDocumentForAccountUuid:self.account.uuid];
        }

        // On the main thread, remove the HUD again
        dispatch_async(dispatch_get_main_queue(), ^(void)
        {
            [self.tableView reloadData];
            stopProgressHUD(self.progressHud);
        });

    });
}

- (void)customizeTableViewCell:(UITableViewCell *)tableViewCell forIndexPath:(NSIndexPath *)indexPath
{
    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    tableViewCell.textLabel.text = ([repositoryInfo tenantID] != nil) ? repositoryInfo.tenantID : repositoryInfo.repositoryName;
    tableViewCell.imageView.image = [UIImage imageNamed:kNetworkIcon_ImageName];
    tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (BOOL)isSelected:(NSIndexPath *)indexPath
{
    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    return [self.documentPickerViewController.selection containsRepository:repositoryInfo];
}

- (BOOL)isSelectionEnabled
{
    return self.documentPickerViewController.selection.isRepositorySelectionEnabled;
}

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    if (self.documentPickerViewController.selection.isRepositorySelectionEnabled)
    {
        [self.documentPickerViewController.selection addRepository:repositoryInfo];
    }
    else // Go one level deeper
    {
        DocumentPickerViewController *newDocumentPickerViewController =
                [DocumentPickerViewController documentPickerForRepository:repositoryInfo];
        [self goOneLevelDeeperWithDocumentPicker:newDocumentPickerViewController];
    }
}

- (void)didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.documentPickerViewController.selection.isRepositorySelectionEnabled)
    {
        RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
        [self.documentPickerViewController.selection removeRepository:repositoryInfo];
    }
}

- (NSString *)titleForTable
{
    return self.account.description;
}

- (void)clearCachedData
{
    self.repositories = nil;
}

@end
