//
//  RootViewController.h
//  Alfresco
//
//  Created by Michael Muller on 9/1/09.
//  Copyright Zia Consulting 2009. All rights reserved.
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
