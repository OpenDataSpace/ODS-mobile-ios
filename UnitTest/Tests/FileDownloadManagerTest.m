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
//  FileDownloadManagerTest.m
//

#import <GHUnitIOS/GHUnit.h>
#import "FileDownloadManager.h"
#import "FileUtils.h"
#import "DownloadMetadata.h"

@interface FileDownloadManagerTest : GHTestCase { }

- (NSString *) moveFileToTempFolder;
- (NSString *) moveFileToDocumentsFolder;
@end

@implementation FileDownloadManagerTest
- (void)testSingleton {
    FileDownloadManager *fileManager = [FileDownloadManager sharedInstance];
    
    GHAssertNotNil(fileManager, @"Shared instance was nil", nil);
    GHAssertEquals(fileManager, [FileDownloadManager sharedInstance], @"Shared instance is not unique", nil);
    GHAssertEquals(fileManager, [fileManager copyWithZone:nil], @"Shared instance is not unique", nil);
}

- (void) testSaveDownload {
    FileDownloadManager *fileManager = [FileDownloadManager sharedInstance];
    
    NSDictionary *downInfo = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DownloadInfo" ofType:@"plist"]];
    DownloadMetadata *metadata = [[DownloadMetadata alloc] initWithDownloadInfo:downInfo]; 
    NSString *tempFile = [self moveFileToTempFolder];
    
    GHTestLog(@"Loaded dictionary with %d objects and moved file to temp folder: %@", [downInfo count], tempFile, nil);
    
    NSString *savedName = [fileManager setDownload:downInfo forKey:metadata.key withFilePath:tempFile];
    GHAssertNotNil(savedName, @"Could not save the download file", nil);
    
    NSInteger count = [[fileManager downloadInfoForFilename:savedName] count];
    GHAssertEquals(5, count, @"Download Info was not saved, %d results in dictionary", count, nil);
    GHAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:savedName]], @"File was not created in the documents folder", nil);
    GHTestLog(@"File saved with name: %@", savedName, nil);
    [metadata release];
    [fileManager removeDownloadInfoForFilename:savedName];
}

- (void) testDeleteRegisteredDownload {
    FileDownloadManager *fileManager = [FileDownloadManager sharedInstance];
    
    NSDictionary *downInfo = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DownloadInfo" ofType:@"plist"]];
    NSString *tempFile = [self moveFileToTempFolder];
    DownloadMetadata *metadata = [[DownloadMetadata alloc] initWithDownloadInfo:downInfo]; 
    NSString *savedName = [fileManager setDownload:downInfo forKey:metadata.key withFilePath:tempFile];
    
    BOOL removed = [fileManager removeDownloadInfoForFilename:savedName];
    GHAssertTrue(removed, @"removeDownloadInfoForFilename: shold return YES", nil);
    GHAssertNil([fileManager downloadInfoForFilename:savedName],  @"Download Metadata exists for the deleted file", nil);
    GHAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:savedName]], @"File was not deleted in the documents folder", nil);
    GHTestLog(@"File deleted with name: %@", savedName, nil);
    [metadata release];
}

- (void) testDeleteLegacyDownload {
    FileDownloadManager *fileManager = [FileDownloadManager sharedInstance];
    NSString *legacyFile = [self moveFileToDocumentsFolder]; 
    
    GHAssertNil([fileManager downloadInfoForFilename:legacyFile], @"File metadata should not exist in the plist", nil);
    GHAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:legacyFile]], @"Legacy file should exist in the Documents folder", nil);
           
    BOOL removed = [fileManager removeDownloadInfoForFilename:legacyFile];
    
    GHAssertTrue(removed, @"removeDownloadInfoForFilename: shold return YES", nil);
    GHAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:legacyFile]], @"Legacy file was not deleted in the documents folder", nil);
    GHTestLog(@"Legacy file deleted with name: %@", legacyFile, nil);
}

- (NSString *) moveFileToTempFolder {
    
    NSString *source = [[NSBundle mainBundle] pathForResource:@"button_submitanswer" ofType:@"png"];
	NSString *destination = [NSTemporaryDirectory() stringByAppendingPathComponent:@"button_submitanswer.png"];
    
    [[NSFileManager defaultManager] createFileAtPath:destination 
                                                           contents:[NSData dataWithContentsOfFile:source] 
                                                         attributes:nil];
    return [destination lastPathComponent];
}

- (NSString *) moveFileToDocumentsFolder {
    
    NSString *source = [[NSBundle mainBundle] pathForResource:@"button_submitanswer" ofType:@"png"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDir = [paths objectAtIndex:0];
	NSString *destination = [docDir stringByAppendingPathComponent:@"button_submitanswer.png"];
    
    [[NSFileManager defaultManager] createFileAtPath:destination 
                                            contents:[NSData dataWithContentsOfFile:source] 
                                          attributes:nil];
    return [destination lastPathComponent];
}                     
                              
@end
