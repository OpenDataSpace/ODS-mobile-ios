//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
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
#import "ServiceDocumentRequest.h"

@interface RootViewController : UITableViewController <AsynchronousDownloadDelegate, DownloadProgressBarDelegate, MBProgressHUDDelegate> {
	NSArray *siteInfo;
	NSArray *companyHomeItems;
	AsynchonousDownload *cmisSitesQuery; // !!!: Change back to CMISGetSites
	FolderItemsDownload *itemDownloader;
	FolderItemsDownload *companyHomeDownloader;
	DownloadProgressBar *progressBar;
	CMISTypeDefinitionDownload *typeDownloader;
    ServiceDocumentRequest *serviceDocumentRequest;
	RepositoryInfo *currentRepositoryInfo;
	
@private
	MBProgressHUD *HUD;
}

@property (nonatomic, retain) NSArray *siteInfo;
@property (nonatomic, retain) NSArray *companyHomeItems;
@property (nonatomic, retain) AsynchonousDownload *cmisSitesQuery;
@property (nonatomic, retain) FolderItemsDownload *itemDownloader;
@property (nonatomic, retain) FolderItemsDownload *companyHomeDownloader;
@property (nonatomic, retain) DownloadProgressBar *progressBar;
@property (nonatomic, retain) CMISTypeDefinitionDownload *typeDownloader;
@property (nonatomic, retain) RepositoryInfo *currentRepositoryInfo;
@property (nonatomic, readwrite, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) ServiceDocumentRequest *serviceDocumentRequest;

- (void)metaDataChanged;
- (void)cancelAllHTTPConnections;

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)sender;
- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)sender;

@end
