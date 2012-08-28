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
//  FavoritesTableViewDataSource.m
//

#import "FavoritesTableViewDataSource.h"
#import "Utility.h"
#import "FavoriteFileUtils.h"
#import "FavoriteFileDownloadManager.h"
#import "DownloadMetadata.h"
#import "RepositoryServices.h"
#import "AppProperties.h"
#import "DownloadsViewController.h"
#import "IpadSupport.h"
#import "DownloadSummaryTableViewCell.h"
#import "DownloadFailureSummaryTableViewCell.h"

#import "FavoriteTableCellWrapper.h"

NSString * const kFavoritesDownloadManagerSection = @"FavoritesDownloadManager";
NSString * const kFavoritesDownloadedFilesSection = @"FavoritesDownloadedFiles";

@interface FavoritesTableViewDataSource ()
@property (nonatomic, readwrite, retain) NSURL *folderURL;
@property (nonatomic, readwrite, retain) NSString *folderTitle;
@property (nonatomic, readwrite, retain) NSMutableArray *children;
@property (nonatomic, readwrite, retain) NSMutableDictionary *downloadsMetadata;
@property (nonatomic, readwrite) BOOL noDocumentsSaved;
@property (nonatomic, readwrite) BOOL downloadManagerActive;
@property (nonatomic, readwrite, retain) NSMutableArray *sectionKeys;
@property (nonatomic, readwrite, retain) NSMutableDictionary *sectionContents;


- (UIButton *)makeDetailDisclosureButton;
- (UITableViewCell *)tableView:(UITableView *)tableView downloadProgressCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView downloadFailuresCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView downloadedFileCellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@implementation FavoritesTableViewDataSource
@synthesize folderURL = _folderURL;
@synthesize folderTitle = _folderTitle;
@synthesize children = _children;
@synthesize downloadsMetadata = _downloadsMetadata;
@synthesize editing = _editing;
@synthesize multiSelection = _multiSelection;
@synthesize noDocumentsSaved = _noDocumentsSaved;
@synthesize downloadManagerActive = _downloadManagerActive;
@synthesize currentTableView = _currentTableView;
@synthesize sectionKeys = _sectionKeys;
@synthesize sectionContents = _sectionContents;
@synthesize favorites = _favorites;
@synthesize showLiveList = _showLiveList;

#pragma mark Memory Management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[_folderURL release];
	[_folderTitle release];
	[_children release];
    [_downloadsMetadata release];
    [_currentTableView release];
    [_sectionKeys release];
    [_sectionContents release];
    
	[super dealloc];
}

#pragma mark Initialization

- (id)init
{
    self = [super init];
	if (self)
    {
        [self setDownloadManagerActive:[[[FavoriteDownloadManager sharedManager] allDownloads] count] > 0];
		[self setChildren:[NSMutableArray array]];
        [self setDownloadsMetadata:[NSMutableDictionary dictionary]];
		[self refreshData];	
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationFavoriteDownloadQueueChanged object:nil];
        
		// TODO: Check to make sure provided URL exists if local file system
	}
	return self;
}

#pragma mark - UITableViewDataSource Cell Renderers

