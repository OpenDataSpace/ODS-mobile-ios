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
//  DownloadsViewController.h
//

#import <UIKit/UIKit.h>

#import "DirectoryWatcher.h"
#import "CMISTypeDefinitionHTTPRequest.h"
#import "DocumentFilter.h"
#import "CMISServiceManager.h"
#import "AlfrescoMDMLite.h"

@class FolderTableViewDataSource;
@class MBProgressHUD;
@class FolderTableViewDataSource;
//
//	TODO: Rename this class to something to the terms of "LocalFileSystemBrowser"
//


@interface DownloadsViewController : UITableViewController <DirectoryWatcherDelegate, UIDocumentInteractionControllerDelegate, CMISServiceManagerListener, AlfrescoMDMServiceManagerDelegate>

@property (nonatomic, retain) DirectoryWatcher *dirWatcher;
@property (nonatomic, retain) NSURL *selectedFile;
@property (nonatomic, retain) FolderTableViewDataSource *folderDatasource;
@property (nonatomic, retain) id<DocumentFilter> documentFilter;

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher;
- (void)detailViewControllerChanged:(NSNotification *)notification;
@end

