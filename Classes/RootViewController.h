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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  RootViewController.h
//

#import "FolderItemsDownload.h"
#import "DownloadProgressBar.h"
#import "CMISTypeDefinitionDownload.h"
#import "CMISGetSites.h"
#import "SiteListDownload.h"
#import "RepositoryInfo.h"
#import "ServiceDocumentRequest.h"
#import "MBProgressHUD.h"
#import "SimpleSettingsViewController.h"
#import "ASINetworkQueue.h"
#import "SitesManagerService.h"
@class FavoritesSitesHttpRequest;

@interface RootViewController : UIViewController <AsynchronousDownloadDelegate, DownloadProgressBarDelegate, MBProgressHUDDelegate, SimpleSettingsViewDelegate, SitesManagerListener> {
	NSArray *allSites;
    NSArray *mySites;
    NSArray *favSites;
    NSArray *activeSites;
	NSArray *companyHomeItems;
	FolderItemsDownload *itemDownloader;
	FolderItemsDownload *companyHomeDownloader;
	DownloadProgressBar *progressBar;
	CMISTypeDefinitionDownload *typeDownloader;
    ServiceDocumentRequest *serviceDocumentRequest;
	RepositoryInfo *currentRepositoryInfo;
    UISegmentedControl *segmentedControl;
    UITableView *_tableView;
    UIView *segmentedControlBkg;
@private
	MBProgressHUD *HUD;
    BOOL shouldForceReload;
    BOOL showSitesOptions;
    NSString *selectedSiteType;
    
    NSIndexPath *selectedIndex;
    NSIndexPath *willSelectIndex;
}

@property (nonatomic, retain) NSArray *allSites;
@property (nonatomic, retain) NSArray *mySites;
@property (nonatomic, retain) NSArray *favSites;
@property (nonatomic, retain) NSArray *activeSites;
@property (nonatomic, retain) NSArray *companyHomeItems;
@property (nonatomic, retain) FolderItemsDownload *itemDownloader;
@property (nonatomic, retain) FolderItemsDownload *companyHomeDownloader;
@property (nonatomic, retain) DownloadProgressBar *progressBar;
@property (nonatomic, retain) CMISTypeDefinitionDownload *typeDownloader;
@property (nonatomic, retain) ServiceDocumentRequest *serviceDocumentRequest;
@property (nonatomic, retain) RepositoryInfo *currentRepositoryInfo;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIView *segmentedControlBkg;

@property (nonatomic, readwrite, retain) MBProgressHUD *HUD;

- (IBAction)showLoginCredentialsView:(id)sender;

- (void)refreshViewData;
- (void)metaDataChanged;
- (void)cancelAllHTTPConnections;

- (void)serviceDocumentRequestFinished:(ASIHTTPRequest *)sender;
- (void)serviceDocumentRequestFailed:(ASIHTTPRequest *)sender;

- (IBAction)segmentedControlChange:(id)sender;

- (UIButton *)makeDetailDisclosureButton;
- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event;

@end
