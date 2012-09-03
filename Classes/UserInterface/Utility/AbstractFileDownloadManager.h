//
//  AbstractFileDownloadManager.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 30/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
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
