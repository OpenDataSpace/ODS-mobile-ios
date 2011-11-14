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
//  RepositoryNodeViewController.h
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "DownloadProgressBar.h"
#import "PostProgressBar.h"
#import "FolderItemsDownload.h"
#import "UploadFormTableViewController.h"
#import "SavedDocumentPickerController.h"
#import "DownloadQueueProgressBar.h"
#import "ASIHTTPRequest.h"
@class FolderDescendantsRequest;

@interface RepositoryNodeViewController : UITableViewController <DownloadProgressBarDelegate, PostProgressBarDelegate, AsynchronousDownloadDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UploadFormDelegate, SavedDocumentPickerDelegate, DownloadQueueDelegate, ASIHTTPRequestDelegate> 
{
	NSString *guid;
	FolderItemsDownload *folderItems;
    CMISTypeDefinitionDownload *metadataDownloader;
	DownloadProgressBar *downloadProgressBar;
    DownloadQueueProgressBar *downloadQueueProgressBar;
	PostProgressBar     *postProgressBar;
	FolderItemsDownload *itemDownloader;
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
}

@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) FolderItemsDownload *folderItems;
@property (nonatomic, retain) CMISTypeDefinitionDownload *metadataDownloader;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;
@property (nonatomic, retain) DownloadQueueProgressBar *downloadQueueProgressBar;
@property (nonatomic, retain) PostProgressBar     *postProgressBar;
@property (nonatomic, retain) FolderItemsDownload *itemDownloader;
@property (nonatomic, retain) FolderDescendantsRequest *folderDescendantsRequest;
@property (nonatomic, retain) NSData              *contentStream;
@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) UITextField *alertField;
@property (nonatomic, readwrite, retain) MBProgressHUD *HUD;

- (void)metaDataChanged;
- (UIButton *)makeDetailDisclosureButton;
- (void) accessoryButtonTapped: (UIControl *) button withEvent: (UIEvent *) event;
@end
