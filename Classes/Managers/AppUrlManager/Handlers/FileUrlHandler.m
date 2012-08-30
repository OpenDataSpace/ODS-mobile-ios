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
#import "FileUtils.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "CMISAtomEntryWriter.h"
#import "SaveBackMetadata.h"
#import "FavoriteManager.h"
#import "FavoriteFileDownloadManager.h"
#import "ConnectivityManager.h"

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
            saveBackMetadata = [[SaveBackMetadata  alloc] init];
            saveBackMetadata.accountUUID = downloadMeta.accountUUID;
            saveBackMetadata.tenantID = downloadMeta.tenantID;
            saveBackMetadata.objectId = downloadMeta.objectId;
            saveBackMetadata.originalPath = [partnerInfo objectForKey:LegacyDocumentPathKey];
            [downloadMeta release];
        }
        else
        {
            saveBackMetadata = [[SaveBackMetadata alloc] initWithDictionary:partnerInfo];
        }
    }
    else
    {
        // Check annotation data for Alfresco generic "Save Back" integration
        NSDictionary *alfrescoMetadata = [annotation objectForKey:AlfrescoSaveBackMetadataKey];
        if (alfrescoMetadata != nil)
        {
            saveBackMetadata = [[SaveBackMetadata alloc] initWithDictionary:alfrescoMetadata];
        }
    }

    // The location where we have saved the inbound file
    NSURL *saveToURL = nil;
    [self setSaveBackMetadata:saveBackMetadata];

    // Found Save Back metadata?
    if (saveBackMetadata != nil)
    {
        // Save the file back where it came from (or to a temp folder)
        saveToURL = [self saveIncomingFileWithURL:url toFilePath:saveBackMetadata.originalPath];

        // If there's a valid accountUUID then we may need to upload back to the Repository
        if (saveBackMetadata.accountUUID != nil)
        {
            // FavoriteManager integration
            FavoriteManager *favoriteManager = [FavoriteManager sharedManager];
            BOOL isSyncedFavorite = ([favoriteManager isSyncEnabled] &&
                                     [favoriteManager isNodeFavorite:saveBackMetadata.objectId inAccount:saveBackMetadata.accountUUID] &&
                                     [favoriteManager updateDocument:saveToURL objectId:saveBackMetadata.objectId accountUUID:saveBackMetadata.accountUUID]);
            if (isSyncedFavorite)
            {
                NSDictionary *downloadInfo = [[FavoriteFileDownloadManager sharedInstance] downloadInfoForFilename:saveBackMetadata.originalName];
                RepositoryItem *repositoryItem = [[[RepositoryItem alloc] initWithDictionary:downloadInfo] autorelease];

                // TODO: Is there a better way to get the RepositoryItem from the FavoriteManager?
                [self displayContentsOfFileWithURL:url repositoryItem:repositoryItem];
            }
            else
            {
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
            [self displayContentsOfFileWithURL:saveToURL];
        }
    }

    [saveBackMetadata release];
}

#pragma mark - Private methods

- (NSURL *)saveIncomingFileWithURL:(NSURL *)url
{
    return [self saveIncomingFileWithURL:url toFilePath:nil];
}

- (NSURL *)saveIncomingFileWithURL:(NSURL *)url toFilePath:(NSString *)filePath
{
    // TODO: lets be robust, make sure a file exists at the URL
	
	NSString *incomingFilePath = [url path];
	NSString *incomingFileName = [[incomingFilePath pathComponents] lastObject];
	NSString *saveToPath = filePath != nil ? filePath : [FileUtils pathToSavedFile:incomingFileName];
	NSURL *saveToURL = [NSURL fileURLWithPath:saveToPath];
    
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:saveToPath])
    {
		[fileManager removeItemAtURL:saveToURL error:NULL];
		NSLog(@"Removed File at '%@'", saveToPath);
	}
    
    BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtURL:url toURL:saveToURL error:NULL];

    return incomingFileMovedSuccessfully ? saveToURL : nil;
}

- (void)displayContentsOfFileWithPath:(NSString *)path
{
    [self displayContentsOfFileWithURL:[NSURL fileURLWithPath:path]];
}

- (void)displayContentsOfFileWithURL:(NSURL *)url
{
    [self displayContentsOfFileWithURL:url repositoryItem:nil];
}

- (void)displayContentsOfFileWithURL:(NSURL *)url repositoryItem:(RepositoryItem *)repositoryItem
{
    NSString *incomingFilePath = [url path];
	NSString *incomingFileName = [[incomingFilePath pathComponents] lastObject];
    
    DocumentViewController *viewController = [[[DocumentViewController alloc] 
                                               initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]] autorelease];
    
    NSString *filename = incomingFileName;
    
    if (repositoryItem)
    {
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
        [viewController setContentMimeType:fileMetadata.contentStreamMimeType];
        [viewController setSelectedAccountUUID:fileMetadata.accountUUID];
        [viewController setTenantID:fileMetadata.tenantID];
    }
    else
    {
        [viewController setIsDownloaded:YES];
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:incomingFilePath];
    [viewController setFileName:filename];
	[viewController setFileData:fileData];
	[viewController setHidesBottomBarWhenPushed:YES];
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    
	[IpadSupport pushDetailController:viewController withNavigation:appDelegate.navigationController andSender:self];
}

- (BOOL)updateRepositoryNodeFromFileAtURL:(NSURL *)fileURLToUpload
{
    NSString *filePath = [fileURLToUpload path];
	NSString *fileName = self.saveBackMetadata.originalName;

    NSLog(@"updating file at %@ to nodeRef: %@", filePath, self.saveBackMetadata.objectId);

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
    
    NSLog(@"putLink = %@", putLink);
    
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
        [self displayContentsOfFileWithURL:url repositoryItem:bar.repositoryItem];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"reload",
                                    [bar.repositoryItem guid], @"itemGuid",
                                    nil];
        [[NSNotificationCenter defaultCenter] postUploadFinishedNotificationWithUserInfo:userInfo];
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
    UIAlertView *failurePrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"updatefailed.alert.title", @"Save Failed")
                                                            message:NSLocalizedString(@"updatefailed.alert.confirm", @"Do you want to save the file to the Downloads folder?")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                  otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [failurePrompt show];
    [failurePrompt release];
}

- (void)presentNoNetworkAlertForURL:(NSURL *)url
{
    // save the URL so the prompt delegate can access it
    [self setUpdatedFileURL:url];
    
    UIAlertView *failurePrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"updatenonetwork.alert.title", @"No Network")
                                                            message:NSLocalizedString(@"updatenonetwork.alert.confirm", @"Do you want to save the file to the Downloads folder?")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                  otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [failurePrompt show];
    [failurePrompt release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        // copy the edited file to the Documents folder
        NSString *savedFile = [FileUtils saveFileToDownloads:[self.updatedFileURL path]
                                                    withName:self.saveBackMetadata.originalName allowSuffix:YES];
        
        if (savedFile != nil)
        {
            [self displayContentsOfFileWithPath:savedFile];
        }
        else
        {
            NSLog(@"Failed to save the edited file %@ to Documents folder", self.updatedFileURL);
            
            [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"savetodocs.alert.title", @"Save Failed") 
                                         message:NSLocalizedString(@"savetodocs.alert.description", @"Failed to save the edited file to Downloads")
                                        delegate:nil 
                               cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK") 
                               otherButtonTitles:nil, nil] autorelease] show];
        }
    }
}

@end
