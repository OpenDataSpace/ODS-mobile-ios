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
//  FavoritesViewController.h
//

#import <UIKit/UIKit.h>
#import "FavoriteManager.h"

#import "IFGenericTableViewController.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"
#import "DownloadProgressBar.h"
#import "CMISServiceManager.h"
#import "EGORefreshTableHeaderView.h"
#import "UploadInfo.h"
#import "DownloadInfo.h"

@class FavoritesHttpRequest;
@class ObjectByIdRequest;
@class CMISTypeDefinitionHTTPRequest;
@class FavoritesTableViewDataSource;
@class FavoritesDownloadManagerDelegate;
@class FavoriteTableCellWrapper;


@interface FavoritesViewController : UITableViewController <FavoriteManagerDelegate, EGORefreshTableHeaderDelegate, MBProgressHUDDelegate, UIPopoverControllerDelegate>

@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) FavoritesHttpRequest *favoritesRequest;
@property (nonatomic, retain) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic, retain) NSDate *lastUpdated;

@property (nonatomic, retain) FavoriteTableCellWrapper * wrapperToRetry;
@property (nonatomic, retain) UIPopoverController *popover;

@property (nonatomic, retain) FavoritesDownloadManagerDelegate *favoriteDownloadManagerDelegate;

@property (nonatomic, retain) FavoritesTableViewDataSource *folderDatasource;

- (void)detailViewControllerChanged:(NSNotification *)notification;


@end
