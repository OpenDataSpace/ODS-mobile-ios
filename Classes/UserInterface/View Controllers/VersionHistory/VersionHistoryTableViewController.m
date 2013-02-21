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
//  VersionHistoryTableViewController.m
//

#import "VersionHistoryTableViewController.h"
#import "CMISTypeDefinitionHTTPRequest.h"
#import "Theme.h"
#import "MetaDataTableViewController.h"
#import "VersionHistoryCellController.h"
#import "VersionHistoryWrapper.h"
#import "DocumentViewController.h"
#import "TableCellViewController.h"
#import "IFButtonCellController.h"
#import "FileDownloadManager.h"
#import "LinkRelationService.h"
#import "FolderItemsHTTPRequest.h"

@interface VersionHistoryTableViewController(private)
- (void)reloadVersionHistory;
-(void)startHUD;
-(void)stopHUD;
@end

@implementation VersionHistoryTableViewController
@synthesize versionHistory = _versionHistory;
@synthesize metadataRequest = _metadataRequest;
@synthesize versionHistoryRequest = _versionHistoryRequest;
@synthesize HUD = _HUD;
@synthesize downloadProgressBar = _downloadProgressBar;
@synthesize latestVersion = _latestVersion;
@synthesize currentRepositoryItem = _currentRepositoryItem;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_metadataRequest clearDelegatesAndCancel];
    
    [_versionHistory release];
    [_metadataRequest release];
    [_versionHistoryRequest release];
    [_HUD release];
    [_downloadProgressBar release];
    [_latestVersion release];
    [_currentRepositoryItem release];
    [_selectedAccountUUID release];
    [_tenantID release];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style versionHistory:(NSArray *)initialVersionHistory accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    self = [super initWithStyle:style];
    if (self)
    {
        [self setVersionHistory:initialVersionHistory];
        [self setSelectedAccountUUID:uuid];
        [self setTenantID:aTenantID];
    }
    
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Always Rotate
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:NSLocalizedString(@"versionhistory.title", @"Version History")];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    versionHistoryActionInProgress = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUpdated:) name:kNotificationDocumentUpdated object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Generic Table View Construction

- (void)constructTableGroups
{
    // Arrays for section headers, bodies and footers
	NSMutableArray *groups =  [NSMutableArray array];
    NSMutableArray *mainGroup = [NSMutableArray array];
    [groups addObject:mainGroup];
    
    [self.tableView setAllowsSelection:YES];
    self.latestVersion = nil;
    
    
    for (RepositoryItem *repositoryItem in self.versionHistory)
    {
        VersionHistoryWrapper *wrapper = [[VersionHistoryWrapper alloc] initWithRepositoryItem:repositoryItem];
        NSString *savedLocally = @"";
        
        /**
         * mhatfield 17dec2011
         * Removed this code, as it seems to be giving false positives
         *
        //Find out if the version is saved locally
        NSDictionary *downloadDict = [[FileDownloadManager sharedInstance] downloadInfoForFilename:repositoryItem.title];
        if(downloadDict) {
            DownloadMetadata *downloadInfo = [[DownloadMetadata alloc] initWithDownloadInfo:downloadDict];
            NSString *versionLabel = [downloadInfo.metadata objectForKey:@"cmis:versionLabel"];
            if([versionLabel isEqualToString:wrapper.versionLabel]) {
                savedLocally = [NSString stringWithFormat:@"\n%@", NSLocalizedString(@"versionhistory.version.savedLocally", @"This version is saved locally")];
            }
            [downloadInfo release];
        }
         */
        
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"versionhistory.cell.title", @"Version History Cell Title"), wrapper.versionLabel];
        NSString *subtitle = [NSString stringWithFormat:NSLocalizedString(@"versionhistory.cell.subtitle", @"Version History Cell Subtitle"), formatDocumentDate(repositoryItem.lastModifiedDate), wrapper.lastAuthor, wrapper.comment, wrapper.isLatestVersion?NSLocalizedString(@"Yes", @"Yes"):NSLocalizedString(@"No", @"No"), savedLocally];
        
        VersionHistoryCellController *cellController = [[VersionHistoryCellController alloc] initWithTitle:title subtitle:subtitle];
        
        [cellController setRepositoryItem:repositoryItem];
        
        [cellController setSelectionTarget:self];
        [cellController setSelectionAction:@selector(performVersionHistoryAction:)];
        //            cellController.accesoryType = UITableViewCellAccessoryDetailDisclosureButton; 
        [cellController setAccessoryView:[UIButton buttonWithType:UIButtonTypeInfoDark]];
        cellController.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        [mainGroup addObject:cellController];
        [cellController release];
        
        //Updating the latestVersion reference
        if (self.latestVersion)
        {
            VersionHistoryWrapper *latestVersionWrapper = [[VersionHistoryWrapper alloc] initWithRepositoryItem:self.latestVersion];
            if ([wrapper.versionLabel floatValue] > [latestVersionWrapper.versionLabel floatValue])
            {
                self.latestVersion = wrapper.repositoryItem;
            }
            
            [latestVersionWrapper release];
        }
        else
        {
            self.latestVersion = wrapper.repositoryItem;
        }
        
        [wrapper release];
    }
    
    if ([self.versionHistory count] == 0)
    {
        TableCellViewController *cell;
        
        cell = [[TableCellViewController alloc]initWithAction:nil onTarget:nil];
        cell.textLabel.text = NSLocalizedString(@"versionhistory.empty", @"No Version History Available");
        
        [cell.textLabel adjustsFontSizeToFitWidth];

        [mainGroup addObject:cell];
        [cell release];
        [self.tableView setAllowsSelection:NO];
    }
    else
    {
        NSMutableArray *downloadLatestGroup = [NSMutableArray array];
        IFButtonCellController *redownloadButton = [[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"versionhistory.download.latest", @"Download Latest Version") 
                                                                                      withAction:@selector(downloadLatestVersion:)
                                                                                        onTarget:self];
        [redownloadButton setBackgroundColor:[UIColor whiteColor]];
        [downloadLatestGroup addObject:redownloadButton];
        [redownloadButton release];
        [groups addObject:downloadLatestGroup];
    }
    
    [tableGroups release];
    tableGroups = [groups retain];
	
    [self setEditing:NO animated:YES];
	[self assignFirstResponderHostToCellControllers];
}

