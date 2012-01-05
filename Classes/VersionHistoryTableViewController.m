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
#import "MBProgressHUD.h"
#import "CMISTypeDefinitionHTTPRequest.h"
#import "Theme.h"
#import "MetaDataTableViewController.h"
#import "VersionHistoryCellController.h"
#import "VersionHistoryWrapper.h"
#import "DocumentViewController.h"
#import "IFTemporaryModel.h"
#import "TableCellViewController.h"
#import "Utility.h"
#import "IFButtonCellController.h"
#import "FileDownloadManager.h"
#import "SavedDocument.h"

@interface VersionHistoryTableViewController(private)
-(void)startHUD;
-(void)stopHUD;
@end

@implementation VersionHistoryTableViewController
@synthesize versionHistory;
@synthesize metadataRequest;
@synthesize HUD;
@synthesize downloadProgressBar;
@synthesize latestVersion;
@synthesize selectedAccountUUID;
@synthesize tenantID;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [metadataRequest clearDelegatesAndCancel];
    
    [versionHistory release];
    [metadataRequest release];
    [HUD release];
    [downloadProgressBar release];
    [latestVersion release];
    [selectedAccountUUID release];
    [tenantID release];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style versionHistory:(NSArray *)initialVersionHistory accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    self = [super initWithStyle:style];
    if(self) {
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
}

