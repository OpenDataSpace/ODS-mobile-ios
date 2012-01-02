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
#import "TableViewHeaderView.h"
#import "ThemeProperties.h"
#import "MBProgressHUD.h"

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
@synthesize selectedAccountUUID;

#pragma mark Memory Management
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [metadataRequest clearDelegatesAndCancel];
    
    [selectedFile release];
	[dirWatcher release];
    [metadataRequest release];
    [HUD release];
    [selectedAccountUUID release];
	
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
    [dataSource setSelectedAccountUUID:selectedAccountUUID];
	[[self tableView] setDataSource:dataSource];
	[[self tableView] reloadData];
	
	// start monitoring the document directory…
	[self setDirWatcher:[DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory] 
													 delegate:self]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositoryShouldReload:) name:kNotificationRepositoryShouldReload object:nil];
		
	[Theme setThemeForUITableViewController:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSURL *fileURL = [(FolderTableViewDataSource *)[tableView dataSource] cellDataObjectForIndexPath:indexPath];
    DownloadMetadata *downloadMetadata = [(FolderTableViewDataSource *)[tableView dataSource] downloadMetadataForIndexPath:indexPath];
	NSString *fileName = [[fileURL path] lastPathComponent];
	
	DocumentViewController *viewController = [[DocumentViewController alloc] 
											  initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
    
    if(downloadMetadata && downloadMetadata.key) {
        [viewController setFileName:downloadMetadata.key];
    } else {
        [viewController setFileName:fileName];
    }
    
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[downloadMetadata accountUUID] 
                                                                                   tenantID:[downloadMetadata tenantID]];
    NSString *currentRepoId = [repoInfo repositoryId];
    if(downloadMetadata && [[downloadMetadata repositoryId] isEqualToString:currentRepoId]) {
        viewController.fileMetadata = downloadMetadata;
    }
    
	[viewController setCmisObjectId:[downloadMetadata objectId]];
	//[viewController setFileData:[NSData dataWithContentsOfFile:[SavedDocument pathToSavedFile:fileName]]];
    [viewController setFilePath:[SavedDocument pathToSavedFile:fileName]];
    [viewController setContentMimeType:[downloadMetadata contentStreamMimeType]];
	[viewController setHidesBottomBarWhenPushed:YES];
    [viewController setIsDownloaded:YES];
    [viewController setSelectedAccountUUID:[downloadMetadata accountUUID]];  
    //
    // NOTE: I do not believe it makes sense to store the selectedAccounUUID in 
    // this DocumentViewController as the viewController is not tied to a AccountInfo object.
    // this should probably be retrieved from the downloadMetaData
    // 
    
    [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:@"detailViewControllerChanged" object:nil];
	[viewController release];
    
    self.selectedFile = fileURL;
}

//  TODO: Decide if this should be removed as it is not being used in Alfresco Mobile
//
//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath 
//{
//    
//    DownloadMetadata *downloadMetadata = [(FolderTableViewDataSource *)[tableView dataSource] downloadMetadataForIndexPath:indexPath];
//    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:[downloadMetadata accountUUID] tenantID:[downloadMetadata tenantID]];
//    NSString *currentRepoId = [repoInfo repositoryId];
//    
//    if([downloadMetadata isMetadataAvailable]) 
//    {
//        if ([[downloadMetadata repositoryId] isEqualToString:currentRepoId]) 
//        {
//            [self startHUD];
//            
//            CMISTypeDefinitionHTTPRequest *down = [[CMISTypeDefinitionHTTPRequest alloc] initWithURL:[NSURL URLWithString:downloadMetadata.describedByUrl] accountUUID:[downloadMetadata accountUUID]];
//            [down setDelegate:self];
//            [down setDownloadMetadata:downloadMetadata];
//            [down setShow500StatusError:NO];
//            [down startAsynchronous];
//            
//            [self setMetadataRequest:down];
//            [down release];
//        } else {
//            [self presentMetadataErrorView:NSLocalizedString(@"metadata.error.cell.notsaved", @"Metadata not saved for the download")];
//        }
//    } else {
//        [self presentMetadataErrorView:NSLocalizedString(@"metadata.error.cell.notsaved", @"Metadata not saved for the download")];
//    }
//}
//


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if([(FolderTableViewDataSource *)[tableView dataSource] noDocumentsSaved]) {
        return UITableViewCellEditingStyleNone;
    }
    
    return UITableViewCellEditingStyleDelete;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UILabel *footerBackground = [[[UILabel alloc] init] autorelease];
    [footerBackground  setText:[self.tableView.dataSource tableView:self.tableView titleForFooterInSection:section]];	
    [footerBackground setBackgroundColor:[UIColor clearColor]];
    [footerBackground setTextAlignment:UITextAlignmentCenter];
    return  footerBackground;
}

#pragma mark -
#pragma mark ASIHTTPRequest methods
- (void)requestFinished:(ASIHTTPRequest *)request
{
    if ([request isKindOfClass:[CMISTypeDefinitionHTTPRequest class]]) 
    {
		CMISTypeDefinitionHTTPRequest *tdd = (CMISTypeDefinitionHTTPRequest *) request;
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[tdd repositoryItem] 
                                                                                             accountUUID:[tdd accountUUID]
                                                                                                tenantID:[tdd tenantID]];
        //
        // FIXME: accountUUID IMPROPERLY SET 
        NSLog(@"FIXME: accountUUID IMPROPERLY SET");
        //
        //
        
        [viewController setCmisObjectId:tdd.downloadMetadata.objectId];
        [viewController setMetadata:tdd.downloadMetadata.metadata];
        [viewController setPropertyInfo:tdd.properties];
        [viewController setDownloadMetadata:tdd.downloadMetadata];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        
        [viewController release];
	}
    
    [self setMetadataRequest:nil];
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    [self stopHUD];
    NSString *failureMessage;
    NSString *errorCell;
    
    if ([request responseStatusCode] >= 400)  {
        failureMessage = NSLocalizedString(@"metadata.error.notfound", @"Metadata not found in server");
        errorCell = NSLocalizedString(@"metadata.error.cell.notfound", @"Metadata not found in server");
    } else {
        failureMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"),
                          [request url]];
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

- (void) presentMetadataErrorView:(NSString *)errorMessage 
{
    MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                          cmisObject:nil accountUUID:nil tenantID:nil];
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

