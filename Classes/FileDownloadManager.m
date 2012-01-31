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
//  FileDownloadManager.m
//
// We store a binary plist to the Documents folder
// The top container is a NSDictionary that will hold the objectId as the key
// and the download metadata as the object.
// We will name the stored file as the objectId md5 hash so we could walk the documents folder
// and ask for a specific metadata information and handle gracefully the legacy downloads
// by returning nil for that specific file

#import "FileDownloadManager.h"
#import "NSString+MD5.h"
#import "FileUtils.h"
#import "Utility.h"

@interface FileDownloadManager (PrivateMethods)
- (NSMutableDictionary *) readMetadata;
- (BOOL) writeMetadata;
@end

@implementation FileDownloadManager
NSString * const MetadataFileName = @"DownloadMetadata";
NSString * const MetadataFileExtension = @"plist";

BOOL reload;
static NSMutableDictionary *downloadMetadata;
static FileDownloadManager *sharedInstance = nil;

- (void) dealloc {
	[super dealloc];
}

#pragma mark -
#pragma mark Singleton methods
+ (FileDownloadManager *)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
			sharedInstance = [[FileDownloadManager alloc] init];
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax;
}

- (oneway void)release
{
}

- (id)autorelease
{
	return self;
}

#pragma mark -
#pragma mark Public methods
- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) tempFile {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(!tempFile || ![fileManager fileExistsAtPath:[FileUtils pathToTempFile:tempFile]]) {
        return nil;
    }
    
    NSString *md5Id;
    
    if(kUseHash) {
        md5Id = [key MD5];
    } else {
        md5Id = key;
    }
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:md5Id];
    
    if(![FileUtils saveTempFile:tempFile withName:md5Id]) {
        NSLog(@"Cannot move tempFile: %@ to the dowloadFolder, newName: %@", tempFile, md5Id);
        return nil;
    }
    
    // Saving a legacy file or a document sent through document interaction
    if(downloadInfo) {
        [[self readMetadata] setObject:downloadInfo forKey:md5Id];
    
        if(![self writeMetadata]) {
            [FileUtils unsave:md5Id];
            [[self readMetadata] setObject:previousInfo forKey:md5Id];
            NSLog(@"Cannot save the metadata plist");
            return nil;
        }
        else
        {
            NSURL *fileURL = [NSURL fileURLWithPath:[FileUtils pathToSavedFile:md5Id]];
            addSkipBackupAttributeToItemAtURL(fileURL);
        }
    }
    return md5Id;
}

- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key {
    NSString *md5Id;
    
    if(kUseHash) {
        md5Id = [key MD5];
    } else {
        md5Id = key;
    }
    [[self readMetadata] setObject:downloadInfo forKey:md5Id];
    
    if(![self writeMetadata]) {
        NSLog(@"Cannot save the metadata plist");
        return nil;
    }
    
    return md5Id;
}

- (NSDictionary *) downloadInfoForKey:(NSString *) key {
    if(kUseHash) {
        key = [key MD5];
    } 
    return [self downloadInfoForFilename:key];
}

- (NSDictionary *) downloadInfoForFilename:(NSString *) filename {
    return [[self readMetadata] objectForKey:filename];
}

- (BOOL) removeDownloadInfoForFilename:(NSString *) filename {
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:filename];
    
    if(previousInfo) {
        [[self readMetadata] removeObjectForKey:filename];
        
        if(![self writeMetadata]) {
            NSLog(@"Cannot delete the metadata in the plist");
            return NO;
        }
    }
    
    if(![FileUtils unsave:filename]) {
        if(previousInfo) {
            [[self readMetadata] setObject:previousInfo forKey:filename];
            // We assume this will not fail since we already wrote it
            [self writeMetadata];
        }
        
        NSLog(@"Cannot delete the file: %@", filename);
        return NO;
    }

    return YES;
}

- (void) reloadInfo {
    reload = YES;
}

- (void) deleteDownloadInfo {
    NSString *path = [self metadataPath];
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

- (BOOL) downloadExistsForKey: (NSString *) key {
    return [[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:key]];
}

#pragma mark -
#pragma mark PrivateMethods
- (NSMutableDictionary *) readMetadata {
    if(downloadMetadata && !reload) {
        return downloadMetadata;
    }
    
    reload = NO;
    NSString *path = [self metadataPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // We create an empty NSMutableDictionary if the file doesn't exists otherwise
    // we create it from the file
    if ([fileManager fileExistsAtPath: path])
    {
        //downloadMetadata = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
        NSPropertyListFormat format;  
        NSString *error;  
        NSData *plistData = [NSData dataWithContentsOfFile:path];   
        
        //We assume the stored data must be a dictionary
        [downloadMetadata release];
        downloadMetadata = [[NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListMutableContainers format:&format errorDescription:&error] retain]; 
        
        if (!downloadMetadata) {  
            NSLog(@"Error reading plist from file '%s', error = '%s'", [path UTF8String], [error UTF8String]);  
            [error release];
        } 
    } else {
        downloadMetadata = [[NSMutableDictionary alloc] init];
    }
    
    return downloadMetadata;
}

- (BOOL) writeMetadata {
    NSString *path = [self metadataPath];
    //[downloadMetadata writeToFile:path atomically:YES];
    NSData *binaryData;  
    NSString *error;
     
    NSDictionary *downloadPlist = [self readMetadata];
    binaryData = [NSPropertyListSerialization dataFromPropertyList:downloadPlist format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];  
    if (binaryData) {  
        [binaryData writeToFile:path atomically:YES];  
    } else {  
        NSLog(@"Error writing plist to file '%s', error = '%s'", [path UTF8String], [error UTF8String]);  
        [error release];
        return NO;
    }  
    return YES;
}

- (NSString *)oldMetadataPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *configPath = [documentsDirectory stringByAppendingPathComponent:@"config"];
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:configPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }
    
    return [configPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", MetadataFileName, MetadataFileExtension]];
}

- (NSString *)metadataPath {
    NSString *filename = [NSString stringWithFormat:@"%@.%@", MetadataFileName, MetadataFileExtension];
    return [FileUtils pathToConfigFile:filename];
}

@end