- (void)downloadDocument
{
    NSURL *contentURL = [NSURL URLWithString:self.latestVersion.contentLocation];
    
    self.downloadProgressBar = [DownloadProgressBar createAndStartWithURL:contentURL delegate:self 
                                                                  message:NSLocalizedString(@"Downloading Document", @"Downloading Document") 
                                                                 filename:self.latestVersion.title
                                                              accountUUID:self.selectedAccountUUID 
                                                                 tenantID:self.tenantID];
    [self.downloadProgressBar setCmisObjectId:[self.latestVersion guid]];
    [self.downloadProgressBar setCmisContentStreamMimeType:[[self.latestVersion metadata] objectForKey:@"cmis:contentStreamMimeType"]];
    [self.downloadProgressBar setVersionSeriesId:[self.latestVersion versionSeriesId]];
    [self.downloadProgressBar setRepositoryItem:self.latestVersion];
    [self.downloadProgressBar setTag:1];
}

- (void)downloadLatestVersion:(id)sender
{
    if (self.latestVersion.contentLocation)
    {
        if ([[FileDownloadManager sharedInstance] downloadExistsForKey:[self.latestVersion title]])
        {
            [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.overwrite.download.prompt.title", @"")
                                         message:NSLocalizedString(@"documentview.overwrite.download.prompt.message", @"Yes/No Question")
                                        delegate:self
                               cancelButtonTitle:NSLocalizedString(@"No", @"No")
                               otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease] show];
        }
        else
        {
            [self downloadDocument];
        }
    }
    else
    {
        displayWarningMessageWithTitle(NSLocalizedString(@"noContentWarningMessage", @"This document has no content."), NSLocalizedString(@"noContentWarningTitle", @"No content"));
    }
}

- (void)reloadVersionHistory
{
    NSString *versionHistoryURI = [[LinkRelationService shared] hrefForLinkRelationString:@"version-history" onCMISObject:self.currentRepositoryItem];
    FolderItemsHTTPRequest *down = [[[FolderItemsHTTPRequest alloc] initWithURL:[NSURL URLWithString:versionHistoryURI] accountUUID:self.selectedAccountUUID] autorelease];
    [down setDelegate:self];
    [self setVersionHistoryRequest:down];
    [down startAsynchronous];
    [self startHUD];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [self downloadDocument];
    }
}

#pragma mark - ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{	
	if ([request isKindOfClass:[CMISTypeDefinitionHTTPRequest class]]) {
		CMISTypeDefinitionHTTPRequest *tdd = (CMISTypeDefinitionHTTPRequest *) request;
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[tdd repositoryItem] 
                                                                                             accountUUID:self.selectedAccountUUID 
                                                                                                tenantID:self.tenantID];
        [viewController setCmisObjectId:tdd.repositoryItem.guid];
        [viewController setMetadata:tdd.repositoryItem.metadata];
        [viewController setPropertyInfo:tdd.properties];
        [viewController setIsVersionHistory:YES];
        
        [self.navigationController pushViewController:viewController animated:YES];
        
        [viewController release];
	}
    else if (request == self.versionHistoryRequest)
    {
        [self setVersionHistory:[self.versionHistoryRequest children]];
        [self updateAndReload];
    }
    
    versionHistoryActionInProgress = NO;
    [self stopHUD];
}

- (void) requestFailed:(ASIHTTPRequest *)request
{
    versionHistoryActionInProgress = NO;
	[self stopHUD];
}

#pragma mark - DownloadProgressBarDelegate methods

