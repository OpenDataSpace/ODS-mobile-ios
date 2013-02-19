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
//  SearchRepositoryNodeDelegate.h
//
// Provides a independent search controller delegate that can search a node (and descendants nodes)
// and attaches in the header of the supplied viewController.tableView (must respond to this selector) in the init method.
// Since it can handle the navigation into an item preview a navigationController of the current ViewController (or any other by setting the property)
// it will use the detail view in the case of the app running in an iPad.
// It's currently highly decoupled from any specific ViewController and it can be attached to virtually any view controller that reponds to the
// tableView selector, the search will be performed starting in the supplied repositoryNodeGuid

#import <Foundation/Foundation.h>
#import "AlfrescoMDMLite.h"
@class RepositoryPreviewManagerDelegate;
@class MBProgressHUD;
@class ObjectByIdRequest;
@class CMISSearchHTTPRequest;

@interface SearchRepositoryNodeDelegate : NSObject <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDelegate, UITableViewDataSource, AlfrescoMDMLiteDelegate, AlfrescoMDMServiceManagerDelegate>

@property (nonatomic, retain) NSMutableArray *repositoryItems;
@property (nonatomic, retain) RepositoryPreviewManagerDelegate *previewDelegate;
@property (nonatomic, retain) ObjectByIdRequest *metadataDownloader;
@property (nonatomic, retain) CMISSearchHTTPRequest *searchRequest;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) UISearchDisplayController *searchController;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, copy) NSString *repositoryNodeGuid;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, copy) NSString *tenantID;

/*
 The UIViewController MUST respond to the tableView selector in order to be initialized properly
 It is ideal that respond to the selectedAccountUUID and tenantID selectors but it is not required
 and both parameters can be set after this init
 */
- (id)initWithViewController:(UIViewController *)viewController;

@end