- (UITableViewCell *)tableView:(UITableView *)tableView downloadProgressCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	DownloadSummaryTableViewCell *cell = (DownloadSummaryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kDownloadSummaryCellIdentifier];
    if (cell == nil)
    {
        cell = [[[DownloadSummaryTableViewCell alloc] initWithIdentifier:kDownloadSummaryCellIdentifier] autorelease];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView downloadFailuresCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	DownloadFailureSummaryTableViewCell *cell = (DownloadFailureSummaryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kDownloadFailureSummaryCellIdentifier];
    if (cell == nil)
    {
        cell = [[[DownloadFailureSummaryTableViewCell alloc] initWithIdentifier:kDownloadFailureSummaryCellIdentifier] autorelease];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView downloadedFileCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    FavoriteTableCellWrapper *cellWrapper = nil;
    cellWrapper = [self.children objectAtIndex:indexPath.row];
    
    return [cellWrapper createCellInTableView:tableView];
}

#pragma mark - UITableViewDataSource


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentTableView = tableView;
    SEL rendererSelector = nil;
    
    NSString *key = [self.sectionKeys objectAtIndex:indexPath.section];
    NSArray *contents = [self.sectionContents objectForKey:key];
    id cellContents = [contents objectAtIndex:indexPath.row];
    
    if ([key isEqualToString:kFavoritesDownloadManagerSection])
    {
        if ([cellContents isEqualToString:kDownloadSummaryCellIdentifier])
        {
            rendererSelector = @selector(tableView:downloadProgressCellForRowAtIndexPath:);
        }
        else if ([cellContents isEqualToString:kDownloadFailureSummaryCellIdentifier])
        {
            rendererSelector = @selector(tableView:downloadFailuresCellForRowAtIndexPath:);
        }
    }
    else
    {
        rendererSelector = @selector(tableView:downloadedFileCellForRowAtIndexPath:);
    }
    
    return [self performSelector:rendererSelector withObject:tableView withObject:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [[self sectionKeys] objectAtIndex:section];
    NSArray *contents = [[self sectionContents] objectForKey:key];
    NSInteger numberOfRows = [contents count];
    
    return numberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self.sectionKeys count];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Deleted the cell: %d", indexPath.row);
    NSURL *fileURL = [[self.children objectAtIndex:indexPath.row] retain];
    NSString *filename = [fileURL lastPathComponent];
	BOOL fileExistsInFavorites = [[FavoriteFileDownloadManager sharedInstance] downloadExistsForKey:filename];
    [self setEditing:YES];
    
	if (fileExistsInFavorites)
    {
        [[FavoriteFileDownloadManager sharedInstance] removeDownloadInfoForFilename:filename];
		NSLog(@"Removed File '%@'", filename);
    }
    
    [self refreshData];
    [self setNoDocumentsSaved:NO];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    DownloadsViewController *delegate = (DownloadsViewController *)[tableView delegate];
    if ([fileURL isEqual:delegate.selectedFile])
    {
        [IpadSupport clearDetailController];
    }
    
    if ([self.children count] == 0)
    {
        [self setNoDocumentsSaved:YES];
        [tableView reloadData];
    }
    
    [fileURL release];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerText = @"";
    NSString *key = [[self sectionKeys] objectAtIndex:section];
    
    if ([key isEqualToString:kFavoritesDownloadedFilesSection])
    {
        if ([self.children count] > 0)
        {
            NSString *documentsText;
            switch ([self.children count])
            {
                case 1:
                    documentsText = NSLocalizedString(@"downloadview.footer.one-document", @"1 Document");
                    break;
                default:
                    documentsText = [NSString stringWithFormat:NSLocalizedString(@"downloadview.footer.multiple-documents", @"%d Documents"), 
                                     [self.children count]];
                    break;
            }
            footerText = [NSString stringWithFormat:@"%@ %@", documentsText, [FavoriteFileUtils stringForLongFileSize:totalFilesSize]];	
        }
        else
        {
            footerText = NSLocalizedString(@"No Favorite Documents", @"No Favorite Documents");	
        }
    }
    
    return footerText;
}

