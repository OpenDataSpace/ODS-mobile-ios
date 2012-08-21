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
#import "MBProgressHUD.h"
#import "AccountManager.h"
#import "Utility.h"
#import "CMISServiceManager.h"
#import "RepositoryServices.h"
#import "DocumentPickerViewController.h"

@interface DocumentPickerRepositoryTableDelegate () <CMISServiceManagerListener>

@property (nonatomic, retain) MBProgressHUD *progressHud;
@property (nonatomic, retain) UITableView *tableView;

@property (nonatomic, retain) NSArray *repositories;

@end


@implementation DocumentPickerRepositoryTableDelegate

@synthesize documentPickerViewController = _documentPickerViewController;
@synthesize account = _account;
@synthesize progressHud = _progressHud;
@synthesize tableView = _tableView;
@synthesize repositories = _repositories;

#pragma mark Object lifecycle

- (void)dealloc
{
    [_account release];
    [_progressHud release];
    [_tableView release];
    [_repositories release];
    [super dealloc];
}

- (id)initWithAccount:(AccountInfo *)account
{
    self = [super init];
    if (self)
    {
        _account = [account retain];
    }

    return self;
}

#pragma mark Data loading

- (void)loadDataForTableView:(UITableView *)tableView
{
    if (self.repositories == nil)
    {
        // On the main thread, display the HUD
        self.progressHud = createAndShowProgressHUDForView(tableView);
        self.tableView = tableView;

        // Fire off repo info request, see listeners below for handling of the response
        CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
        [serviceManager addListener:self forAccountUuid:self.account.uuid];
        [serviceManager loadServiceDocumentForAccountUuid:self.account.uuid];
    }
}

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest
{
    self.repositories = [[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:self.account.uuid];

    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.account.uuid];
    [self.tableView reloadData];
    stopProgressHUD(self.progressHud);
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.account.uuid];
    stopProgressHUD(self.progressHud);
}

#pragma mark Table view datasource and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.repositories.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RepositoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    cell.textLabel.text = ([repositoryInfo tenantID] != nil) ? repositoryInfo.tenantID : repositoryInfo.repositoryName;
    cell.imageView.image = [UIImage imageNamed:kNetworkIcon_ImageName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    DocumentPickerViewController *newDocumentPickerViewController =
               [DocumentPickerViewController documentPickerForRepository:repositoryInfo];
    [self.documentPickerViewController.navigationController pushViewController:newDocumentPickerViewController animated:YES];
}

- (NSString *)titleForTable
{
    return self.account.description;
}


@end