- (void)performVersionHistoryAction:(id)sender
{
    if (versionHistoryActionInProgress == NO)
    {
        versionHistoryActionInProgress = YES;
        VersionHistoryCellController *cell = (VersionHistoryCellController *)sender;
        RepositoryItem *versionItem = cell.repositoryItem;
        
        if (cell.selectionType == VersionHistorySelectionTypeRow)
        {
            if (versionItem.contentLocation)
            {
                NSURL *contentURL = [NSURL URLWithString:versionItem.contentLocation];
                self.downloadProgressBar = [DownloadProgressBar createAndStartWithURL:contentURL delegate:self 
                                                                              message:NSLocalizedString(@"Downloading Document", @"Downloading Document") 
                                                                             filename:versionItem.title 
                                                                          accountUUID:self.selectedAccountUUID 
                                                                             tenantID:self.tenantID];
                [self.downloadProgressBar setCmisObjectId:[versionItem guid]];
                [self.downloadProgressBar setCmisContentStreamMimeType:[[versionItem metadata] objectForKey:@"cmis:contentStreamMimeType"]];
                [self.downloadProgressBar setVersionSeriesId:[versionItem versionSeriesId]];
                [self.downloadProgressBar setRepositoryItem:versionItem];
                [self.downloadProgressBar setTag:0];
            }
            else
            {
                displayWarningMessageWithTitle(NSLocalizedString(@"noContentWarningMessage", @"This document has no content."), NSLocalizedString(@"noContentWarningTitle", @"No content"));
                versionHistoryActionInProgress = NO;
            }
        } 
        else 
        {
            [self startHUD];
            
            CMISTypeDefinitionHTTPRequest *down = [[CMISTypeDefinitionHTTPRequest alloc] initWithURL:[NSURL URLWithString:versionItem.describedByURL] 
                                                                                         accountUUID:self.selectedAccountUUID];
            [down setDelegate:self];
            [down setRepositoryItem:versionItem];
            [down startAsynchronous];
            [down setTenantID:self.tenantID];
            [self setMetadataRequest:down];
            [down release];
        }
    }
} 

- (void)download:(DownloadProgressBar *)down completeWithPath:(NSString *)filePath
{
    DownloadMetadata *fileMetadata = down.downloadMetadata;
    NSString *filename;
    
    if (fileMetadata.key)
    {
        filename = fileMetadata.key;
    }
    else
    {
        filename = down.filename;
    }
    
    if (down.tag == 0)
    {
        VersionHistoryWrapper *wrapper = [[VersionHistoryWrapper alloc] initWithRepositoryItem:down.repositoryItem];
        DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
        
        // If the document was updated we should not allow edit in the DocumentViewController since the version history is outdated
        if (wrapper.isLatestVersion)
        {
            // We use the original repositoryItem. The version history repository items does not include allowableActions
            [doc setCmisObjectId:[self.currentRepositoryItem guid]];
            [doc setCanEditDocument:[self.currentRepositoryItem canSetContentStream]];
        }
        else 
        {
            [doc setCmisObjectId:down.cmisObjectId];
        }
        
        [doc setContentMimeType:[down cmisContentStreamMimeType]];
        [doc setIsVersionDocument:![wrapper isLatestVersion]];
        [doc setHidesBottomBarWhenPushed:YES];
        [doc setSelectedAccountUUID:self.selectedAccountUUID];
        [doc setTenantID:self.tenantID];
        [doc setShowReviewButton:YES];

        [doc setFileName:filename];
        [doc setFilePath:filePath];
        [doc setFileMetadata:fileMetadata];
        [doc setIsRestrictedDocument:[[AlfrescoMDMLite sharedInstance] isRestrictedDocument:fileMetadata]];
        
        [self.navigationController pushViewController:doc animated:YES];
        [doc release];
        [wrapper release];
    }
    else
    {
        [self startHUD];
        
        //We need to move the file from ASI to the temp folder since it may be a file in the cache
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *tempPath = [FileUtils pathToTempFile:filename];
        //We only use it if the file is in the temp path
        if (![fileManager fileExistsAtPath:tempPath])
        {
            //Can happen when ASIHTTPRequest returns a cached file
            NSError *error = nil;
            //Ignore the error
            [fileManager moveItemAtPath:filePath toPath:tempPath error:&error];
            
            if (error)
            {
                AlfrescoLogDebug(@"Error copying file to temp path %@", [error description]);
            }
        }
        
        [[FileDownloadManager sharedInstance] setDownload:fileMetadata.downloadInfo forKey:filename withFilePath:filename];
        [self stopHUD];
        displayInformationMessage(NSLocalizedString(@"documentview.download.confirmation.title", @"Document Saved"));
    }
    versionHistoryActionInProgress= NO;
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down
{
    versionHistoryActionInProgress = NO;
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - MBProgressHUD Helper Methods

- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.view);
	}
}

- (void)stopHUD
{
	if (self.HUD)
    {
        stopProgressHUD(self.HUD);
		self.HUD = nil;
	}
}

#pragma mark - NSNotificationCenter methods

- (void)documentUpdated:(NSNotification *) notification
{
    NSString *objectId = [[notification userInfo] objectForKey:@"objectId"];
    if ([[self.currentRepositoryItem guid] isEqualToString:objectId])
    {
        [self reloadVersionHistory];
    }
}

@end
