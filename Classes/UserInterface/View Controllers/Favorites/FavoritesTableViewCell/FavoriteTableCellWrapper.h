//
//  FavoriteTableCellWrapper.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 13/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
@class RepositoryItem;
@class UploadInfo;

@interface FavoriteTableCellWrapper : NSObject


@property (nonatomic, retain) NSString* accountUUID;
@property (nonatomic, retain) NSString* tenantID;

@property (nonatomic, copy) NSString *itemTitle;
@property (nonatomic, retain) RepositoryItem *repositoryItem;
@property (nonatomic, retain) UploadInfo *uploadInfo;
@property (nonatomic, assign) BOOL isSearchError;
@property (nonatomic, assign) NSInteger searchStatusCode;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, readonly) RepositoryItem *anyRepositoryItem;
@property (nonatomic, assign) BOOL isDownloadingPreview;
@property (nonatomic, retain) UITableViewCell *cell;

@property (nonatomic, retain) NSString * fileSize;

/*
 Use this initializer to create an repository item from a current/failed upload
 */
- (id)initWithUploadInfo:(UploadInfo *)uploadInfo;
/*
 Use this initializer to create a repository item wreapper from an existing repository item
 */
- (id)initWithRepositoryItem:(RepositoryItem *)repositoryItem;

/*
 Creates the right cell for the underlying representation of the Repository Item
 */
- (UITableViewCell *)createCellInTableView:(UITableView *)tableView;

// Create a default disclosure button
- (UIButton *)makeDetailDisclosureButton;

// Create a cancel button for preview
- (UIButton *)makeCancelPreviewDisclosureButton;

@end
