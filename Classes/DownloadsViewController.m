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
//  DownloadsViewController.m
//

#import "DownloadsViewController.h"
#import "SavedDocument.h"
#import "DocumentViewController.h"
#import "Utility.h"
#import "UIColor+Theme.h"
#import "Theme.h"
#import "DirectoryWatcher.h"
#import "FolderTableViewDataSource.h"
#import "IpadSupport.h"
#import "MetaDataTableViewController.h"
#import "MBProgressHUD.h"
#import "RepositoryServices.h"
#import "Constants.h"
#import "TableViewHeaderView.h"
#import "ThemeProperties.h"

@interface DownloadsViewController (Private)

- (NSString *)applicationDocumentsDirectory;
- (void)selectCurrentRow;
- (void) startHUD;
- (void) stopHUD;
- (void) presentMetadataErrorView: (NSString *) errorMessage;
@end


@implementation DownloadsViewController
@synthesize dirWatcher;
@synthesize selectedFile;
@synthesize metadataRequest;
@synthesize HUD;

#pragma mark Memory Management
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [selectedFile release];
	[dirWatcher release];
    [metadataRequest release];
    [HUD release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[self setDirWatcher:nil];
    self.tableView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationRepositoryShouldReload object:nil];
}

#pragma mark View Life Cycle

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    [self selectCurrentRow];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setTitle:NSLocalizedString(@"Favorites", @"Favorites View Title")];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	NSURL *applicationDocumentsDirectoryURL = [NSURL fileURLWithPath:[self applicationDocumentsDirectory] isDirectory:YES];
	FolderTableViewDataSource *dataSource = [[FolderTableViewDataSource alloc] initWithURL:applicationDocumentsDirectoryURL];
	[[self tableView] setDataSource:dataSource];
	[[self tableView] reloadData];
	
	// start monitoring the document directory…
	[self setDirWatcher:[DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory] 
													 delegate:self]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositoryShouldReload:) name:kNotificationRepositoryShouldReload object:nil];
		
	[Theme setThemeForUITableViewController:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark -
#pragma mark UITableViewDelegate methods

static NSString *kDocumentViewController = @"DocumentViewController";

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSURL *fileURL = [(FolderTableViewDataSource *)[tableView dataSource] cellDataObjectForIndexPath:indexPath];
    DownloadMetadata *downloadMetadata = [(FolderTableViewDataSource *)[tableView dataSource] downloadMetadataForIndexPath:indexPath];
	NSString *fileName = [[fileURL path] lastPathComponent];
	
	DocumentViewController *viewController = [[DocumentViewController alloc] 
											  initWithNibName:kDocumentViewController bundle:[NSBundle mainBundle]];
    
    if(downloadMetadata && downloadMetadata.key) {
        [viewController setFileName:downloadMetadata.key];
    } else {
        [viewController setFileName:fileName];
    }
    
    NSString *currentRepoId = [[[RepositoryServices shared] currentRepositoryInfo] repositoryId];
    if(downloadMetadata && [[downloadMetadata repositoryId] isEqualToString:currentRepoId]) {
        viewController.fileMetadata = downloadMetadata;
    }
    
	[viewController setCmisObjectId:[downloadMetadata objectId]];
	[viewController setFileData:[NSData dataWithContentsOfFile:[SavedDocument pathToSavedFile:fileName]]];
	[viewController setHidesBottomBarWhenPushed:YES];
    [viewController setIsDownloaded:YES];
    [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:@"detailViewControllerChanged" object:nil];
	[viewController release];
    
    self.selectedFile = fileURL;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    DownloadMetadata *downloadMetadata = [(FolderTableViewDataSource *)[tableView dataSource] downloadMetadataForIndexPath:indexPath];
    NSString *currentRepoId = [[[RepositoryServices shared] currentRepositoryInfo] repositoryId];
    
    if([downloadMetadata isMetadataAvailable]) {
        if ([[downloadMetadata repositoryId] isEqualToString:currentRepoId]) {
            [self startHUD];
            
            CMISTypeDefinitionDownload *down = [[CMISTypeDefinitionDownload alloc] initWithURL:[NSURL URLWithString:downloadMetadata.describedByUrl] delegate:self];
            down.downloadMetadata = downloadMetadata;
            down.showHUD = NO;
            down.show500StatusError = NO;
            [down start];
            self.metadataRequest = down;
            [down release];
        } else {
            [self presentMetadataErrorView:NSLocalizedString(@"metadata.error.cell.notsaved", @"Metadata not saved for the download")];
        }
    } else {
        [self presentMetadataErrorView:NSLocalizedString(@"metadata.error.cell.notsaved", @"Metadata not saved for the download")];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([(FolderTableViewDataSource *)[tableView dataSource] noDocumentsSaved]) {
        return UITableViewCellEditingStyleNone;
    }
    
    return UITableViewCellEditingStyleDelete;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSString *sectionTitle = [tableView.dataSource tableView:tableView titleForFooterInSection:section];
	if ((nil == sectionTitle))
		return nil;
    
    //The height gets adjusted if it is less than the needed height
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
    [headerView setBackgroundColor:[ThemeProperties browseFooterColor]];
    [headerView.textLabel setTextColor:[ThemeProperties browseFooterTextColor]];
    
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	NSString *sectionTitle = [tableView.dataSource tableView:tableView titleForFooterInSection:section];
	if ((nil == sectionTitle))
		return 0.0f;
	
	TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
	return headerView.frame.size.height;
}

#pragma mark -
#pragma mark AsynchronousDelegate methods
- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async {
	
	if ([async isKindOfClass:[CMISTypeDefinitionDownload class]]) {
		CMISTypeDefinitionDownload *tdd = (CMISTypeDefinitionDownload *) async;
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[tdd repositoryItem]];
        [viewController setCmisObjectId:tdd.downloadMetadata.objectId];
        [viewController setMetadata:tdd.downloadMetadata.metadata];
        [viewController setPropertyInfo:tdd.properties];
        [viewController setDownloadMetadata:tdd.downloadMetadata];
        [viewController setCmisObject:tdd.downloadMetadata.repositoryItem];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        
        [viewController release];
	}
    
    self.metadataRequest = nil;
    [self stopHUD];
}

