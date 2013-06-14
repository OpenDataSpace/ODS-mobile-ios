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
//  FileUrlHandler.m
//

#import "FileUrlHandler.h"
#import "DownloadMetadata.h"
#import "DownloadInfo.h"
#import "QOPartnerApplicationAnnotationKeys.h"
#import "DocumentViewController.h"
#import "FileDownloadManager.h"
#import "AlfrescoAppDelegate.h"
#import "IpadSupport.h"
#import "AlfrescoUtils.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "CMISAtomEntryWriter.h"
#import "SaveBackMetadata.h"
#import "FavoriteFileDownloadManager.h"
#import "ConnectivityManager.h"
#import "MoreViewController.h"
#import "ISO8601DateFormatter.h"

@interface FileUrlHandler ()
@property (nonatomic, retain) PostProgressBar *postProgressBar;
@property (nonatomic, retain) NSURL *updatedFileURL;
@property (nonatomic, retain) SaveBackMetadata *saveBackMetadata;
@end

@implementation FileUrlHandler
@synthesize postProgressBar = _postProgressBar;
@synthesize updatedFileURL = _updatedFileURL;
@synthesize saveBackMetadata = _saveBackMetadata;

NSString * const LegacyFileMetadataKey = @"PartnerApplicationFileMetadataKey";
NSString * const LegacyDocumentPathKey = @"PartnerApplicationDocumentPath";


- (void)dealloc
{
    [_postProgressBar release];
    [_updatedFileURL release];
    [_saveBackMetadata release];
    [super dealloc];
}

- (NSString *)handledUrlPrefix:(NSString *)defaultAppScheme
{
    return @"file://";
}

