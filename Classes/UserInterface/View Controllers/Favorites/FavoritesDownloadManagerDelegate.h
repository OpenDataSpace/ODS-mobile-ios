//
//  FavoritesDownloadManagerDelegate.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 13/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FavoriteDownloadManager.h"
#import "PreviewManager.h"

@interface FavoritesDownloadManagerDelegate : NSObject <PreviewManagerDelegate>


@property (nonatomic, retain) NSMutableArray *repositoryItems;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, assign) BOOL presentNewDocumentPopover;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, copy) NSString *tenantID;


- (NSIndexPath *)indexPathForNodeWithGuid:(NSString *)itemGuid;

@end
