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
//  RepositoryNodeDataSource.h
//
// A generic repository node data source that can be initialized with different arguments
// depending on the way we want to retrieve the repository node data (children, etc.)
// This DataSource supports initializing by:
// ObjectId
// CMIS Path
// Repository node description (RepositoryItem instance)

#import <Foundation/Foundation.h>
#import "RepositoryItem.h"
#import "MBProgressHUD.h"

@protocol RepositoryNodeDataSourceDelegate <NSObject>

- (void)dataSourceFinishedLoadingWithSuccess:(BOOL)wasSuccessful;

@end

@interface RepositoryNodeDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, retain) NSArray *nodeChildren;
@property (nonatomic, retain) RepositoryItem *repositoryNode;
@property (nonatomic, retain) id reloadRequest;
@property (nonatomic, retain) NSMutableArray *repositoryItems;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, copy) NSString *tenantID;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, readonly) BOOL isReloading;
@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) SEL reloadRequestFactory;
@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, copy) NSString *cmisPath;

- (id)initWithSelectedAccountUUID:(NSString *)selectedAccountUUID tenantID:(NSString *)tenantID;

// Returns a Repository Node Data Source initialized with a repository node
// The reload action will be the getChildren request.
// 
- (id)initWithRepositoryItem:(RepositoryItem *)repositoryNode andSelectedAccount:(NSString *)selectedAccountUUID;

// Returns a Repository Node Data Source initialized with a cmis path
// The reload action will be the ObjectByPath request
// 
- (id)initWithCMISPath:(NSString *)cmisPath selectedAccount:(NSString *)uuid tenantID:(NSString *)tenantID;

// Returns a Repository Node Data Source initialized with an object id
// The reload action will be the ObjectById request
// 
- (id)initWithObjectId:(NSString *)objectId selectedAccount:(NSString *)uuid tenantID:(NSString *)tenantID;


// If the children were already retrieved we should use this method to preload the datasource
// The reload action will replace this childrens
- (void)preLoadChildren:(NSArray *)children;

// Reloads the data source by calling the backend
// The actual implementation or webservice call will vary depending of the
// init used. After the asynchronous request a [tableView reloadData] will be 
// performed to reload the tableView
- (void)reloadDataSource;

// Adds a list of uploads to the repository wrappers
- (void)addUploadsToRepositoryItems:(NSArray *)uploads insertCells:(BOOL)insertCells;

@end
