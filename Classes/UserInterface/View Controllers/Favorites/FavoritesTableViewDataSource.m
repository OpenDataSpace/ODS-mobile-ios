//
//  FavoritesTableViewDataSource.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 08/08/2012.
//  Copyright (c) 2012 . All rights reserved.
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

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
	if (self)
    {
        [self setDownloadManagerActive:[[[FavoriteDownloadManager sharedManager] allDownloads] count] > 0];
		[self setFolderURL:url];
		[self setChildren:[NSMutableArray array]];
        [self setDownloadsMetadata:[NSMutableDictionary dictionary]];
		[self refreshData];	
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationFavoriteDownloadQueueChanged object:nil];
        
		// TODO: Check to make sure provided URL exists if local file system
	}
	return self;
}

#pragma mark -

#pragma mark UITableViewDataSource Cell Renderers

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
	static NSString *cellIdentifier = @"folderChildTableCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
    {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
		[[cell textLabel] setFont:[UIFont boldSystemFontOfSize:17.0f]];
		[[cell detailTextLabel] setFont:[UIFont italicSystemFontOfSize:14.0f]];
	}
	
	NSString *title = @"";
	NSString *details = @"";
	UIImage *iconImage = nil;
	
	if ([[self folderURL] isFileURL] && [self.children count] > 0) 
    {
		NSError *error;
        NSString *fileURLString = @"";
        NSString *modDateString = @"";
        DownloadMetadata *metadata = nil;
        long fileSize = 0;
        
       
        if(self.showLiveList == NO)
        {
		 fileURLString = [(NSURL *)[self.children objectAtIndex:indexPath.row] path];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURLString error:&error];
		fileSize = [[fileAttributes objectForKey:NSFileSize] longValue];
        NSDate *modificationDate = [fileAttributes objectForKey:NSFileModificationDate];
        // We use the formatDocumentFromDate() because it formats the date according the user settings
        modDateString = formatDocumentDateFromDate(modificationDate);
            
            metadata = [self.downloadsMetadata objectForKey:[fileURLString lastPathComponent]];
        }
        else {
            fileURLString = [[self.children objectAtIndex:indexPath.row] title];
            
            NSDictionary * itemMetaData = [[self.children objectAtIndex:indexPath.row] metadata];  
            
            if([itemMetaData objectForKey:@"cmis:lastModificationDate"] != nil && ![[itemMetaData objectForKey:@"cmis:lastModificationDate"] isEqualToString:@""])
            {
            NSDate *modificationDate = dateFromIso([itemMetaData objectForKey:@"cmis:lastModificationDate"]);
            
            modDateString = formatDocumentDateFromDate(modificationDate);
            }
        }
		
         
        
        /**
         * mhatfield: 06 June 2012
         * Pulling the displayed filename from the metadata could show two files with the same name. Confusing for the user?
         */
        /*
         if (metadata)
         {
         title = metadata.filename;
         }
         else
         {
         title = [fileURLString lastPathComponent];
         }
         */
        title = [fileURLString lastPathComponent];
        
    
		// !!!: Check if we got an error and handle gracefully
        // TODO: Needs to be localized
		details = [NSString stringWithFormat:@"%@ | %@", modDateString, [FavoriteFileUtils stringForLongFileSize:fileSize]];
		iconImage = imageForFilename(title);
        
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        
        RepositoryInfo *repoInfo = nil;
        NSString *currentRepoId = nil;
        BOOL showMetadata = [[AppProperties propertyForKey:kDShowMetadata] boolValue];
        
        if(self.showLiveList == NO)
        {
          repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:metadata.accountUUID tenantID:metadata.tenantID];
          currentRepoId = [repoInfo repositoryId];
        
        }
        else {
            
           // RepositoryItem * temp = [self.children objectAtIndex:indexPath.row];
           // repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[temp.metadata objectForKey:@"accountUUID"] tenantID:[temp.metadata objectForKey:@"tenantID"]];

        }
        
        if ([currentRepoId isEqualToString:[metadata repositoryId]] && showMetadata && !self.multiSelection) 
        {
            [cell setAccessoryView:[self makeDetailDisclosureButton]];
        }
        else
        {
            [cell setAccessoryView:nil];
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        [tableView setAllowsSelection:YES];
	} 
    else if (self.noDocumentsSaved)
    {
        title = NSLocalizedString(@"downloadview.footer.no-documents", @"No Favorite Documents");
        [[cell imageView] setImage:nil];
        details = nil;
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [tableView setAllowsSelection:NO];
    } 
    else
    {
		// FIXME: implement when going over the network
	}
	
	[[cell textLabel] setText:title];
	[[cell detailTextLabel] setText:details];
    
    if (iconImage)
    {
        [[cell imageView] setImage:iconImage];
    }
	
	return cell;
}

