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
//  SearchViewController.h
//

#import <UIKit/UIKit.h>
#import "DownloadProgressBar.h"
#import "SelectSiteViewController.h"
#import "CMISServiceManager.h"
@class BaseHTTPRequest;
@class ServiceDocumentRequest;
@class SearchPreviewManagerDelegate;

@interface SearchViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, SelectSiteDelegate, ASIHTTPRequestDelegate, CMISServiceManagerListener> {
@private
	IBOutlet UISearchBar *search;
	IBOutlet UITableView *table;
	NSMutableArray *results;
	BaseHTTPRequest *searchDownload;
    NSIndexPath *selectedIndex;
    NSIndexPath *willSelectIndex;
    ServiceDocumentRequest *serviceDocumentRequest;
    MBProgressHUD *HUD;                                                    
    TableViewNode *selectedSearchNode;
    NSString *selectedAccountUUID;
    NSString *savedTenantID;
}	

@property (nonatomic, retain) UISearchBar *search;
@property (nonatomic, retain) UITableView *table;
@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) BaseHTTPRequest *searchDownload;
@property (nonatomic, retain) ServiceDocumentRequest *serviceDocumentRequest;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) TableViewNode *selectedSearchNode;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *savedTenantID;
@property (nonatomic, retain) SearchPreviewManagerDelegate *previewDelegate;

//- (IBAction)searchBarSearchButtonClicked:(UISearchBar *)searchBar;
///- (IBAction)searchBarCancelButtonClicked:(UISearchBar *)searchBar;

@end
