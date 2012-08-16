//
//  FavoritesTableViewDataSource.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 08/08/2012.
//  Copyright (c) 2012 . All rights reserved.
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
