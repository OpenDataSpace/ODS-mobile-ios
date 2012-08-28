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

@interface FileUrlHandler ()
@property (nonatomic, retain) PostProgressBar *postProgressBar;
@property (nonatomic, retain) NSString *updatedFileName;
@end

@interface FileUrlHandler (private)
- (NSURL *)saveIncomingFileWithURL:(NSURL *)url;
- (NSURL *)saveIncomingFileWithURL:(NSURL *)url toFilePath:(NSString *)filePath;
- (BOOL)updateRepositoryNode:(SaveBackMetadata *)saveBackMetadata fileURLToUpload:(NSURL *)fileURLToUpload;
- (void)displayContentsOfFileWithURL:(NSURL *)url;
@end

@implementation FileUrlHandler
@synthesize postProgressBar = _postProgressBar;
@synthesize updatedFileName = _updatedFileName;

NSString * const LegacyFileMetadataKey = @"PartnerApplicationFileMetadataKey";
NSString * const LegacyDocumentPathKey = @"PartnerApplicationDocumentPath";

- (void)dealloc
{
    [_postProgressBar release];
    [_updatedFileName release];
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
            saveBackMetadata.originalName = [partnerInfo objectForKey:LegacyDocumentPathKey];
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

    // Found Save Back metadata?
    if (saveBackMetadata != nil)
    {
        // If there's a valid accountUUID then upload back to the Repository
        if (saveBackMetadata.accountUUID != nil)
        {
            // grab the content and upload it to the provided nodeRef
            [self updateRepositoryNode:saveBackMetadata fileURLToUpload:url];
        }
        else
        {
            // ...otherwise it came from the Documents folder
            if (saveBackMetadata.originalName != nil)
            {
                // the downloaded filename may have changed from the original
                saveToURL = [self saveIncomingFileWithURL:url toFilePath:saveBackMetadata.originalName];
            }
            else
            {
                // save with the name we were given
                saveToURL = [self saveIncomingFileWithURL:url];
            }
        }
    }
    else
    {
        // Save the incoming file
        saveToURL = [self saveIncomingFileWithURL:url];

        // Set the "do not backup" flag
        addSkipBackupAttributeToItemAtURL(saveToURL);
    }

    if (saveToURL != nil)
    {
        // display the contents of the saved file
        [self displayContentsOfFileWithURL:saveToURL];
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
    NSURL *saveToURL;
    
    // TODO: lets be robust, make sure a file exists at the URL
	
	NSString *incomingFilePath = [url path];
	NSString *incomingFileName = [[incomingFilePath pathComponents] lastObject];
	NSString *saveToPath = filePath != nil ? filePath : [FileUtils pathToSavedFile:incomingFileName];
	saveToURL = [NSURL fileURLWithPath:saveToPath];
    
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:saveToPath])
    {
		[fileManager removeItemAtURL:saveToURL error:NULL];
		NSLog(@"Removed File '%@' From Downloads Folder", incomingFileName);
	}
    
    if ([fileManager fileExistsAtPath:[FileUtils pathToTempFile:incomingFileName]])
    {
        NSURL *tempURL = [NSURL fileURLWithPath:[FileUtils pathToTempFile:incomingFileName]];
        [fileManager removeItemAtURL:tempURL error:NULL];
    }
    
    //	BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtURL:url toURL:saveToURL error:NULL];
	BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtPath:[url path] toPath:[saveToURL path] error:NULL];
	if (!incomingFileMovedSuccessfully) 
    {
        // return nil if document move failed.
		saveToURL = nil;
	}
    
    return saveToURL;
}

