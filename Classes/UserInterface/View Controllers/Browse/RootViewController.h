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
//  RootViewController.h
//

#import "FolderItemsHTTPRequest.h"
#import "DownloadProgressBar.h"
#import "CMISTypeDefinitionHTTPRequest.h"
#import "RepositoryInfo.h"
#import "MBProgressHUD.h"
#import "ASINetworkQueue.h"
#import "SitesManagerService.h"
#import "CMISServiceManager.h"
#import "EGORefreshTableHeaderView.h"
#import "SiteTableViewCell.h"

@class FavoritesSitesHttpRequest;

@interface RootViewController : UIViewController <
    ASIHTTPRequestDelegate,
    CMISServiceManagerListener,
    DownloadProgressBarDelegate,
    EGORefreshTableHeaderDelegate,
    MBProgressHUDDelegate,
    SitesManagerActionsDelegate,
    SitesManagerListener,
    SiteTableViewCellDelegate,
    UITableViewDataSource,
    UITableViewDelegate>
{
@private
    BOOL showSitesOptions;
    BOOL isAlfrescoAccount;
}

@property (nonatomic, retain) NSArray *allSites;
@property (nonatomic, retain) NSArray *mySites;
@property (nonatomic, retain) NSArray *favSites;
@property (nonatomic, retain) NSArray *activeSites;
@property (nonatomic, retain) NSArray *companyHomeItems;
@property (nonatomic, retain) FolderItemsHTTPRequest *itemDownloader;
@property (nonatomic, retain) FolderItemsHTTPRequest *companyHomeDownloader;
@property (nonatomic, retain) DownloadProgressBar *progressBar;
@property (nonatomic, retain) CMISTypeDefinitionHTTPRequest *typeDownloader;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIView *segmentedControlBkg;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) NSString *repositoryID;
@property (nonatomic, readwrite, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) NSString *selectedSiteType;
@property (nonatomic, retain) NSIndexPath *selectedIndex;
@property (nonatomic, retain) NSIndexPath *willSelectIndex;

- (void)refreshViewData;
- (void)metaDataChanged;
- (void)cancelAllHTTPConnections;

- (IBAction)segmentedControlChange:(id)sender;

- (UIButton *)makeDetailDisclosureButton;
- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event;

@end
