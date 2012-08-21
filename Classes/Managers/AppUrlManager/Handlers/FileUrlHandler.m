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
#import "Utility.h"
#import "AlfrescoAppDelegate.h"
#import "IpadSupport.h"
#import "AlfrescoUtils.h"
#import "FileUtils.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "CMISAtomEntryWriter.h"

@interface FileUrlHandler (private)
- (NSDictionary *)partnerInfoForIncomingFile:(id)annotation;
- (NSURL *)saveIncomingFileWithURL:(NSURL *)url;
- (NSURL *)saveIncomingFileWithURL:(NSURL *)url toFilePath:(NSString *)filePath;
- (BOOL)updateRepositoryNode:(DownloadMetadata *)fileMetadata fileURLToUpload:(NSURL *)fileURLToUpload;
- (BOOL)updateRepositoryNode:(DownloadMetadata *)fileMetadata fileURLToUpload:(NSURL *)fileURLToUpload withFileName:(NSString *)fileName;
- (void)displayContentsOfFileWithURL:(NSURL *)url;
@end

@implementation FileUrlHandler
@synthesize postProgressBar = _postProgressBar;

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
    // Check annotation data for Quickoffice integration
    NSString *receivedSecretUUID = [annotation objectForKey: PartnerApplicationSecretUUIDKey];
    NSString *partnerApplicationSecretUUID = externalAPIKey(APIKeyQuickoffice);
    NSDictionary *partnerInfo = [self partnerInfoForIncomingFile:annotation];
    
    if (partnerInfo != nil && [receivedSecretUUID isEqualToString:partnerApplicationSecretUUID])
    {
        // extract the file metadata, if present
        NSDictionary *fileMeta = [partnerInfo objectForKey:PartnerApplicationFileMetadataKey];
        NSString *originalFilePath = [partnerInfo objectForKey:PartnerApplicationDocumentPathKey];
        
        if (fileMeta != nil)
        {
            DownloadMetadata *downloadMeta = [[DownloadMetadata alloc] initWithDownloadInfo:fileMeta];
            
            // grab the content and upload it to the provided nodeRef
            if (originalFilePath != nil)
            {
                NSString *originalFileName = [[originalFilePath pathComponents] lastObject];
                [self updateRepositoryNode:downloadMeta fileURLToUpload:url withFileName:originalFileName];
            }
            else
            {
                NSLog(@"WARNING: File received with incomplete partner info!");
                [self updateRepositoryNode:downloadMeta fileURLToUpload:url];
            }
            
            [downloadMeta release];
        }
        else
        {
            // save the file locally to the downloads folder
            NSURL *saveToURL;
            if (originalFilePath != nil)
            {
                // the downloaded filename will have changed from the original
                saveToURL = [self saveIncomingFileWithURL:url toFilePath:originalFilePath];
            }
            else
            {
                // save with the name we were given
                saveToURL = [self saveIncomingFileWithURL:url];
            }
            
            // display the contents of the saved file
            [self displayContentsOfFileWithURL:saveToURL];
        }
    }
    else
    {
        // save the incoming file
        NSURL *saveToURL = [self saveIncomingFileWithURL:url];
        
        // Set the "do not backup" flag
        addSkipBackupAttributeToItemAtURL(saveToURL);
        
        // display the contents of the saved file
        [self displayContentsOfFileWithURL:saveToURL];
    }
}

