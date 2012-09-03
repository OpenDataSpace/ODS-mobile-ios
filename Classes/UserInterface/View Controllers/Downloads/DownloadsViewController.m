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
#import "Utility.h"
#import "UIColor+Theme.h"
#import "Theme.h"
#import "DirectoryWatcher.h"
#import "FolderTableViewDataSource.h"
#import "IpadSupport.h"
#import "MetaDataTableViewController.h"
#import "RepositoryServices.h"
#import "TableViewHeaderView.h"
#import "ThemeProperties.h"
#import "ActiveDownloadsViewController.h"
#import "FailedDownloadsViewController.h"
#import "DownloadSummaryTableViewCell.h"
#import "DownloadFailureSummaryTableViewCell.h"
#import "DownloadManager.h"

@interface DownloadsViewController (Private)

- (NSString *)applicationDocumentsDirectory;
- (void)selectCurrentRow;
@end


@implementation DownloadsViewController
@synthesize dirWatcher = _dirWatcher;
@synthesize selectedFile = _selectedFile;
@synthesize folderDatasource = _folderDatasource;

#pragma mark Memory Management
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_selectedFile release];
	[_dirWatcher release];
    [_folderDatasource release];
	
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	[self setDirWatcher:nil];
    self.tableView = nil;
}

#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self.tableView reloadData];
    [self selectCurrentRow];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setTitle:NSLocalizedString(@"Favorites", @"Favorites View Title")];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	NSURL *applicationDocumentsDirectoryURL = [NSURL fileURLWithPath:[self applicationDocumentsDirectory] isDirectory:YES];
	FolderTableViewDataSource *dataSource = [[FolderTableViewDataSource alloc] initWithURL:applicationDocumentsDirectoryURL];
    [self setFolderDatasource:dataSource];
	[[self tableView] setDataSource:dataSource];
	[[self tableView] reloadData];
    [dataSource release];
	
	// start monitoring the document directory…
	[self setDirWatcher:[DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory] 
													 delegate:self]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationDownloadQueueChanged object:nil];

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
        NSURL *fileURL = [dataSource cellDataObjectForIndexPath:indexPath];
        DownloadMetadata *downloadMetadata = [dataSource downloadMetadataForIndexPath:indexPath];
        NSString *fileName = [[fileURL path] lastPathComponent];
        
        DocumentViewController *viewController = [[DocumentViewController alloc] 
                                                  initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
        
        if (downloadMetadata && downloadMetadata.key)
        {
            [viewController setFileName:downloadMetadata.key];
        }
        else
        {
            [viewController setFileName:fileName];
        }
        
        RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[downloadMetadata accountUUID] 
                                                                                       tenantID:[downloadMetadata tenantID]];
        NSString *currentRepoId = [repoInfo repositoryId];
        if (downloadMetadata && [[downloadMetadata repositoryId] isEqualToString:currentRepoId])
        {
            viewController.fileMetadata = downloadMetadata;
        }
        
        [viewController setCmisObjectId:[downloadMetadata objectId]];
        [viewController setFilePath:[FileUtils pathToSavedFile:fileName]];
        [viewController setContentMimeType:[downloadMetadata contentStreamMimeType]];
        [viewController setHidesBottomBarWhenPushed:YES];
        [viewController setIsDownloaded:YES];
        [viewController setSelectedAccountUUID:[downloadMetadata accountUUID]];
        [viewController setShowReviewButton:YES];
        //
        // NOTE: I do not believe it makes sense to store the selectedAccounUUID in 
        // this DocumentViewController as the viewController is not tied to a AccountInfo object.
        // this should probably be retrieved from the downloadMetaData
        // 
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
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
    UILabel *footerBackground = [[[UILabel alloc] init] autorelease];
    [footerBackground setText:[self.tableView.dataSource tableView:self.tableView titleForFooterInSection:section]];	

    FolderTableViewDataSource *dataSource = (FolderTableViewDataSource *)[tableView dataSource];
    NSString *key = [[dataSource sectionKeys] objectAtIndex:section];

    if ([key isEqualToString:kDownloadedFilesSection])
    {
        [footerBackground setBackgroundColor:[UIColor whiteColor]];
        [footerBackground setTextAlignment:UITextAlignmentCenter];
    }

    return footerBackground;
}

#pragma mark -
#pragma mark DirectoryWatcherDelegate methods

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
    FolderTableViewDataSource *folderDataSource = (FolderTableViewDataSource *)[self.tableView dataSource];
    
    /* We disable the automatic table view refresh while editing to get an animated
       effect. The automatic refresh is activated after only one time it was disabled.
     */
    if (!folderDataSource.editing)
    {
        NSLog(@"Reloading favorites tableview");
        [folderDataSource refreshData];
        [self.tableView reloadData];
        [self selectCurrentRow];
    }
    else
    {
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
        [self performSelector:@selector(selectCurrentRow) withObject:nil afterDelay:0.5];
        folderDataSource.editing = NO;
    }
}


#pragma mark - File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}
           
- (void) selectCurrentRow
{
    FolderTableViewDataSource *folderDataSource = (FolderTableViewDataSource *)[self.tableView dataSource];
    
    if (IS_IPAD && [folderDataSource.children containsObject:self.selectedFile])
    {
        NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:[folderDataSource.children indexOfObject:self.selectedFile] inSection:0];
        
        [self.tableView selectRowAtIndexPath:selectedIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark - NotificationCenter methods

- (void)detailViewControllerChanged:(NSNotification *) notification
{
    id sender = [notification object];
    
    if (sender && ![sender isEqual:self])
    {
        self.selectedFile = nil;
        
        [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
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

@end
