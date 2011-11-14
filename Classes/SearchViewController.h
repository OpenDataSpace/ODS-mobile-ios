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
//  SearchViewController.h
//

#import <UIKit/UIKit.h>
#import "DownloadProgressBar.h"
#import "SearchResultsDownload.h"
#import "SelectSiteViewController.h"
@class ServiceDocumentRequest;

@interface SearchViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, DownloadProgressBarDelegate, AsynchronousDownloadDelegate, SelectSiteDelegate> {
@private
	IBOutlet UISearchBar *search;
	IBOutlet UITableView *table;
	NSMutableArray *results;
	DownloadProgressBar *progressBar;
	AsynchonousDownload *searchDownload;
    NSIndexPath *selectedIndex;
    NSIndexPath *willSelectIndex;
    ServiceDocumentRequest *serviceDocumentRequest;
    MBProgressHUD *HUD;                                                    
    RepositoryItem *selectedSite;
}	

@property (nonatomic, retain) UISearchBar *search;
@property (nonatomic, retain) UITableView *table;
@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) DownloadProgressBar *progressBar;
@property (nonatomic, retain) AsynchonousDownload *searchDownload;
@property (nonatomic, retain) ServiceDocumentRequest *serviceDocumentRequest;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) RepositoryItem *selectedSite;

//- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async;
//- (void) asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error;
//- (IBAction)searchBarSearchButtonClicked:(UISearchBar *)searchBar;
///- (IBAction)searchBarCancelButtonClicked:(UISearchBar *)searchBar;

@end