#pragma mark - Private methods
- (NSDictionary *)partnerInfoForIncomingFile:(id)annotation
{
    NSDictionary *alfOptions = nil;
    
    if (annotation != nil)
    {
        NSLog(@"annotation = %@", annotation);
        
        alfOptions = [annotation objectForKey:PartnerApplicationInfoKey];
    }
    
    return alfOptions;
}

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
	BOOL fileExistsInFavorites = [fileManager fileExistsAtPath:saveToPath];
	if (fileExistsInFavorites) {
		[fileManager removeItemAtURL:saveToURL error:NULL];
		NSLog(@"Removed File '%@' From Favorites Folder", incomingFileName);
	}
    
    if ([fileManager fileExistsAtPath:[FileUtils pathToTempFile:incomingFileName]]) {
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

- (BOOL)updateRepositoryNode:(DownloadMetadata *)fileMetadata fileURLToUpload:(NSURL *)fileURLToUpload
{
    return [self updateRepositoryNode:fileMetadata fileURLToUpload:fileURLToUpload withFileName:nil];
}

- (BOOL)updateRepositoryNode:(DownloadMetadata *)fileMetadata fileURLToUpload:(NSURL *)fileURLToUpload withFileName:(NSString *)useFileName
{
    NSString *filePath = [fileURLToUpload path];
    
    // if we're given a "useFileName" then move the document to the new name
    if (useFileName != nil)
    {
        NSString *oldPath = [fileURLToUpload path];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        filePath = [FileUtils pathToTempFile:useFileName];
        if ([fileManager fileExistsAtPath:filePath])
        {
            [fileManager removeItemAtPath:filePath error:NULL];
        }
        
        BOOL isFileMoved = [fileManager moveItemAtPath:oldPath toPath:filePath error:NULL];
        if (!isFileMoved)
        {
            NSLog(@"ERROR: Could not move %@ to %@", oldPath, filePath);
            filePath = [fileURLToUpload path];
        }
    }
    
    NSLog(@"updating file at %@ to nodeRef: %@", filePath, fileMetadata.objectId);
    
    // extract node id from object id
	NSString *fileName = [[filePath pathComponents] lastObject];
    NSArray *idSplit = [fileMetadata.objectId componentsSeparatedByString:@"/"];
    NSString *nodeId = [idSplit objectAtIndex:3];
    
    // build CMIS setContent PUT request
    AlfrescoUtils *alfrescoUtils = [AlfrescoUtils sharedInstanceForAccountUUID:fileMetadata.accountUUID];
    NSURL *putLink = nil;
    if (fileMetadata.tenantID == nil)
    {
        putLink = [alfrescoUtils setContentURLforNode:nodeId];
    }
    else
    {
        putLink = [alfrescoUtils setContentURLforNode:nodeId tenantId:fileMetadata.tenantID];
    }
    
    NSLog(@"putLink = %@", putLink);
    
    NSString *putFile = [CMISAtomEntryWriter generateAtomEntryXmlForFilePath:filePath uploadFilename:fileName];
    
    // upload the updated content to the repository showing progress
    self.postProgressBar = [PostProgressBar createAndStartWithURL:putLink
                                                      andPostFile:putFile
                                                         delegate:self 
                                                          message:NSLocalizedString(@"postprogressbar.update.document", @"Updating Document")
                                                      accountUUID:fileMetadata.accountUUID
                                                    requestMethod:@"PUT" 
                                                    suppressErrors:YES];
    self.postProgressBar.fileData = [NSURL fileURLWithPath:filePath];
    
    return YES;
}

#pragma mark -
#pragma mark PostProgressBarDelegate
- (void) post:(PostProgressBar *)bar completeWithData:(NSData *)data
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

- (void) post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    if (data != nil)
    {
        NSURL *url = (NSURL *)data;
        NSLog(@"URL: %@", url);
        
        // save the URL so the prompt delegate can access it
        _updatedFileName = [[[url pathComponents] lastObject] copy];
        
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

#pragma mark - 
#pragma mark Alert Confirmation
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    if (buttonIndex == 1)
    {
        // copy the edited file to the Documents folder
        if ([FileUtils saveTempFile:_updatedFileName withName:_updatedFileName])
        {
            NSString *savedFilePath = [FileUtils pathToSavedFile:_updatedFileName];
            [self displayContentsOfFileWithURL:[[[NSURL alloc] initFileURLWithPath:savedFilePath] autorelease]];
        }
        else
        {
            NSLog(@"Failed to save the edited file %@ to Documents folder", _updatedFileName);
            
            [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"savetodocs.alert.title", @"Save Failed") 
                                         message:NSLocalizedString(@"savetodocs.alert.description", @"Failed to save the edited file to Downloads")
                                        delegate:nil 
                               cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK") 
                               otherButtonTitles:nil, nil] autorelease] show];
        }
        
        // release the updatedFileUrl
        [_updatedFileName release];
        _updatedFileName = nil;
    }
    
}

@end