- (void)handleUrl:(NSURL *)url annotation:(id)annotation
{
    // Common Save Back parameters
    SaveBackMetadata *saveBackMetadata = nil;

    // Check annotation data for Quickoffice "Save Back" integration
    NSString *receivedSecretUUID = [annotation objectForKey:QuickofficeApplicationSecretUUIDKey];
    if ([receivedSecretUUID isEqualToString:externalAPIKey(APIKeyQuickoffice)])
    {
        NSDictionary *partnerInfo = [annotation objectForKey:QuickofficeApplicationInfoKey];

        // Check for legacy data, pre-1.4
        // This possibility might arise if the Alfresco app is upgraded whilst documents are still being edited
        // in Quickoffice.
        NSDictionary *legacyMetadata = [partnerInfo objectForKey:LegacyFileMetadataKey];
        if (legacyMetadata != nil)
        {
            DownloadMetadata *downloadMeta = [[DownloadMetadata alloc] initWithDownloadInfo:legacyMetadata];
            saveBackMetadata = [[[SaveBackMetadata  alloc] init] autorelease];
            saveBackMetadata.accountUUID = downloadMeta.accountUUID;
            saveBackMetadata.tenantID = downloadMeta.tenantID;
            saveBackMetadata.objectId = downloadMeta.objectId;
            saveBackMetadata.originalPath = [partnerInfo objectForKey:LegacyDocumentPathKey];
            [downloadMeta release];
        }
        else
        {
            saveBackMetadata = [[[SaveBackMetadata alloc] initWithDictionary:partnerInfo] autorelease];
        }
    }
    else
    {
        // Check annotation data for Alfresco generic "Save Back" integration
        NSDictionary *alfrescoMetadata = [annotation objectForKey:AlfrescoSaveBackMetadataKey];
        if (alfrescoMetadata != nil)
        {
            saveBackMetadata = [[[SaveBackMetadata alloc] initWithDictionary:alfrescoMetadata] autorelease];
        }
    }

    // The location where we have saved the inbound file
    NSURL *saveToURL = nil;
    [self setSaveBackMetadata:saveBackMetadata];

    // Found Save Back metadata?
    if (saveBackMetadata != nil)
    {
        // If there's a valid accountUUID then we may need to upload back to the Repository
        if (saveBackMetadata.accountUUID != nil)
        {
            // FavoriteManager integration
            FavoriteManager *favoriteManager = [FavoriteManager sharedManager];
            BOOL isSyncedFavorite = ([favoriteManager isSyncPreferenceEnabled] &&
                                     [favoriteManager isNodeFavorite:saveBackMetadata.objectId accountUUID:saveBackMetadata.accountUUID tenantID:saveBackMetadata.tenantID]);
            if (isSyncedFavorite)
            {
                FavoriteFileDownloadManager *fileDownloadManager = [FavoriteFileDownloadManager sharedInstance];
                NSDictionary *downloadInfo = [favoriteManager downloadInfoForDocumentWithID:saveBackMetadata.objectId];
                RepositoryItem *repositoryItem = [[[RepositoryItem alloc] initWithDictionary:downloadInfo] autorelease];
                NSString *generatedFileName = [fileDownloadManager generatedNameForFile:[downloadInfo objectForKey:@"filename"] withObjectID:saveBackMetadata.objectId];
                NSString *syncedFilePath = [fileDownloadManager pathToFileDirectory:generatedFileName];

                // Save the file back where it came from (or to a temp folder)
                saveToURL = [self saveIncomingFileWithURL:url toFilePath:syncedFilePath];
                if (saveToURL != nil)
                {
                    // display the contents of the saved file
                    [self displayRepositoryFileWithURL:saveToURL repositoryItem:repositoryItem];
                    [favoriteManager forceSyncForFileURL:saveToURL objectId:saveBackMetadata.objectId accountUUID:saveBackMetadata.accountUUID];
                }
            }
            else
            {
                NSArray *originalPathComponents = [saveBackMetadata.originalPath pathComponents];
                if ([originalPathComponents containsObject:kSyncedFilesDirectory])
                {
                    // The file has been unfavorited between Open In... and now, so it can't be saved back to the Synced Files directory
                    saveBackMetadata.originalPath = [FileUtils pathToTempFile:saveBackMetadata.originalName];
                }
                // Save the file back where it came from (or to a temp folder)
                saveToURL = [self saveIncomingFileWithURL:url toFilePath:saveBackMetadata.originalPath withFileName:saveBackMetadata.originalName];

                // Give the Reachability code some time to run, otherwise we might get a false indication
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    // Check current reachability status via ConnectivityManager
                    ConnectivityManager *connectivityManager = [ConnectivityManager sharedManager];
                    if (connectivityManager.hasInternetConnection)
                    {
                        // grab the content and upload it to the provided nodeRef
                        [self updateRepositoryNodeFromFileAtURL:saveToURL];
                    }
                    else
                    {
                        [self presentNoNetworkAlertForURL:saveToURL];
                    }
                });
            }
        }
        else
        {
            // Save the file back where it came from (or to a temp folder)
            saveToURL = [self saveIncomingFileWithURL:url toFilePath:saveBackMetadata.originalPath withFileName:saveBackMetadata.originalName];
            
            if (saveToURL != nil)
            {
                // display the contents of the saved file
                [self displayDownloadedFileWithURL:saveToURL];
            }
        }
    }
    else
    {
        // Save the incoming file
        saveToURL = [self saveIncomingFileWithURL:url];

        // Set the "do not backup" flag
        addSkipBackupAttributeToItemAtURL(saveToURL);

        if (saveToURL != nil)
        {
            // display the contents of the saved file
            [self displayDownloadedFileWithURL:saveToURL];
        }
    }
}

#pragma mark - Private methods

- (NSURL *)saveIncomingFileWithURL:(NSURL *)url
{
    return [self saveIncomingFileWithURL:url toFilePath:nil withFileName:nil];
}

- (NSURL *)saveIncomingFileWithURL:(NSURL *)url toFilePath:(NSString *)filePath
{
    return [self saveIncomingFileWithURL:url toFilePath:filePath withFileName:nil];
}

- (NSURL *)saveIncomingFileWithURL:(NSURL *)url toFilePath:(NSString *)filePath withFileName:fileName
{
	NSString *incomingFilePath = [url path];
	NSString *incomingFileName = fileName != nil ? fileName : [[incomingFilePath pathComponents] lastObject];
	NSString *saveToPath = filePath != nil ? filePath : [FileUtils pathToSavedFile:incomingFileName];
	NSURL *saveToURL = [NSURL fileURLWithPath:saveToPath];
    
    if ([saveToURL isEqual:url])
    {
        return saveToURL;
    }
    
	NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
	if ([fileManager fileExistsAtPath:saveToPath])
    {
		[fileManager removeItemAtPath:saveToPath error:&error];
	}
    
    BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtPath:[url path] toPath:saveToPath error:&error];
    return incomingFileMovedSuccessfully ? saveToURL : nil;
}