#pragma mark -
#pragma mark Generic Table View Construction
- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
        NSMutableDictionary *tempModel = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:self.versionHistory, nil] forKeys:[NSArray arrayWithObjects:@"versionHistory", nil]];
        
        [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:tempModel] autorelease]];
	}
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *groups =  [NSMutableArray array];
    NSMutableArray *mainGroup = [NSMutableArray array];
    [groups addObject:mainGroup];
    
    NSArray *itemHistory = [self.model objectForKey:@"versionHistory"];
    [self.tableView setAllowsSelection:YES];
    self.latestVersion = nil;
    
    
    for (RepositoryItem *repositoryItem in itemHistory) {
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
        
        NSString *title = [NSString stringWithFormat:@"Version: %@", wrapper.versionLabel];
        NSString *subtitle = [NSString stringWithFormat:@"Last Modified: %@\nLast Modified By: %@\nComment: %@\nCurrent Version: %@%@", formatDocumentDate(repositoryItem.lastModifiedDate), wrapper.lastAuthor, wrapper.comment, wrapper.isLatestVersion?NSLocalizedString(@"Yes", @"Yes"):NSLocalizedString(@"No", @"No"), savedLocally];
        
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
        if(self.latestVersion) {
            VersionHistoryWrapper *latestVersionWrapper = [[VersionHistoryWrapper alloc] initWithRepositoryItem:latestVersion];
            if([wrapper.versionLabel floatValue] > [latestVersionWrapper.versionLabel floatValue]) {
                self.latestVersion = wrapper.repositoryItem;
            }
            
            [latestVersionWrapper release];
        } else {
            self.latestVersion = wrapper.repositoryItem;
        }
        
        [wrapper release];
    }
    
    if([itemHistory count] == 0) {
        TableCellViewController *cell;
        
        cell = [[TableCellViewController alloc]initWithAction:nil onTarget:nil];
        cell.textLabel.text = NSLocalizedString(@"versionhistory.empty", @"No Version History Available");
        
        [cell.textLabel adjustsFontSizeToFitWidth];

        [mainGroup addObject:cell];
        [cell release];
        [self.tableView setAllowsSelection:NO];
    } else {
        NSMutableArray *downloadLatestGroup = [NSMutableArray array];
        IFButtonCellController *redownloadButton = [[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"versionhistory.download.latest", @"Download Latest Version") 
                                                                                      withAction:@selector(downloadLatestVersion:) onTarget:self];
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

- (void)downloadLatestVersion:(id)sender
{
    if (latestVersion.contentLocation) 
    {
        NSURL *contentURL = [NSURL URLWithString:latestVersion.contentLocation];
        
        self.downloadProgressBar = [DownloadProgressBar createAndStartWithURL:contentURL delegate:self 
                                                                      message:NSLocalizedString(@"Downloading Document", @"Downloading Document") 
                                                                     filename:latestVersion.title
                                                                  accountUUID:selectedAccountUUID 
                                                                     tenantID:tenantID];
        [downloadProgressBar setCmisObjectId:[latestVersion guid]];
        [downloadProgressBar setCmisContentStreamMimeType:[[latestVersion metadata] objectForKey:@"cmis:contentStreamMimeType"]];
        [downloadProgressBar setVersionSeriesId:[latestVersion versionSeriesId]];
        [downloadProgressBar setRepositoryItem:latestVersion];
        [downloadProgressBar setTag:1];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noContentWarningTitle", @"No content")
                                                        message:NSLocalizedString(@"noContentWarningMessage", @"This document has no content.") 
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
        
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(ASIHTTPRequest *)request
{	
	if ([request isKindOfClass:[CMISTypeDefinitionHTTPRequest class]]) {
		CMISTypeDefinitionHTTPRequest *tdd = (CMISTypeDefinitionHTTPRequest *) request;
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[tdd repositoryItem] 
                                                                                             accountUUID:selectedAccountUUID 
                                                                                                tenantID:tenantID];
        [viewController setCmisObjectId:tdd.repositoryItem.guid];
        [viewController setMetadata:tdd.repositoryItem.metadata];
        [viewController setPropertyInfo:tdd.properties];
        [viewController setIsVersionHistory:YES];
        
        [self.navigationController pushViewController:viewController animated:YES];
        
        [viewController release];
	}
    
    [self stopHUD];
}

- (void) requestFailed:(ASIHTTPRequest *)request {
	[self stopHUD];
}

#pragma mark -
#pragma mark DownloadProgressBarDelegate methods

- (void)performVersionHistoryAction:(id)sender
{
    VersionHistoryCellController *cell = (VersionHistoryCellController *)sender;
    RepositoryItem *versionItem = cell.repositoryItem;
    
    if(cell.selectionType == VersionHistoryRowSelection) {
        
        if (versionItem.contentLocation) {
            NSURL *contentURL = [NSURL URLWithString:versionItem.contentLocation];
            self.downloadProgressBar = [DownloadProgressBar createAndStartWithURL:contentURL delegate:self 
                                                                          message:NSLocalizedString(@"Downloading Document", @"Downloading Document") 
                                                                         filename:versionItem.title 
                                                                      accountUUID:selectedAccountUUID 
                                                                           tenantID:tenantID];
            [downloadProgressBar setCmisObjectId:[versionItem guid]];
            [downloadProgressBar setCmisContentStreamMimeType:[[versionItem metadata] objectForKey:@"cmis:contentStreamMimeType"]];
            [downloadProgressBar setVersionSeriesId:[versionItem versionSeriesId]];
            [downloadProgressBar setRepositoryItem:versionItem];
            [downloadProgressBar setTag:0];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noContentWarningTitle", @"No content")
                                                            message:NSLocalizedString(@"noContentWarningMessage", @"This document has no content.") 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    } 
    else 
    {
        [self startHUD];
        
        CMISTypeDefinitionHTTPRequest *down = [[CMISTypeDefinitionHTTPRequest alloc] initWithURL:[NSURL URLWithString:versionItem.describedByURL] 
                                                                                     accountUUID:selectedAccountUUID];
        [down setDelegate:self];
        [down setRepositoryItem:versionItem];
        [down startAsynchronous];
        [down setTenantID:self.tenantID];
        [self setMetadataRequest:down];
        [down release];
    }
} 

- (void)download:(DownloadProgressBar *)down completeWithPath:(NSString *)filePath{
    
    if(down.tag == 0) {
        DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
        [doc setCmisObjectId:down.cmisObjectId];
        [doc setContentMimeType:[down cmisContentStreamMimeType]];
        [doc setIsVersionDocument:YES];
        [doc setHidesBottomBarWhenPushed:YES];
        [doc setSelectedAccountUUID:selectedAccountUUID];
        [doc setTenantID:self.tenantID];
        
        DownloadMetadata *fileMetadata = down.downloadMetadata;
        NSString *filename;
        
        if(fileMetadata.key) {
            filename = fileMetadata.key;
        } else {
            filename = down.filename;
        }
        
        [doc setFileName:filename];
        [doc setFilePath:filePath];
        [doc setFileMetadata:fileMetadata];
        
        [self.navigationController pushViewController:doc animated:YES];
        [doc release];
    } else {
        DownloadMetadata *fileMetadata = down.downloadMetadata;
        
//        TODO: VERIFY AND MOVE IF NOT NEEDED
//
//        NSString *filename;
//        
//        if(fileMetadata.key) {
//            filename = fileMetadata.key;
//        } else {
//            filename = down.filename;
//        }
        
        //We need to move the file from ASI to the temp folder since it may be a file in the cache
        NSString *fileName = [filePath lastPathComponent];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *tempPath = [SavedDocument pathToTempFile:[filePath lastPathComponent]];
        //We only use it if the file is in the temp path
        if(![fileManager fileExistsAtPath:tempPath]) {
            //Can happen when ASIHTTPRequest returns a cached file
            NSError *error = nil;
            //Ignore the error
            [fileManager copyItemAtPath:filePath toPath:tempPath error:&error];
            
            if(error) {
                NSLog(@"Error copying file to temp path %@", [error description]);
            }
        }
        
        [[FileDownloadManager sharedInstance] setDownload:fileMetadata.downloadInfo forKey:[filePath lastPathComponent] withFilePath:fileName];
        UIAlertView *saveConfirmationAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.download.confirmation.title", @"")
                                                                        message:NSLocalizedString(@"documentview.download.confirmation.message", @"The document has been saved to your device")
                                                                       delegate:nil 
                                                              cancelButtonTitle: @"Close" 
                                                              otherButtonTitles:nil, nil];
        [saveConfirmationAlert show];
        [saveConfirmationAlert release];
    }
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}
    
    [self setHUD:[MBProgressHUD showHUDAddedTo:self.view animated:YES]];
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

@end
