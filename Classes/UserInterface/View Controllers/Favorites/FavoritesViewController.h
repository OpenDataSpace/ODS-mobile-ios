//
//  FavoritesViewController.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FavoriteManager.h"

#import "IFGenericTableViewController.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"
#import "DownloadProgressBar.h"
#import "CMISServiceManager.h"
#import "EGORefreshTableHeaderView.h"

#import "DirectoryWatcher.h"

@class FavoritesHttpRequest;
@class ObjectByIdRequest;
@class CMISTypeDefinitionHTTPRequest;
@class FavoritesTableViewDataSource;

@interface FavoritesViewController : UITableViewController <FavoriteManagerDelegate, EGORefreshTableHeaderDelegate, MBProgressHUDDelegate,DirectoryWatcherDelegate>
{
    @private
    MBProgressHUD *HUD;
    FavoritesHttpRequest *favoritesRequest;
    DownloadProgressBar *downloadProgressBar;
}

@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) FavoritesHttpRequest *favoritesRequest;
@property (nonatomic, retain) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic, retain) NSDate *lastUpdated;


@property (nonatomic, retain) DirectoryWatcher *dirWatcher;
@property (nonatomic, retain) FavoritesTableViewDataSource *folderDatasource;

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher;
- (void)detailViewControllerChanged:(NSNotification *)notification;

@end
