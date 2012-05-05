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

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DownloadProgressBar.h"
#import "PostProgressBar.h"
#import "FolderItemsHTTPRequest.h"
#import "UploadFormTableViewController.h"
#import "SavedDocumentPickerController.h"
#import "DownloadQueueProgressBar.h"
#import "ASIHTTPRequest.h"
#import "AccountInfo.h"
#import "PhotoCaptureSaver.h"

@class CMISSearchHTTPRequest;
@class FolderDescendantsRequest;
@class CMISTypeDefinitionHTTPRequest;

@interface RepositoryNodeViewController : UIViewController <DownloadProgressBarDelegate, PostProgressBarDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UploadFormDelegate, SavedDocumentPickerDelegate, DownloadQueueDelegate, ASIHTTPRequestDelegate, UISearchDisplayDelegate, UISearchBarDelegate, PhotoCaptureSaverDelegate, UITableViewDataSource, UITableViewDelegate> 
{
	NSString *guid;
	FolderItemsHTTPRequest *folderItems;
    CMISTypeDefinitionHTTPRequest *metadataDownloader;
	DownloadProgressBar *downloadProgressBar;
    DownloadQueueProgressBar *downloadQueueProgressBar;
	PostProgressBar     *postProgressBar;
	FolderItemsHTTPRequest *itemDownloader;
    FolderDescendantsRequest *folderDescendantsRequest;
	NSData              *contentStream;
	UIPopoverController *popover;

	UITextField *alertField;
	BOOL replaceData;
    
    NSIndexPath *selectedIndex;
    NSIndexPath *willSelectIndex;
    
    MBProgressHUD *HUD;
    NSInteger hudCount;
    
    NSMutableArray *childsToDownload;
    NSMutableArray *childsToOverwrite;
    BOOL shouldForceReload;
    UISearchDisplayController *searchController;
    CMISSearchHTTPRequest *searchRequest;
    PhotoCaptureSaver *photoSaver;
    UITableView *_tableView;
    UITableViewStyle _tableViewStyle;
    
    NSString *selectedAccountUUID;
    NSString *tenantID;
}

@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) FolderItemsHTTPRequest *folderItems;
@property (nonatomic, retain) CMISTypeDefinitionHTTPRequest *metadataDownloader;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;
@property (nonatomic, retain) DownloadQueueProgressBar *downloadQueueProgressBar;
@property (nonatomic, retain) PostProgressBar     *postProgressBar;
@property (nonatomic, retain) FolderItemsHTTPRequest *itemDownloader;
@property (nonatomic, retain) FolderDescendantsRequest *folderDescendantsRequest;
@property (nonatomic, retain) NSData              *contentStream;
@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) UITextField *alertField;
@property (nonatomic, readwrite, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) UISearchDisplayController *searchController;
@property (nonatomic, retain) CMISSearchHTTPRequest *searchRequest;
@property (nonatomic, retain) PhotoCaptureSaver *photoSaver;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;

- (void)reloadFolderAction;
- (UIButton *)makeDetailDisclosureButton;
- (void) accessoryButtonTapped: (UIControl *) button withEvent: (UIEvent *) event;

- (id)initWithStyle:(UITableViewStyle)style;
@end
