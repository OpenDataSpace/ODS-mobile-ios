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
#import "RepositoryInfo.h"
#import "Utility.h"
#import "DocumentPickerSiteTableDelegate.h"
#import "RepositoryItem.h"
#import "DocumentPickerViewController.h"
#import "SitesManagerService.h"
#import "DocumentPickerSelection.h"

@interface DocumentPickerSiteTableDelegate () <SitesManagerListener>

// Data
@property (nonatomic, assign) NSArray *currentlyDisplayedSites; // This is basically a pointer to any of the three NSArrays below. But having this around, makes the table methods much easier
@property (nonatomic, retain) NSArray *mySites;
@property (nonatomic, retain) NSArray *favoriteSites;
@property (nonatomic, retain) NSArray *allSites;

// View
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MBProgressHUD *progressHud;

@end


@implementation DocumentPickerSiteTableDelegate

@synthesize repositoryInfo = _repositoryInfo;
@synthesize tableView = _tableView;
@synthesize progressHud = _progressHud;
@synthesize documentPickerViewController = _documentPickerViewController;
@synthesize siteTypeToDisplay = _siteTypeToDisplay;
@synthesize mySites = _mySites;
@synthesize favoriteSites = _favoriteSites;
@synthesize allSites = _allSites;
@synthesize currentlyDisplayedSites = _currentlyDisplayedSites;


#pragma mark Init and dealloc

- (void)dealloc
{
    [_repositoryInfo release];
    [_tableView release];
    [_progressHud release];
    [_mySites release];
    [_favoriteSites release];
    [_allSites release];
    [super dealloc];
}

- (id)initWithRepositoryInfo:(RepositoryInfo *)repositoryInfo
{
    self = [super init];
    if (self)
    {
        _repositoryInfo = [repositoryInfo retain];
    }
    return self;
}

#pragma mark Data loading

- (void)loadDataForTableView:(UITableView *)tableView
{
    // Fire off async request if data not yet fetched
    if (self.mySites == nil)
    {
        // On the main thread, display the HUD
        self.progressHud = createAndShowProgressHUDForView(self.documentPickerViewController.view); // blocking the whole view, since we also want the segmentcontrol to block
        self.tableView = tableView;

        SitesManagerService * sitesManagerService = [SitesManagerService
                sharedInstanceForAccountUUID:self.repositoryInfo.accountUuid tenantID:self.repositoryInfo.tenantID];
        [sitesManagerService addListener:self];
        [sitesManagerService startOperations];
    }
    else
    {
        [self switchCurrentlyDisplayedSites];
    }
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

#pragma mark Table view datasource and delegate methods

- (void)tableViewDidLoad:(UITableView *)tableView
{
    if (self.documentPickerViewController.selection.isSiteSelectionEnabled)
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
    return self.currentlyDisplayedSites.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SiteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    RepositoryItem *repositoryItem = [self.currentlyDisplayedSites objectAtIndex:indexPath.row];
    cell.textLabel.text = repositoryItem.title;
    cell.imageView.image = [UIImage imageNamed:@"site.png"];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

    http://stackoverflow.com/questions/2501386/uitableviewcell-setselected-but-selection-not-shown
    if ([self isSiteSelected:repositoryItem])
    {
        [[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }

    return cell;
}

- (BOOL)isSiteSelected:(RepositoryItem *)siteToCheck
{
    for (RepositoryItem *site in self.documentPickerViewController.selection.selectedSites)
    {
        if ([site.guid isEqualToString:siteToCheck.guid])
        {
            return YES;
        }
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
        newDocumentPickerViewController.selection = self.documentPickerViewController.selection; // copying setting for selection, and already selected items
        [self.documentPickerViewController.navigationController pushViewController:newDocumentPickerViewController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.documentPickerViewController.selection.isSiteSelectionEnabled)
    {
        RepositoryItem *site = [self.currentlyDisplayedSites objectAtIndex:indexPath.row];
        [self.documentPickerViewController.selection removeSite:site];
    }
    NSLog(@"-----> %d", self.documentPickerViewController.selection.selectedSites.count);
}

- (NSString *)titleForTable
{
    return ([self.repositoryInfo tenantID] != nil) ? self.repositoryInfo.tenantID : self.repositoryInfo.repositoryName;
}


@end
