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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  FolderTableViewDataSource.m
//

#import "FolderTableViewDataSource.h"
#import "Utility.h"
#import "SavedDocument.h"
#import "FileDownloadManager.h"
#import "DownloadMetadata.h"
#import "RepositoryServices.h"
#import "AppProperties.h"

@interface FolderTableViewDataSource ()
@property (nonatomic, readwrite, retain) NSURL *folderURL;
@property (nonatomic, readwrite, retain) NSString *folderTitle;
@property (nonatomic, readwrite, retain) NSMutableArray *children;
@property (nonatomic, readwrite, retain) NSMutableDictionary *downloadsMetadata;

- (UIButton *)makeDetailDisclosureButton;
@end



@implementation FolderTableViewDataSource
@synthesize folderURL;
@synthesize folderTitle;
@synthesize children;
@synthesize downloadsMetadata;
@synthesize editing;
@synthesize noDocumentsSaved;
@synthesize currentTableView;
@synthesize selectedAccountUUID;

#pragma mark Memory Management
- (void)dealloc
{
	[folderURL release];
	[folderTitle release];
	[children release];
    [downloadsMetadata release];
    [currentTableView release];
    [selectedAccountUUID release];
    
	[super dealloc];
}

#pragma mark Initialization
- (id)initWithURL:(NSURL *)url
{
    self = [super init];
	if (self) {
		[self setFolderURL:url];
		[self setChildren:[NSMutableArray array]];
        [self setDownloadsMetadata:[NSMutableDictionary dictionary]];
		[self refreshData];	
		
        if([children count] == 0) {
            noDocumentsSaved = YES;
        }
        
		// TODO: Check to make sure provided URL exists if local file system
	}
	return self;
}

