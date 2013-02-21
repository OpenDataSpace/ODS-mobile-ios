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
//  DownloadsViewController.m
//

#import "DownloadsViewController.h"
#import "FileUtils.h"
#import "DocumentViewController.h"
#import "Theme.h"
#import "FolderTableViewDataSource.h"
#import "IpadSupport.h"
#import "RepositoryServices.h"
#import "ActiveDownloadsViewController.h"
#import "FailedDownloadsViewController.h"
#import "DownloadSummaryTableViewCell.h"
#import "DownloadFailureSummaryTableViewCell.h"
#import "AccountManager.h"
#import "SessionKeychainManager.h"

@interface DownloadsViewController (Private)

- (NSString *)applicationDocumentsDirectory;
- (void)selectCurrentRow;
@end


@implementation DownloadsViewController
@synthesize dirWatcher = _dirWatcher;
@synthesize selectedFile = _selectedFile;
@synthesize folderDatasource = _folderDatasource;
@synthesize documentFilter = _documentFilter;

#pragma mark Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_selectedFile release];
	[_dirWatcher release];
    [_folderDatasource release];
    [_documentFilter release];
	
    [super dealloc];
}

#pragma mark - View Life Cycle

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    [self.tableView reloadData];
    [self selectCurrentRow];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.title)
    {
        [self setTitle:NSLocalizedString(@"downloads.view.title", @"Favorites View Title")];
    }
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	NSURL *applicationDocumentsDirectoryURL = [NSURL fileURLWithPath:[self applicationDocumentsDirectory] isDirectory:YES];
	FolderTableViewDataSource *dataSource = [[FolderTableViewDataSource alloc] initWithURL:applicationDocumentsDirectoryURL andDocumentFilter:self.documentFilter];
    [self setFolderDatasource:dataSource];
	[[self tableView] setDataSource:dataSource];
	[[self tableView] reloadData];
    [dataSource release];
	
	// start monitoring the document directory…
	[self setDirWatcher:[DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory]
													 delegate:self]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationDownloadQueueChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFilesExpired:) name:kNotificationExpiredFiles object:nil];
    
	[Theme setThemeForUITableViewController:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FolderTableViewDataSource *dataSource = (FolderTableViewDataSource *)[tableView dataSource];
    NSString *key = [[dataSource sectionKeys] objectAtIndex:indexPath.section];
    
    if ([key isEqualToString:kDownloadManagerSection])
    {
        NSString *cellType = [dataSource cellDataObjectForIndexPath:indexPath];
        if ([cellType hasPrefix:kDownloadSummaryCellIdentifier])
        {
            ActiveDownloadsViewController *viewController = [[ActiveDownloadsViewController alloc] init];
            [viewController setTitle:NSLocalizedString(@"download.summary.title", @"In Progress")];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
        }
        else if ([cellType isEqualToString:kDownloadFailureSummaryCellIdentifier])
        {
            FailedDownloadsViewController *viewController = [[FailedDownloadsViewController alloc] init];
            [viewController setTitle:NSLocalizedString(@"download.failuresView.title", @"Download Failures")];
            [self.navigationController pushViewController:viewController animated:YES];
            [viewController release];
        }
    }
    else
    {
        [self showDocument];
    }
}

- (void) showDocument
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    FolderTableViewDataSource *dataSource = (FolderTableViewDataSource *)[self.tableView dataSource];
    
    NSURL *fileURL = [dataSource cellDataObjectForIndexPath:indexPath];
    DownloadMetadata *downloadMetadata = [dataSource downloadMetadataForIndexPath:indexPath];
    NSString *fileName = [[fileURL path] lastPathComponent];
    
    if ([[AlfrescoMDMLite sharedInstance] isDownloadExpired:fileName withAccountUUID:[downloadMetadata accountUUID]])
    {
        [[RepositoryServices shared] removeRepositoriesForAccountUuid:[downloadMetadata accountUUID]];
        [[AlfrescoMDMLite sharedInstance] setServiceDelegate:self];
        [[AlfrescoMDMLite sharedInstance] loadRepositoryInfoForAccount:[downloadMetadata accountUUID]];
    }
    else
    {
        DocumentViewController *viewController = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
        
        if (downloadMetadata && downloadMetadata.key)
        {
            [viewController setFileName:downloadMetadata.key];
        }
        else
        {
            [viewController setFileName:fileName];
        }
        
        viewController.fileMetadata = downloadMetadata;
        [viewController setCmisObjectId:[downloadMetadata objectId]];
        [viewController setFilePath:[FileUtils pathToSavedFile:fileName]];
        [viewController setContentMimeType:[downloadMetadata contentStreamMimeType]];
        [viewController setHidesBottomBarWhenPushed:YES];
        [viewController setIsDownloaded:YES];
        [viewController setSelectedAccountUUID:[downloadMetadata accountUUID]];
        [viewController setShowReviewButton:YES];
        [viewController setIsRestrictedDocument:[[AlfrescoMDMLite sharedInstance] isRestrictedDownload:fileName]];

        //
        // NOTE: I do not believe it makes sense to store the selectedAccounUUID in
        // this DocumentViewController as the viewController is not tied to a AccountInfo object.
        // this should probably be retrieved from the downloadMetaData
        //
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [viewController release];
        
        self.selectedFile = fileURL;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
    
    FolderTableViewDataSource *dataSource = (FolderTableViewDataSource *)[tableView dataSource];
    NSString *key = [[dataSource sectionKeys] objectAtIndex:indexPath.section];
    
    if ([key isEqualToString:kDownloadedFilesSection] && ![(FolderTableViewDataSource *)[tableView dataSource] noDocumentsSaved])
    {
        editingStyle = UITableViewCellEditingStyleDelete;
    }
    
    return editingStyle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    FolderTableViewDataSource *dataSource = (FolderTableViewDataSource *)[tableView dataSource];
    NSString *key = [[dataSource sectionKeys] objectAtIndex:section];
    
    CGFloat height = 0.0f;
    if ([key isEqualToString:kDownloadedFilesSection])
    {
        height = 32.0f;
    }
    return height;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    FolderTableViewDataSource *dataSource = (FolderTableViewDataSource *)[tableView dataSource];
    
    UILabel *footerBackground = [[[UILabel alloc] init] autorelease];
    [footerBackground setText:[dataSource tableView:tableView titleForFooterInSection:section]];
    
    NSString *key = [[dataSource sectionKeys] objectAtIndex:section];
    
    if ([key isEqualToString:kDownloadedFilesSection])
    {
        [footerBackground setBackgroundColor:[UIColor whiteColor]];
        [footerBackground setTextAlignment:UITextAlignmentCenter];
    }
    
    return footerBackground;
}

