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
// DocumentPickerSiteTableDelegate
//
#import "DocumentPickerSiteTableDelegate.h"
#import "RepositoryInfo.h"
#import "Utility.h"
#import "RepositoryItem.h"
#import "SitesManagerService.h"
#import "DocumentPickerSelection.h"
#import "AccountInfo.h"
#import "CMISServiceManager.h"
#import "RepositoryServices.h"

@interface DocumentPickerSiteTableDelegate () <SitesManagerListener, CMISServiceManagerListener>

@property (nonatomic, retain) AccountInfo *account;

// Data
@property (nonatomic, assign) NSArray *currentlyDisplayedSites; // This is basically a pointer to any of the three NSArrays below. But having this around, makes the table methods much easier
@property (nonatomic, retain) NSArray *mySites;
@property (nonatomic, retain) NSArray *favoriteSites;
@property (nonatomic, retain) NSArray *allSites;

@end


@implementation DocumentPickerSiteTableDelegate

@synthesize repositoryInfo = _repositoryInfo;
@synthesize siteTypeToDisplay = _siteTypeToDisplay;
@synthesize mySites = _mySites;
@synthesize favoriteSites = _favoriteSites;
@synthesize allSites = _allSites;
@synthesize currentlyDisplayedSites = _currentlyDisplayedSites;
@synthesize account = _account;


#pragma mark Init and dealloc

- (void)dealloc
{
    [_repositoryInfo release];
    [_mySites release];
    [_favoriteSites release];
    [_allSites release];
    [_account release];
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

- (id)initWithRepositoryInfo:(RepositoryInfo *)repositoryInfo
{
    self = [self init];
    if (self)
    {
        _repositoryInfo = [repositoryInfo retain];
    }
    return self;
}

- (id)initWithAccount:(AccountInfo *)account
{
    self = [self init];
    if (self)
    {
        _account = [account retain];
    }
    return self;
}


#pragma mark Implementation of DocumentPickerTableDelegateFunctionality protocol

- (NSInteger)tableCount
{
    return self.currentlyDisplayedSites.count;
}

- (BOOL)isDataAvailable
{
    return self.mySites != nil;  // Chose my sites here, but can any of the three arrays, as they are fetched together (sadly :( )
}

// Need to override here, as the default impl will not do the switching when changing site type
- (void)loadDataForTableView:(UITableView *)tableView
{
    [super loadDataForTableView:tableView];

    if (self.mySites != nil)
    {
        [self switchCurrentlyDisplayedSites];
    }
}

- (void)loadData
{
    // If the account property is set, we haven't fetched the repository info yet, so we must do that now
    if (self.account != nil)
    {
        [self loadAccount];
    }
    else
    {
        [self loadSites];
    }
}

- (void)loadAccount
{
    CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
    [serviceManager addListener:self forAccountUuid:self.account.uuid];
    [serviceManager loadServiceDocumentForAccountUuid:self.account.uuid];
}

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest
{
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.account.uuid];

    NSArray *repositories = [[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:self.account.uuid];
    if (repositories.count > 1)
    {
        NSLog(@"[WARNING] Got multiple repositories back, but only 1 is supported here!");
    }
    else if (repositories.count == 1)
    {
        self.repositoryInfo = [repositories objectAtIndex:0];
        [self loadSites];
    }
    else
    {
        stopProgressHUD(self.progressHud);
    }
}

- (void)loadSites
{
    SitesManagerService *sitesManagerService = [SitesManagerService
            sharedInstanceForAccountUUID:self.repositoryInfo.accountUuid tenantID:self.repositoryInfo.tenantID];
    [sitesManagerService addListener:self];
    [sitesManagerService startOperations];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.account.uuid];
    stopProgressHUD(self.progressHud);
}

- (void)siteManagerFinished:(SitesManagerService *)siteManager
{
    // Copy data
    self.mySites = siteManager.mySites;
    self.allSites = siteManager.allSites;
    self.favoriteSites = siteManager.favoriteSites;

    // Remove self as listener
    [siteManager removeListener:self];

    // Update UI
    [self switchCurrentlyDisplayedSites];
}

- (void)switchCurrentlyDisplayedSites
{
    switch (self.siteTypeToDisplay)
    {
        case DocumentPickerSiteTypeMySites :
            self.currentlyDisplayedSites = self.mySites;
            break;
        case DocumentPickerSiteTypeAllSites :
            self.currentlyDisplayedSites = self.allSites;
            break;
        case DocumentPickerSiteTypeFavoriteSites :
            self.currentlyDisplayedSites = self.favoriteSites;
            break;
    }

    stopProgressHUD(self.progressHud);
    [self.tableView reloadData];
}

- (void)siteManagerFailed:(SitesManagerService *)siteManager
{
    stopProgressHUD(self.progressHud);
}

- (void)customizeTableViewCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItem *repositoryItem = [self.currentlyDisplayedSites objectAtIndex:indexPath.row];
    cell.textLabel.text = repositoryItem.title;
    cell.imageView.image = [UIImage imageNamed:@"site.png"];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
}

- (BOOL)isSelectionEnabled
{
    return self.documentPickerViewController.selection.isSiteSelectionEnabled;
}

- (BOOL)isSelected:(NSIndexPath *)indexPath
{
    RepositoryItem *repositoryItem = [self.currentlyDisplayedSites objectAtIndex:indexPath.row];
    return [self.documentPickerViewController.selection containsSite:repositoryItem];
}

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItem *site = [self.currentlyDisplayedSites objectAtIndex:indexPath.row];
    if (self.documentPickerViewController.selection.isSiteSelectionEnabled)
    {
        [self.documentPickerViewController.selection addSite:site];
    }
    else // Go one level deeper
    {
        DocumentPickerViewController *newDocumentPickerViewController = [DocumentPickerViewController
                documentPickerForRepositoryItem:site accountUuid:self.repositoryInfo.accountUuid tenantId:self.repositoryInfo.tenantID];
        [self goOneLevelDeeperWithDocumentPicker:newDocumentPickerViewController];
    }
}

- (void)didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.documentPickerViewController.selection.isSiteSelectionEnabled)
    {
        RepositoryItem *site = [self.currentlyDisplayedSites objectAtIndex:indexPath.row];
        [self.documentPickerViewController.selection removeSite:site];
    }
}

- (NSString *)titleForTable
{
    if (self.account != nil)
    {
        return self.account.description;
    }
    else
    {
        return ([self.repositoryInfo tenantID] != nil) ? self.repositoryInfo.tenantID : self.repositoryInfo.repositoryName;
    }
}

- (void)clearCachedData
{
    self.currentlyDisplayedSites = nil;
    self.mySites = nil;
    self.favoriteSites = nil;
    self.allSites = nil;
}


@end