- (void) asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error {
    [self stopHUD];
    NSString *failureMessage;
    NSString *errorCell;
    
    if (error.code >= 400)  {
        failureMessage = NSLocalizedString(@"metadata.error.notfound", @"Metadata not found in server");
        errorCell = NSLocalizedString(@"metadata.error.cell.notfound", @"Metadata not found in server");
    } else {
        failureMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"),
                          [async.httpRequest url]];
        errorCell = NSLocalizedString(@"metadata.error.cell.requestfailed", @"Failed to connect to the repository");
    }
	
    UIAlertView *sdFailureAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"metadata.error.alert.title", @"Error")
															  message:failureMessage
															 delegate:nil 
													cancelButtonTitle:NSLocalizedString(@"Continue", nil)
													otherButtonTitles:nil] autorelease];
	[sdFailureAlert show];
    
    [self presentMetadataErrorView:errorCell];
    self.metadataRequest = nil;
}

- (void) presentMetadataErrorView:(NSString *)errorMessage {
    MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                          cmisObject:nil];
    viewController.errorMessage = errorMessage;
    [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
    [viewController release];
}

#pragma mark -
#pragma mark DirectoryWatcherDelegate methods

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
    FolderTableViewDataSource *folderDataSource = (FolderTableViewDataSource *)[self.tableView dataSource];
    
    /* We disable the automatic table view refresh while editing to get an animated
       effect. The automatic refresh is activated after only one time it was disabled.
     */
    if(!folderDataSource.editing) {
        NSLog(@"Reloading favorites tableview");
        [folderDataSource refreshData];
        [self.tableView reloadData];
        [self selectCurrentRow];
    } else {
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
        [self performSelector:@selector(selectCurrentRow) withObject:nil afterDelay:0.5];
        folderDataSource.editing = NO;
    }
}


#pragma mark -
#pragma mark File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}
           
- (void) selectCurrentRow {
    FolderTableViewDataSource *folderDataSource = (FolderTableViewDataSource *)[self.tableView dataSource];
    
    if(IS_IPAD && [folderDataSource.children containsObject:self.selectedFile]) {
        NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:[folderDataSource.children indexOfObject:self.selectedFile] inSection:0];
        
        [self.tableView selectRowAtIndexPath:selectedIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}
    
    [self setHUD:[MBProgressHUD showHUDAddedTo:self.tableView animated:YES]];
    [self.HUD setRemoveFromSuperViewOnHide:YES];
    [self.HUD setTaskInProgress:YES];
    [self.HUD setMode:MBProgressHUDModeIndeterminate];
}

- (void)stopHUD
{
	if (HUD) {
		[HUD setTaskInProgress:NO];
		[HUD hide:YES];
		[HUD removeFromSuperview];
		[self setHUD:nil];
	}
}

#pragma mark - NotificationCenter methods

- (void) detailViewControllerChanged:(NSNotification *) notification {
    id sender = [notification object];
    
    if(sender && ![sender isEqual:self]) {
        self.selectedFile = nil;
        
        [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void) applicationWillResignActive:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in DownloadsViewController");
    
    [metadataRequest cancel];
}

-(void)repositoryShouldReload:(NSNotification *)notification {
    [[self tableView] reloadData];
}

@end

