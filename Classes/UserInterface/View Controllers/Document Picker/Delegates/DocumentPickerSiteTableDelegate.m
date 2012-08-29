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
#import "AccountManager.h"

@interface DocumentPickerSiteTableDelegate () <SitesManagerListener, CMISServiceManagerListener>

@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) NSString *tenantID;

// Data
@property (nonatomic, assign) NSArray *currentlyDisplayedSites; // This is basically a pointer to any of the three NSArrays below. But having this around, makes the table methods much easier
@property (nonatomic, retain) NSArray *mySites;
@property (nonatomic, retain) NSArray *favoriteSites;
@property (nonatomic, retain) NSArray *allSites;

@end


@implementation DocumentPickerSiteTableDelegate

@synthesize siteTypeToDisplay = _siteTypeToDisplay;
@synthesize mySites = _mySites;
@synthesize favoriteSites = _favoriteSites;
@synthesize allSites = _allSites;
@synthesize currentlyDisplayedSites = _currentlyDisplayedSites;
@synthesize tenantID = _tenantID;
@synthesize accountUUID = _accountUUID;


#pragma mark Init and dealloc

- (void)dealloc
{
    [_mySites release];
    [_favoriteSites release];
    [_allSites release];
    [_tenantID release];
    [_accountUUID release];
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

- (id)initWithAccount:(NSString *)accountUUID tenantId:(NSString *)tenantID;
{
    self = [self init];
    if (self)
    {
        _accountUUID = [accountUUID retain];
        _tenantID = [tenantID retain];
    }
    return self;
}

- (id)initWithAccountUUID:(NSString *)accountUUID;
{
    self = [self init];
    if (self)
    {
        _accountUUID = [accountUUID retain];
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
    if (self.accountUUID != nil && self.tenantID == nil)
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
    [serviceManager addListener:self forAccountUuid:self.accountUUID];
    [serviceManager loadServiceDocumentForAccountUuid:self.accountUUID];
}

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest
{
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.accountUUID];

    NSArray *repositories = [[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:self.accountUUID];
    if (repositories.count > 1)
    {
        NSLog(@"[WARNING] Got multiple repositories back, but only 1 is supported here!");
    }
    else if (repositories.count == 1)
    {
        RepositoryInfo *repositoryInfo = [repositories objectAtIndex:0];
        self.tenantID = repositoryInfo.tenantID;
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
            sharedInstanceForAccountUUID:self.accountUUID tenantID:self.tenantID];
    [sitesManagerService addListener:self];
    [sitesManagerService startOperations];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.accountUUID];
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
                documentPickerForRepositoryItem:site accountUuid:self.accountUUID tenantId:self.tenantID];
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
    if (self.accountUUID != nil)
    {
        return [[AccountManager sharedManager] accountInfoForUUID:self.accountUUID].description;
    }
    else
    {
        RepositoryInfo *repositoryInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:self.accountUUID tenantID:self.tenantID];
        return ([repositoryInfo tenantID] != nil) ? repositoryInfo.tenantID : repositoryInfo.repositoryName;
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
