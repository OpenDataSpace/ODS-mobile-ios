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
//  RepositoryNodeViewController.h
//
// Used to display the contents of a repository node.
// It can:
// - Browse into another respository folder (node)
// - Search in the current node and descendants
// - Add or delete repository documents
// Regarding the data for the table view, this controller is reposible of loading and reloading the current
// data (listing for the current node) and everything that is in the navigation bar (adding documents or folders)
// and toolbar (multiselect document for downloading/deleting)
// The actual delegate for the tableView will be a BrowseRepositoryNodeDelegate
// Everything related to the contextual search will be handled by the SearchRepositoryNodeDelegate

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "FolderItemsHTTPRequest.h"
#import "UploadFormTableViewController.h"
#import "SavedDocumentPickerController.h"
#import "DownloadQueueProgressBar.h"
#import "DeleteQueueProgressBar.h"
#import "ASIHTTPRequest.h"
#import "AccountInfo.h"
#import "PhotoCaptureSaver.h"
#import "EGORefreshTableHeaderView.h"
#import "MultiSelectActionsToolbar.h"
#import "PreviewManager.h"
#import "DownloadManager.h"
#import "ObjectByIdRequest.h"
#import "RepositoryNodeDataSource.h"
#import "CreateFolderViewController.h"
#import "RenameQueueProgressBar.h"
#import "MoveQueueProgressBar.h"
#import "ChooserFolderViewController.h"
#import "CreateLinkViewController.h"

@class CMISSearchHTTPRequest;
@class FolderDescendantsRequest;
@class CMISTypeDefinitionHTTPRequest;
@class RepositoryItemCellWrapper;
@class BrowseRepositoryNodeDelegate;
@class SearchRepositoryNodeDelegate;


@interface RepositoryNodeViewController : UIViewController < // Protocols alphabetized & on separate lines to help source control!
    ASIHTTPRequestDelegate,
    CreateFolderRequestDelegate,
    CreateLinkRequestDelegate,
    DeleteQueueDelegate,
    RenameQueueDelegate,
    MoveQueueDelegate,
    DownloadQueueDelegate,
    EGORefreshTableHeaderDelegate,
    MultiSelectActionsDelegate,
    PhotoCaptureSaverDelegate,
    RepositoryNodeDataSourceDelegate,
    SavedDocumentPickerDelegate,
    ChooserFolderDelegate,
    UIActionSheetDelegate,
    UIAlertViewDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    UIPopoverControllerDelegate,
    UIScrollViewDelegate,
    UISearchBarDelegate,
    UISearchDisplayDelegate>
{
    NSInteger _hudCount;
    
    NSMutableArray *_childsToDownload;
    NSMutableArray *_childsToOverwrite;
    NSMutableArray *_itemsToDelete;
    NSMutableArray *_itemsToMove;
    UITableViewStyle _tableViewStyle;
}

@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) FolderItemsHTTPRequest *folderItems;
@property (nonatomic, retain) DownloadQueueProgressBar *downloadQueueProgressBar;
@property (nonatomic, retain) DeleteQueueProgressBar *deleteQueueProgressBar;
@property (nonatomic, retain) RenameQueueProgressBar *renameQueueProgressBar;
@property (nonatomic, retain) MoveQueueProgressBar *moveQueueProgressBar;
@property (nonatomic, retain) FolderDescendantsRequest *folderDescendantsRequest;
@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) UITextField *alertField;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) PhotoCaptureSaver *photoSaver;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) UIBarButtonItem *actionSheetSenderControl;
@property (nonatomic, assign) CGRect  actionSheetSenderRect;
@property (nonatomic, retain) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic, retain) NSDate *lastUpdated;
@property (nonatomic, retain) MultiSelectActionsToolbar *multiSelectToolbar;
@property (nonatomic, retain) BrowseRepositoryNodeDelegate *browseDelegate;
@property (nonatomic, retain) RepositoryNodeDataSource *browseDataSource;
@property (nonatomic, retain) SearchRepositoryNodeDelegate *searchDelegate;
@property (nonatomic, retain) UIImagePickerController *imagePickerController;
@property (nonatomic, retain) RepositoryItem *selectedItem;

- (id)initWithStyle:(UITableViewStyle)style;

- (void)enableNavigationRightBarItem:(BOOL) bEnable;
@end