#pragma mark -
#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentTableView = tableView;
    
	static NSString *CellIdentifier = @"folderChildTableCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (nil == cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		[[cell textLabel] setFont:[UIFont boldSystemFontOfSize:17.0f]];
		[[cell detailTextLabel] setFont:[UIFont italicSystemFontOfSize:14.0f]];
	}
	
	NSString *title = @"";
	NSString *details = @"";
	UIImage *iconImage = nil;
	
	if ([[self folderURL] isFileURL] && [children count] > 0) 
    {
		NSError *error;
		NSString *fileURLString = [(NSURL *)[self.children objectAtIndex:indexPath.row] path];
		NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURLString error:&error];
		long fileSize = [[fileAttributes objectForKey:NSFileSize] longValue];
        NSDate *modificationDate = [fileAttributes objectForKey:NSFileModificationDate];
        // We use the formatDocumentFromDate() because it formats the date according the user settings
        NSString *modDateString = formatDocumentDateFromDate(modificationDate);
		
        DownloadMetadata *metadata = [downloadsMetadata objectForKey:[fileURLString lastPathComponent]];
        if(metadata) {
            title = metadata.filename;
        } else {
            title = [fileURLString lastPathComponent];
        }
        
		// !!!: Check if we got an error and handle gracefully
        // TODO: Needs to be localized
		details = [NSString stringWithFormat:@"%@ | %@", modDateString, [SavedDocument stringForLongFileSize:fileSize]];
		iconImage = imageForFilename(title);

        [cell setAccessoryType:UITableViewCellAccessoryNone];
        
        RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:metadata.accountUUID tenantID:metadata.tenantID];
        NSString *currentRepoId = [repoInfo repositoryId];
        BOOL showMetadata = [[AppProperties propertyForKey:kDShowMetadata] boolValue];
        
        if ([currentRepoId isEqualToString:[metadata repositoryId]] && showMetadata) {
            [cell setAccessoryView:[self makeDetailDisclosureButton]];
        } else {
            [cell setAccessoryView:nil];
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
        [tableView setAllowsSelection:YES];
        
	} 
    else if(noDocumentsSaved) {
        title = NSLocalizedString(@"downloadview.footer.no-documents", @"No Downloaded Documents");
        [[cell imageView] setImage:nil];
        details = nil;
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [tableView setAllowsSelection:NO];
    } 
    else {
		// FIXME: implement when going over the network
	}
	
	[[cell textLabel] setText:title];
	[[cell detailTextLabel] setText:details];
    
    if (iconImage)
        [[cell imageView] setImage:iconImage];
	
	return cell;
}

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSLog(@"accessory view tapped");
    NSIndexPath * indexPath = [self.currentTableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.currentTableView]];
    if ( indexPath == nil )
        return;
    [self.currentTableView.delegate tableView:self.currentTableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger noDocuments = noDocumentsSaved? 1: 0;
	return [children count] +  noDocuments; /// TODO: Dont forget me if sectioned
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1; // TODO: more sections?
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Deleted the cell: %d", [indexPath row]);
    NSString *filename = [(NSURL *)[self.children objectAtIndex:indexPath.row] lastPathComponent];
	BOOL fileExistsInFavorites = [[FileDownloadManager sharedInstance] downloadExistsForKey:filename];
    editing = YES;
    
	if (fileExistsInFavorites) {
        [[FileDownloadManager sharedInstance] removeDownloadInfoForFilename:filename];
		NSLog(@"Removed File '%@'", filename);
    }
    
    [self refreshData];
    noDocumentsSaved = NO;
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    if([children count] == 0) {
        noDocumentsSaved = YES;
        [tableView reloadData];
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *documentsText;
    NSString *footerText = @"";
    switch ([self.children count]) {
        case 1:
            documentsText = NSLocalizedString(@"downloadview.footer.one-document", @"1 Document");
            break;
        default:
            documentsText = [NSString stringWithFormat:NSLocalizedString(@"downloadview.footer.multiple-documents", @"%d Documents"), 
                             [self.children count]];
            break;
    }
    
    if([self.children count] > 0) {
        footerText = [NSString stringWithFormat:@"%@ %@", documentsText, [SavedDocument stringForLongFileSize:totalFilesSize]];	
    } else {
        footerText = NSLocalizedString(@"downloadview.footer.no-documents", @"No Downloaded Documents");	
    }
    
    return footerText;
}


#pragma mark -
#pragma mark Instance Methods
- (void)refreshData
{
	[[self children] removeAllObjects];
    [[self downloadsMetadata] removeAllObjects];
    
	if ([[self folderURL] isFileURL]) {
		
		[self setFolderTitle:[[self.folderURL path] lastPathComponent]];
        totalFilesSize = 0;
		
		// !!!: Need to program defensively and check for an error ...
		NSArray *folderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[self folderURL] path] 
																					  error:NULL];
		
		for (NSString *fileName in [folderContents objectEnumerator])
		{
			NSString *filePath = [[self.folderURL path] stringByAppendingPathComponent:fileName];
			NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            NSError *error;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
            totalFilesSize += [[fileAttributes objectForKey:NSFileSize] longValue];
			
			BOOL isDirectory;
			[[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
			
			// only add files, no directories nor the Inbox
			if (!isDirectory && ![fileName isEqualToString: @"Inbox"]) {
				[self.children addObject:fileURL];
                
                NSDictionary *downloadInfo = [[FileDownloadManager sharedInstance] downloadInfoForFilename:[fileURL lastPathComponent]];
                
                if(downloadInfo) {
                    DownloadMetadata *metadata = [[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo];
                    [downloadsMetadata setObject:metadata forKey:[fileURL lastPathComponent]];
                    [metadata release];
                }
            }
		}	
	}
	else {
		//	FIXME: implement me
	}
    
    noDocumentsSaved = NO;
}

- (id)cellDataObjectForIndexPath:(NSIndexPath *)indexPath
{
	return [[self children] objectAtIndex:[indexPath row]];
}

- (id)downloadMetadataForIndexPath:(NSIndexPath *)indexPath
{
    NSURL *fileURL = (NSURL *)[self.children objectAtIndex:indexPath.row];
	return [[self downloadsMetadata] objectForKey:[fileURL lastPathComponent]];
}

@end