#pragma mark - Instance Methods

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSLog(@"accessory view tapped");
    NSIndexPath *indexPath = [self.currentTableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.currentTableView]];
    if (indexPath != nil)
    {
        [self.currentTableView.delegate tableView:self.currentTableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
}


- (void)refreshData 
{
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableDictionary *contents = [[NSMutableDictionary alloc] init];
    
	[[self children] removeAllObjects];
    [[self downloadsMetadata] removeAllObjects];
    totalFilesSize = 0;
    
    /*
    if (self.showLiveList == NO) 
    {
        
    
        if ([[self folderURL] isFileURL])
        {
            [self setFolderTitle:[[self.folderURL path] lastPathComponent]];
            
            
            // !!!: Need to program defensively and check for an error ...
            NSEnumerator *folderContents = [[NSFileManager defaultManager] enumeratorAtURL:[self folderURL]
                                                                includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                                                   options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                              errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                                                  NSLog(@"Error retrieving the favorite folder contents in URL: %@ and error: %@", url, error);
                                                                                  return YES;
                                                                              }];
            
            for (NSURL *fileURL in folderContents)
            {
                NSError *error;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:&error];
                totalFilesSize += [[fileAttributes objectForKey:NSFileSize] longValue];
                
                BOOL isDirectory;
                [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
                
                
                RepositoryItem * item = [[RepositoryItem alloc] initWithDictionary:[[FavoriteFileDownloadManager sharedInstance] downloadInfoForFilename:[fileURL lastPathComponent]]];
                
                FavoriteTableCellWrapper * cellWrapper = [[FavoriteTableCellWrapper alloc]  initWithRepositoryItem:item];
                [cellWrapper setSyncStatus:SyncOffline];
                
                cellWrapper.fileSize = [FavoriteFileUtils sizeOfSavedFile:item.title];
                [self.children addObject:cellWrapper];
                
                [cellWrapper release];
                [item release];
            }
            
            [contents setObject:self.children forKey:kFavoritesDownloadedFilesSection];
            [keys addObject:kFavoritesDownloadedFilesSection];
        }
        else
        {
            //	FIXME: implement me
        }
        
        [self setNoDocumentsSaved:[self.children count] == 0];
        
        if (self.multiSelection)
        {
            [self.currentTableView setAllowsMultipleSelectionDuringEditing:!self.noDocumentsSaved];
            [self.currentTableView setEditing:!self.noDocumentsSaved];
        }
        
    }
    else {
        */
        for (FavoriteTableCellWrapper *item in self.favorites)
        {
            NSString *contentStreamLengthStr = [item.repositoryItem contentStreamLengthString];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:[FavoriteFileUtils pathToSavedFile:item.repositoryItem.title]])
            {
                NSError *error;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[FavoriteFileUtils pathToSavedFile:item.repositoryItem.title] error:&error];
                totalFilesSize += [[fileAttributes objectForKey:NSFileSize] longValue];
                
                item.fileSize = [FavoriteFileUtils sizeOfSavedFile:item.repositoryItem.title];
            }
            else {
                item.fileSize = [FavoriteFileUtils stringForLongFileSize:[contentStreamLengthStr longLongValue]];
                totalFilesSize += [contentStreamLengthStr longLongValue];
            }
            
            
            [self.children addObject:item];
            
        }
        
        
        [contents setObject:self.children forKey:kFavoritesDownloadedFilesSection];
        [keys addObject:kFavoritesDownloadedFilesSection];
        
   // }
    
    
    [self setSectionKeys:keys];
    [self setSectionContents:contents];
    
    [keys release];
    [contents release];
}

- (id)cellDataObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [[self sectionKeys] objectAtIndex:indexPath.section];
    NSArray *contents = [[self sectionContents] objectForKey:key];
    
	return [contents objectAtIndex:indexPath.row];
}

- (id)downloadMetadataForIndexPath:(NSIndexPath *)indexPath
{
    NSURL *fileURL = (NSURL *)[self.children objectAtIndex:indexPath.row];
	return [[self downloadsMetadata] objectForKey:[fileURL lastPathComponent]];
}

- (NSArray *)selectedDocumentsURLs
{
    NSArray *selectedIndexes = [self.currentTableView indexPathsForSelectedRows];
    NSMutableArray *selectedURLs = [NSMutableArray arrayWithCapacity:[selectedIndexes count]];
    for (NSIndexPath *indexPath in selectedIndexes)
    {
        [selectedURLs addObject:[self.children objectAtIndex:indexPath.row]];
    }
    
    return [NSArray arrayWithArray:selectedURLs];
}

#pragma mark - Download notifications

- (void)downloadQueueChanged:(NSNotification *)notification
{
    NSInteger activeCount = [[[FavoriteDownloadManager sharedManager] activeDownloads] count];
    
    if(activeCount == 0)
    {
        [self refreshData];
        [self.currentTableView reloadData];
    }
}

@end

