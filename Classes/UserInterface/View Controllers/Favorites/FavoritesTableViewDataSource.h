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
//  FavoritesTableViewDataSource.h
//

#import <Foundation/Foundation.h>
#import "FavoriteDownloadManager.h"

@interface FavoritesTableViewDataSource : NSObject <UITableViewDataSource>
{
@private
    float totalFilesSize;
}
@property (nonatomic, readonly, retain) NSURL *folderURL;
@property (nonatomic, readonly, retain) NSString *folderTitle;
@property (nonatomic, readonly, retain) NSMutableArray *children;
@property (nonatomic, readonly, retain) NSMutableDictionary *downloadsMetadata;
@property (nonatomic) BOOL editing;
@property (nonatomic) BOOL multiSelection;
@property (nonatomic, readonly) BOOL noDocumentsSaved;
@property (nonatomic, readonly) BOOL downloadManagerActive;
@property (nonatomic, retain) UITableView *currentTableView;

@property (nonatomic, readonly, retain) NSMutableArray *sectionKeys;
@property (nonatomic, readonly, retain) NSMutableDictionary *sectionContents;

@property (nonatomic, retain) NSArray *favorites;
@property (nonatomic) BOOL showLiveList;

- (id)initWithURL:(NSURL *)url;

- (void)refreshData;
- (id)cellDataObjectForIndexPath:(NSIndexPath *)indexPath;
- (id)downloadMetadataForIndexPath:(NSIndexPath *)indexPath;

/*
 Returns a list of URLs of the documents selected by the user
 */
- (NSArray *)selectedDocumentsURLs;
@end

extern NSString * const kFavoritesDownloadManagerSection;
extern NSString * const kFavoritesDownloadedFilesSection;
