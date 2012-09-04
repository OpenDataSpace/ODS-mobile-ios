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
//  AbstractFileDownloadManager.h
//

#import <Foundation/Foundation.h>
#import "NSString+MD5.h"
#import "FileUtils.h"
#import "Utility.h"
#import "FileProtectionManager.h"

#define kUseHash NO

@interface AbstractFileDownloadManager : NSObject
{
    @private
    
    BOOL reload;
    NSMutableDictionary *downloadMetadata;
}

+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;

- (NSDictionary *) downloadInfoForKey:(NSString *) key;
- (NSDictionary *) downloadInfoForFilename:(NSString *) filename;
-(NSDictionary *) downloadInfoForDocumentWithID:(NSString *) objectID;
// Set Download will persist the metadataInfo and also save the file document
// Will revert everything back if something went wrong
// returns the saved file name if everything was successful, nil if something went wrong
- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) tempFile;
- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key;

- (BOOL) updateDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) path;

-(void) updateLastModifiedDate:(NSString *) lastModificationDate  andLastDownloadDateForFilename:(NSString *) filename;

// Remove Download will persist the metadataInfo remove and also delete the file document
// Will revert everything back if something went wrong
// returns YES if everything was successful, NO if something went wrong
- (BOOL) removeDownloadInfoForFilename:(NSString *) filename;
- (void) removeDownloadInfoForAllFiles;

- (BOOL) downloadExistsForKey: (NSString *) key;

- (void) reloadInfo;
- (void) deleteDownloadInfo;

- (NSString *)metadataPath;
- (NSString *)oldMetadataPath;

-(NSString *) pathComponentToFile:(NSString *) fileName;
-(NSString *) pathToFileDirectory:(NSString*) fileName;

- (NSMutableDictionary *) readMetadata;
- (BOOL) writeMetadata;

@end