- (void)displayDownloadedFileWithPath:(NSString *)path
{
    [self displayDownloadedFileWithURL:[NSURL fileURLWithPath:path]];
}

- (void)displayDownloadedFileWithURL:(NSURL *)url
{
    NSString *incomingFilePath = [url path];
	NSString *filename = [[incomingFilePath pathComponents] lastObject];
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    DocumentViewController *viewController = [[[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]] autorelease];
    [viewController setIsDownloaded:YES];
    
    /**
     * Ensure DownloadsViewController is either visible (iPad) or in the navigation stack (iPhone)
     */
    UINavigationController *moreNavController = appDelegate.moreNavController;
    [moreNavController popToRootViewControllerAnimated:NO];
    
    MoreViewController *moreViewController = (MoreViewController *)[moreNavController.viewControllers objectAtIndex:0];
    [moreViewController view]; // Ensure the controller's view is loaded
    [moreViewController showDownloadsViewWithSelectedFileURL:[NSURL fileURLWithPath:incomingFilePath]];
    [appDelegate.tabBarController setSelectedViewController:moreNavController];
    
    if (IS_IPAD)
    {
        [IpadSupport clearDetailController];
        [IpadSupport showMasterPopover];
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:incomingFilePath];
    [viewController setFileName:filename];
    [viewController setFileData:fileData];
    [viewController setFilePath:incomingFilePath];
    [viewController setHidesBottomBarWhenPushed:YES];
    
    if (IS_IPAD)
    {
        [IpadSupport pushDetailController:viewController withNavigation:moreNavController andSender:self];
    }
    else
    {
        [moreNavController pushViewController:viewController animated:NO];
    }

    // Updated document parameters notification
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"objectId",
                              [url path], @"newPath", nil];
    [[NSNotificationCenter defaultCenter] postDocumentUpdatedNotificationWithUserInfo:userInfo];
}

- (void)displayRepositoryFileWithURL:(NSURL *)url repositoryItem:(RepositoryItem *)repositoryItem
{
    NSString *incomingFilePath = [url path];
	NSString *filename = [[incomingFilePath pathComponents] lastObject];
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];

    DocumentViewController *viewController = [[[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]] autorelease];
    
    DownloadInfo *downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:repositoryItem] autorelease];
    DownloadMetadata *fileMetadata = downloadInfo.downloadMetadata;
    [fileMetadata setAccountUUID:self.saveBackMetadata.accountUUID];
    [fileMetadata setTenantID:self.saveBackMetadata.tenantID];
    
    if (fileMetadata.key)
    {
        filename = fileMetadata.key;
    }
    [viewController setFileMetadata:fileMetadata];
    [viewController setCmisObjectId:fileMetadata.objectId];
    [viewController setCanEditDocument:YES];
    [viewController setContentMimeType:fileMetadata.contentStreamMimeType];
    [viewController setSelectedAccountUUID:fileMetadata.accountUUID];
    [viewController setTenantID:fileMetadata.tenantID];
    [viewController setIsRestrictedDocument:[[AlfrescoMDMLite sharedInstance] isRestrictedDocument:fileMetadata]];
    
    NSData *fileData = [NSData dataWithContentsOfFile:incomingFilePath];
    [viewController setFileName:filename];
    [viewController setFileData:fileData];
    [viewController setFilePath:incomingFilePath];
    [viewController setHidesBottomBarWhenPushed:YES];

    UINavigationController *currentNavController = [appDelegate.tabBarController.viewControllers objectAtIndex:appDelegate.tabBarController.selectedIndex];

    if (IS_IPAD)
    {
        if (![[IpadSupport getCurrentDetailViewControllerObjectID] isEqualToString:repositoryItem.guid] &&
            ![[IpadSupport getCurrentDetailViewControllerFileURL] isEqual:url])
        {
            [IpadSupport pushDetailController:viewController withNavigation:currentNavController andSender:self];
        }
    }
    else
    {
        id currentViewController = [currentNavController.viewControllers lastObject];
        if ([currentViewController isKindOfClass:[DocumentViewController class]])
        {
            NSString *objectID = [((DocumentViewController *)currentViewController) cmisObjectId];
            NSURL *fileURL = [NSURL fileURLWithPath:[((DocumentViewController *)currentViewController) filePath]];
            if ([objectID isEqualToString:repositoryItem.guid] || [fileURL isEqual:url])
            {
                [currentNavController popViewControllerAnimated:NO];
            }
        }
        [currentNavController pushViewController:viewController animated:NO];
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:repositoryItem.guid, @"objectId",
                              [url path], @"newPath",
                              repositoryItem, @"repositoryItem", nil];
    [[NSNotificationCenter defaultCenter] postDocumentUpdatedNotificationWithUserInfo:userInfo];
}

