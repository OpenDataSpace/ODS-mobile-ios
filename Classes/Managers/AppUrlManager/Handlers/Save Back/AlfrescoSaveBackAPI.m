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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  AlfrescoSaveBackAPI.m
//

#import "AlfrescoSaveBackAPI.h"

/**
 * AlfrescoBundleIdentifier can be matched against application in documentInteractionController:willBeginSendingToApplication:
 */
NSString * const AlfrescoBundleIdentifier = @"com.alfresco.mobile";

/**
 * The Alfresco private metadata will be stored in the annotation dictionary under this key. It should be returned in the
 * same format, using the same key, when invoking a Save Back operation.
 */
NSString * const AlfrescoSaveBackMetadataKey = @"AlfrescoMetadata";

/**
 * To limit the "Open In..." list of available apps during a Save Back operation, the document must be renamed so that
 * the following extension is appended to the filename. For example "My Document.docx.alf01"
 */
NSString * const AlfrescoSaveBackDocumentExtension = @".alf01";


/**
 * Save Back to Alfresco helper function.
 *
 * The function is given the path to a document and will return a URL representing a suitably renamed document
 * ready to participate in the Save Back operation. The renamed document will be created in the temporary directory.
 */
NSURL *alfrescoSaveBackURLForFilePath(NSString *filePath, NSError **error)
{
    NSString *tempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:filePath.pathComponents.lastObject];
    NSString *tempSaveBackPath = [tempFilename stringByAppendingString:AlfrescoSaveBackDocumentExtension];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:tempSaveBackPath])
    {
        if ([fileManager removeItemAtPath:tempSaveBackPath error:error] == NO)
        {
            return nil;
        }
    }
    
    if ([fileManager copyItemAtPath:filePath toPath:tempSaveBackPath error:error] == NO)
    {
        return nil;
    }
    
    return [NSURL fileURLWithPath:tempSaveBackPath];
}