#pragma mark - DirectoryWatcherDelegate methods

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
    FolderTableViewDataSource *folderDataSource = (FolderTableViewDataSource *)[self.tableView dataSource];
    
    /* We disable the automatic table view refresh while editing to get an animated
     effect. The automatic refresh is activated after only one time it was disabled.
     */
    if (!folderDataSource.editing)
    {
        AlfrescoLogDebug(@"Reloading favorites tableview");
        [folderDataSource refreshData];
        [self.tableView reloadData];
        [self selectCurrentRow];
    }
    else
    {
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
        folderDataSource.editing = NO;
    }
}


#pragma mark - File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)selectCurrentRow
{
    NSURL *fileURL = self.selectedFile;
    if (!fileURL)
    {
        fileURL = [IpadSupport getCurrentDetailViewControllerFileURL];
    }
    
    FolderTableViewDataSource *folderDataSource = (FolderTableViewDataSource *)[self.tableView dataSource];
    if (IS_IPAD)
    {
        NSArray *pathComponents = [fileURL pathComponents];
        if ([pathComponents containsObject:@"Documents"] && [folderDataSource.children containsObject:fileURL])
        {
            NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:[folderDataSource.children indexOfObject:fileURL] inSection:0];
            [self.tableView selectRowAtIndexPath:selectedIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
            self.selectedFile = fileURL;
        }
        else
        {
            if (self.tableView.indexPathForSelectedRow != nil)
            {
                [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
            }
            self.selectedFile = nil;
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = (folderDataSource.children.count > 0);
    if (folderDataSource.children.count == 0)
    {
        [self setEditing:NO];
    }
}

- (NSIndexPath *)indexPathForItemWithTitle:(NSString *)itemTitle
{
    NSIndexPath *indexPath = nil;
    NSMutableArray *items = self.folderDatasource.children;
    
    if (itemTitle != nil && items != nil)
    {
        // Define a block predicate to search for the item being viewed
        BOOL (^matchesRepostoryItem)(NSString *, NSUInteger, BOOL *) = ^ (NSString *cellTitle, NSUInteger idx, BOOL *stop)
        {
            BOOL matched = NO;
            NSString *fileURLString = [(NSURL *)cellTitle path];
            
            if ([[fileURLString lastPathComponent] isEqualToString:itemTitle] == YES)
            {
                matched = YES;
                *stop = YES;
            }
            return matched;
        };
        
        // See if there's an item in the list with a matching guid, using the block defined above
        NSUInteger matchingIndex = [items indexOfObjectPassingTest:matchesRepostoryItem];
        if (matchingIndex != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:matchingIndex inSection:0];
        }
    }
    
    return indexPath;
}

#pragma mark - NotificationCenter methods

- (void)detailViewControllerChanged:(NSNotification *)notification
{
    id sender = [notification object];
    
    if (sender && ![sender isEqual:self])
    {
        self.selectedFile = nil;
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

#pragma mark - DownloadManager Notification methods

- (void)downloadQueueChanged:(NSNotification *)notification
{
    NSArray *failedDownloads = [[DownloadManager sharedManager] failedDownloads];
    NSInteger activeCount = [[[DownloadManager sharedManager] activeDownloads] count];
    
    if ([failedDownloads count] > 0)
    {
        [self.navigationController.tabBarItem setBadgeValue:@"!"];
    }
    else if (activeCount > 0)
    {
        [self.navigationController.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%d", activeCount]];
    }
    else
    {
        [self.navigationController.tabBarItem setBadgeValue:nil];
    }
}

#pragma mark - CMISServiceManagerService

- (void)mdmServiceManagerRequestFinishedForAccount:(NSString*)accountUUID withSuccess:(BOOL)success
{
    if(success)
    {
        NSIndexPath * selectedRow = [self.tableView indexPathForSelectedRow];
    
        [self showDocument];
        
        [self.tableView reloadData];
        
        [self.tableView selectRowAtIndexPath:selectedRow animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        [self selectCurrentRow];
    }
}

- (void)handleFilesExpired:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSArray * expiredFiles = userInfo[@"expiredDownloadFiles"];
    NSString *currentDetailViewControllerFileURL = [[IpadSupport getCurrentDetailViewControllerFileURL] lastPathComponent];
    
    for (NSString *docTitle in expiredFiles)
    {
        NSIndexPath *index = [self indexPathForItemWithTitle:docTitle];
        [[self.tableView cellForRowAtIndexPath:index] setAlpha:0.5];
        
        if ([currentDetailViewControllerFileURL isEqualToString:docTitle])
        {
            [self.tableView deselectRowAtIndexPath:index animated:YES];
        }
    }
}

@end