- (BOOL)updateRepositoryNodeFromFileAtURL:(NSURL *)fileURLToUpload
{
    NSString *filePath = [fileURLToUpload path];
	NSString *fileName = self.saveBackMetadata.originalName;

    AlfrescoLogDebug(@"updating file at %@ to nodeRef: %@", filePath, self.saveBackMetadata.objectId);

    // extract node id from objectId (nodeRef)
    NSArray *idSplit = [self.saveBackMetadata.objectId componentsSeparatedByString:@"/"];
    NSString *nodeId = [idSplit objectAtIndex:3];
    
    // build CMIS setContent PUT request
    AlfrescoUtils *alfrescoUtils = [AlfrescoUtils sharedInstanceForAccountUUID:self.saveBackMetadata.accountUUID];
    NSURL *putLink = nil;
    if (self.saveBackMetadata.tenantID == nil)
    {
        putLink = [alfrescoUtils setContentURLforNode:nodeId];
    }
    else
    {
        putLink = [alfrescoUtils setContentURLforNode:nodeId tenantId:self.saveBackMetadata.tenantID];
    }
    
    AlfrescoLogDebug(@"putLink = %@", putLink);
    
    NSString *putFile = [CMISAtomEntryWriter generateAtomEntryXmlForFilePath:filePath uploadFilename:fileName];
    
    // upload the updated content to the repository showing progress
    self.postProgressBar = [PostProgressBar createAndStartWithURL:putLink
                                                      andPostFile:putFile
                                                         delegate:self 
                                                          message:NSLocalizedString(@"postprogressbar.update.document", @"Updating Document")
                                                      accountUUID:self.saveBackMetadata.accountUUID
                                                    requestMethod:@"PUT" 
                                                    suppressErrors:YES];
    self.postProgressBar.fileData = (id)fileURLToUpload; //[NSURL fileURLWithPath:filePath];
    
    return YES;
}

#pragma mark - PostProgressBarDelegate

- (void)post:(PostProgressBar *)bar completeWithData:(NSData *)data
{
    if (data != nil)
    {
        NSURL *url = (NSURL *)data;
        [self displayRepositoryFileWithURL:url repositoryItem:bar.repositoryItem];
    }
}

- (void)post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    if (data != nil)
    {
        NSURL *url = (NSURL *)data;
        [self presentUploadFailedAlertForURL:url];
    }
}

#pragma mark -  Alert Confirmation

- (void)presentUploadFailedAlertForURL:(NSURL *)url
{
    // save the URL so the prompt delegate can access it
    [self setUpdatedFileURL:url];
    
    // TODO: show error about authentication and prompt user to save to downloads area
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"updatefailed.alert.title", @"Save Failed")
                                 message:NSLocalizedString(@"updatefailed.alert.confirm", @"Do you want to save the file to the Downloads folder?")
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"No", @"No")
                       otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease] show];
}

- (void)presentNoNetworkAlertForURL:(NSURL *)url
{
    // save the URL so the prompt delegate can access it
    [self setUpdatedFileURL:url];
    
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"updatenonetwork.alert.title", @"No Network")
                                 message:NSLocalizedString(@"updatenonetwork.alert.confirm", @"Do you want to save the file to the Downloads folder?")
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"No", @"No")
                       otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease] show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        // copy the edited file to the Documents folder
        NSString *savedFile = [FileUtils saveFileToDownloads:[self.updatedFileURL path]
                                                    withName:self.saveBackMetadata.originalName overwriteExisting:NO];
        
        if (savedFile != nil)
        {
            [self displayDownloadedFileWithPath:savedFile];
        }
        else
        {
            AlfrescoLogDebug(@"Failed to save the edited file %@ to Documents folder", self.updatedFileURL);
            
            displayErrorMessageWithTitle(NSLocalizedString(@"savetodocs.alert.description", @"Failed to save the edited file to Downloads"), NSLocalizedString(@"savetodocs.alert.title", @"Save Failed"));
        }
    }
}

@end