#pragma mark UITableViewDataSource

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
            footerText = NSLocalizedString(@"downloadview.footer.no-documents", @"No Downloaded Documents");	
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
    
    if (self.showLiveList == NO) {
        
        /**
         * In-progress or failed downloads (only for non-multiselect mode)?   (!self.multiSelection && )
         
        FavoriteDownloadManager *manager = [FavoriteDownloadManager sharedManager];
        if (!self.multiSelection && [manager.allDownloads count] > 0)
        {
            //NSLog(@"============ %@",[[[manager allDownloads] objectAtIndex:0] downloadInfo]);
            NSMutableArray *dmContent = [[NSMutableArray alloc] initWithCapacity:2];
            if ([manager.activeDownloads count] > 0)
            {
                [dmContent addObject:kDownloadSummaryCellIdentifier];
            }
            if ([manager.failedDownloads count] > 0)
            {
                [dmContent addObject:kDownloadFailureSummaryCellIdentifier];
            }
            
            // Safety check
            if ([dmContent count] > 0)
            {
                [contents setObject:dmContent forKey:kFavoritesDownloadManagerSection];
                [keys addObject:kFavoritesDownloadManagerSection];
            }
            [dmContent release];
        }
        */
        /**
         * Downloaded files
         */
        if ([[self folderURL] isFileURL])
        {
            [self setFolderTitle:[[self.folderURL path] lastPathComponent]];
            totalFilesSize = 0;
            
            // !!!: Need to program defensively and check for an error ...
            NSEnumerator *folderContents = [[NSFileManager defaultManager] enumeratorAtURL:[self folderURL]
                                                                includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                                                   options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                              errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                                                  NSLog(@"Error retrieving the download folder contents in URL: %@ and error: %@", url, error);
                                                                                  return YES;
                                                                              }];
            
            for (NSURL *fileURL in folderContents)
            {
                NSError *error;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:&error];
                totalFilesSize += [[fileAttributes objectForKey:NSFileSize] longValue];
                
                BOOL isDirectory;
                [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
                
                // only add files, no directories nor the Inbox
                if (!isDirectory && ![[fileURL path] isEqualToString: @"Inbox"])
                {
                    [self.children addObject:fileURL];
                    
                    NSDictionary *downloadInfo = [[FavoriteFileDownloadManager sharedInstance] downloadInfoForFilename:[fileURL lastPathComponent]];
                    
                    if (downloadInfo)
                    {
                        DownloadMetadata *metadata = [[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo];
                        [self.downloadsMetadata setObject:metadata forKey:[fileURL lastPathComponent]];
                        [metadata release];
                    }
                }
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
        
        for (RepositoryItem *item in self.favorites)
        {
            
            [self.children addObject:item];
            
            //[self.downloadsMetadata setObject:item.metadata forKey:item.title];
        
        }
        
        [contents setObject:self.children forKey:kFavoritesDownloadedFilesSection];
        [keys addObject:kFavoritesDownloadedFilesSection];

    }
  
    
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
    if(self.showLiveList == NO)
    {
    NSURL *fileURL = (NSURL *)[self.children objectAtIndex:indexPath.row];
	return [[self downloadsMetadata] objectForKey:[fileURL lastPathComponent]];
    }
    else {
        RepositoryItem * repItem = [self.children objectAtIndex:indexPath.row];
        return repItem;
    }
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

