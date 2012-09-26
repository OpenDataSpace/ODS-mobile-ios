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
//  FavoriteTableCellWrapper.h
//

#import <Foundation/Foundation.h>
@class RepositoryItem;
@class UploadInfo;
@class FavoriteTableViewCell;

typedef enum 
{
    SyncFailed,
    SyncSuccessful,  
    SyncLoading,
    SyncWaiting,
    SyncOffline,
    SyncCancelled,
    SyncDisabled,
} SyncStatus;

typedef enum 
{
    IsFavorite,
    IsNotFavorite,
} Document;

typedef enum
{
    Download,
    Upload,
    None
    
} ActivityType;


@interface FavoriteTableCellWrapper : NSObject


@property (nonatomic, retain) NSString* accountUUID;
@property (nonatomic, retain) NSString* tenantID;

@property (nonatomic, copy)   NSString *itemTitle;
@property (nonatomic, retain) RepositoryItem *repositoryItem;
@property (nonatomic, retain) UploadInfo *uploadInfo;
@property (nonatomic, assign) BOOL isSearchError;
@property (nonatomic, assign) NSInteger searchStatusCode;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, readonly) RepositoryItem *anyRepositoryItem;
@property (nonatomic, assign) BOOL isActivityInProgress;
@property (nonatomic, assign) BOOL isPreviewInProgress;
@property (nonatomic, retain) UITableViewCell *cell;
@property (nonatomic, assign) BOOL isSelected;

@property (nonatomic, retain) NSString * fileSize;

@property (nonatomic, assign) SyncStatus syncStatus;
@property (nonatomic, assign) Document document;
@property (nonatomic, assign) ActivityType activityType;
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
-(void) updateCellDetails:(UITableViewCell *) cell;

- (void) updateSyncStatus:(SyncStatus)status forCell:(FavoriteTableViewCell*)cell;
- (void) favoriteOrUnfavoriteDocument;

// Create a default disclosure button
- (UIButton *)makeDetailDisclosureButton;

// Create a cancel button for preview
- (UIButton *)makeCancelPreviewDisclosureButton;
- (UIButton *)makeFailureDisclosureButton;

@end