- (void)displayContentsOfFileWithURL:(NSURL *)url
{
    NSString *incomingFilePath = [url path];
	NSString *incomingFileName = [[incomingFilePath pathComponents] lastObject];
    
    DocumentViewController *viewController = [[[DocumentViewController alloc] 
                                               initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]] autorelease];
    
    NSDictionary *downloadInfo = [[FileDownloadManager sharedInstance] downloadInfoForFilename:incomingFileName];
    NSString *filename = incomingFileName;
    
    if (downloadInfo)
    {
        DownloadMetadata *fileMetadata = [[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo];
        
        if (fileMetadata.key)
        {
            filename = fileMetadata.key;
        }
        [viewController setFileMetadata:fileMetadata];
        [viewController setCmisObjectId:fileMetadata.objectId];
        [viewController setContentMimeType:fileMetadata.contentStreamMimeType];
        [viewController setSelectedAccountUUID:fileMetadata.accountUUID];
        [viewController setTenantID:fileMetadata.tenantID];
        [fileMetadata release];
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

- (BOOL)updateRepositoryNode:(SaveBackMetadata *)saveBackMetadata fileURLToUpload:(NSURL *)fileURLToUpload
{
    NSString *filePath = [fileURLToUpload path];
    
    NSLog(@"updating file at %@ to nodeRef: %@", filePath, saveBackMetadata.objectId);

    // Default filename - use the filename we have been given
	NSString *fileName = [[filePath pathComponents] lastObject];
    if (saveBackMetadata.originalName != nil)
    {
        // The original name was also given, so use that instead
        fileName = [[saveBackMetadata.originalName pathComponents] lastObject];
    }

    // extract node id from objectId (nodeRef)
    NSArray *idSplit = [saveBackMetadata.objectId componentsSeparatedByString:@"/"];
    NSString *nodeId = [idSplit objectAtIndex:3];
    
    // build CMIS setContent PUT request
    AlfrescoUtils *alfrescoUtils = [AlfrescoUtils sharedInstanceForAccountUUID:saveBackMetadata.accountUUID];
    NSURL *putLink = nil;
    if (saveBackMetadata.tenantID == nil)
    {
        putLink = [alfrescoUtils setContentURLforNode:nodeId];
    }
    else
    {
        putLink = [alfrescoUtils setContentURLforNode:nodeId tenantId:saveBackMetadata.tenantID];
    }
    
    NSLog(@"putLink = %@", putLink);
    
    NSString *putFile = [CMISAtomEntryWriter generateAtomEntryXmlForFilePath:filePath uploadFilename:fileName];
    
    // upload the updated content to the repository showing progress
    self.postProgressBar = [PostProgressBar createAndStartWithURL:putLink
                                                      andPostFile:putFile
                                                         delegate:self 
                                                          message:NSLocalizedString(@"postprogressbar.update.document", @"Updating Document")
                                                      accountUUID:saveBackMetadata.accountUUID
                                                    requestMethod:@"PUT" 
                                                    suppressErrors:YES];
    self.postProgressBar.fileData = [NSURL fileURLWithPath:filePath];
    
    return YES;
}

#pragma mark - PostProgressBarDelegate

- (void)post:(PostProgressBar *)bar completeWithData:(NSData *)data
{
    if (data != nil)
    {
        NSURL *url = (NSURL *)data;
        NSLog(@"URL: %@", url);
        [self displayContentsOfFileWithURL:url];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"reload",
                                   [bar.repositoryItem guid], @"itemGuid" ,nil];
        [[NSNotificationCenter defaultCenter] postUploadFinishedNotificationWithUserInfo:userInfo];
    }
}

- (void)post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    if (data != nil)
    {
        NSURL *url = (NSURL *)data;

        // save the URL so the prompt delegate can access it
        [self setUpdatedFileName:url.pathComponents.lastObject];
        
        // TODO: show error about authentication and prompt user to save to downloads area
        UIAlertView *failurePrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"updatefailed.alert.title", @"Save Failed") 
                                                                message:NSLocalizedString(@"updatefailed.alert.confirm", @"Do you want to save the file to the Downloads folder?") 
                                                               delegate:self 
                                                      cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                                                      otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
        [failurePrompt show];
        [failurePrompt release];
    }
}

#pragma mark -  Alert Confirmation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    if (buttonIndex == 1)
    {
        // copy the edited file to the Documents folder
        if ([FileUtils saveTempFile:self.updatedFileName withName:self.updatedFileName])
        {
            NSString *savedFilePath = [FileUtils pathToSavedFile:self.updatedFileName];
            [self displayContentsOfFileWithURL:[[[NSURL alloc] initFileURLWithPath:savedFilePath] autorelease]];
        }
        else
        {
            NSLog(@"Failed to save the edited file %@ to Documents folder", self.updatedFileName);
            
            [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"savetodocs.alert.title", @"Save Failed") 
                                         message:NSLocalizedString(@"savetodocs.alert.description", @"Failed to save the edited file to Downloads")
                                        delegate:nil 
                               cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK") 
                               otherButtonTitles:nil, nil] autorelease] show];
        }
    }
}

@end
