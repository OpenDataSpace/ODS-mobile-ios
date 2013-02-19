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
//  BrowseRepositoryNodeDelegate.h
//
// Conforms to UITableViewDelegate and will respond to user interaction with the datasource.
// The data from the repository must be supplied to this delegate since this delegate is not responsible for loading/reloading the data.
// Currently it uses code that is tightly coupled with the RepositoryNodeViewController but it will however work with any other view controller
// that wishes to display list of repository nodes. 
// A repository node is abstracted into RepositoryItemCellWrapper and can be subclassed to support other type of repository item concepts like sites.
// To get the latest array of respository items the tableView's datasource must respond to the repositoryItems selector in order for this delegate
// to work properly

#import <Foundation/Foundation.h>
#import "BaseHTTPRequest.h"
#import "AlfrescoMDMLite.h"
@class MBProgressHUD;
@class FolderItemsHTTPRequest;
@class RepositoryPreviewManagerDelegate;
@class ObjectByIdRequest;
@class UploadInfo;
@class RepositoryItemCellWrapper;
@class MultiSelectActionsToolbar;

@interface BrowseRepositoryNodeDelegate : NSObject <UITableViewDelegate, UIPopoverControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, ASIHTTPRequestDelegate, AlfrescoMDMServiceManagerDelegate>
{
    NSMutableArray *_itemsToDelete;
}
@property (nonatomic, readonly) NSMutableArray *repositoryItems;
@property (nonatomic, retain) MultiSelectActionsToolbar *multiSelectToolbar;
@property (nonatomic, retain) FolderItemsHTTPRequest *itemDownloader;
@property (nonatomic, retain) ObjectByIdRequest *metadataDownloader;
@property (nonatomic, retain) RepositoryPreviewManagerDelegate *previewDelegate;
@property (nonatomic, retain) UploadInfo *uploadToDismiss;
@property (nonatomic, retain) RepositoryItemCellWrapper *uploadToCancel;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, assign) id actionsDelegate;
@property (nonatomic, assign) id<UIScrollViewDelegate> scrollViewDelegate;
@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, copy) NSString *uplinkRelation;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, copy) NSString *tenantID;

/*
 The UIViewController MUST respond to the tableView selector in order to be initialized properly
 It is ideal that respond to the selectedAccountUUID and tenantID selectors but it is not required
 and both parameters can be set after this init
 */
- (id)initWithViewController:(UIViewController *)viewController;

@end
