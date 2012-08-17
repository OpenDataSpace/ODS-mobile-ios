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
//  FavoriteFileDownloadManager.m
//

#import "FavoriteFileDownloadManager.h"
#import "NSString+MD5.h"
#import "FavoriteFileUtils.h"
#import "Utility.h"
#import "FileProtectionManager.h"
#import "RepositoryItem.h"
//#import "FavoriteTableCellWrapper.h"

@interface FavoriteFileDownloadManager (PrivateMethods)
- (NSMutableDictionary *) readMetadata;
- (BOOL) writeMetadata;
@end


@implementation FavoriteFileDownloadManager
NSString * const FavoriteMetadataFileName = @"FavoriteFilesMetadata";
NSString * const FavoriteMetadataFileExtension = @"plist";

BOOL reload;
static NSMutableDictionary *downloadMetadata;

#pragma mark - Singleton methods

+ (FavoriteFileDownloadManager *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

#pragma mark - Public methods
- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) tempFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(!tempFile || ![fileManager fileExistsAtPath:[FavoriteFileUtils pathToTempFile:tempFile]])
    {
        return nil;
    }
    
    NSString *md5Id;
    
    if(kUseHash)
    {
        md5Id = [key MD5];
    }
    else
    {
        md5Id = key;
    }
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:md5Id];
    
    if(![FavoriteFileUtils saveTempFile:tempFile withName:md5Id])
    {
        NSLog(@"Cannot move tempFile: %@ to the dowloadFolder, newName: %@", tempFile, md5Id);
        return nil;
    }
    
    // Saving a legacy file or a document sent through document interaction
    if(downloadInfo) 
    {
        NSMutableDictionary *tempDownloadInfo = [[downloadInfo mutableCopy] autorelease];
        [tempDownloadInfo setObject:[NSDate date] forKey:@"lastDownloadedDate"];
        [[self readMetadata] setObject:tempDownloadInfo forKey:md5Id];
        
        if(![self writeMetadata])
        {
            [FavoriteFileUtils unsave:md5Id];
            [[self readMetadata] setObject:previousInfo forKey:md5Id];
            NSLog(@"Cannot save the metadata plist");
            return nil;
        }
        else
        {
            NSURL *fileURL = [NSURL fileURLWithPath:[FavoriteFileUtils pathToSavedFile:md5Id]];
            addSkipBackupAttributeToItemAtURL(fileURL);
        }
    }
    return md5Id;
}

-(BOOL) string:(NSString*)string existsIn:(NSArray*)array
{
    for(id item in array)
    {
        if ([item isEqualToString:string])
        {
            return YES;
        }
    }
    
    return NO;
}

-(void) deleteUnFavoritedItems:(NSArray*)favorites excludingItemsFromAccounts:(NSArray*) failedAccounts
{   
    NSDictionary * favoritesMetaData = [self readMetadata];
    NSMutableArray *favoritesKeys = [[NSMutableArray alloc] init];
    NSArray *temp = [favoritesMetaData allKeys];
    
    for (int  i =0; i < [temp count]; i++)
    {
        NSString * accountUDIDForDoc = [[favoritesMetaData objectForKey:[temp objectAtIndex:i]] objectForKey:@"accountUUID"];
        
        if([self string:accountUDIDForDoc existsIn:failedAccounts] == NO)
        {
            [favoritesKeys addObject:[temp objectAtIndex:i]];
        }
        
    }
    
    NSMutableArray *itemsToBeDeleted = [favoritesKeys mutableCopy];
    
    for(NSString * item in favoritesKeys)
    {
        for (RepositoryItem *repos in favorites)
        {
            if ([repos.title isEqualToString:item]) 
            {
                [itemsToBeDeleted removeObject:item];
                
            }
        }
    }
    
    for (NSString *item in itemsToBeDeleted)
    {
        NSLog(@"Removing Item: %@", item);
        [self removeDownloadInfoForFilename:item];
    }
    
    [itemsToBeDeleted release];
    
    [favoritesKeys release];
}

- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key
{
    NSString *md5Id;
    
    if(kUseHash)
    {
        md5Id = [key MD5];
    }
    else
    {
        md5Id = key;
    }
    [[self readMetadata] setObject:downloadInfo forKey:md5Id];
    
    if(![self writeMetadata])
    {
        NSLog(@"Cannot save the metadata plist");
        return nil;
    }
    
    return md5Id;
}

- (NSDictionary *) downloadInfoForKey:(NSString *) key
{
    if(kUseHash)
    {
        key = [key MD5];
    } 
    return [self downloadInfoForFilename:key];
}

- (NSDictionary *) downloadInfoForFilename:(NSString *) filename
{
    return [[self readMetadata] objectForKey:filename];
}

- (BOOL) removeDownloadInfoForFilename:(NSString *) filename
{
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:filename];
    
    if(previousInfo)
    {
        [[self readMetadata] removeObjectForKey:filename];
        
        if(![self writeMetadata])
        {
            NSLog(@"Cannot delete the metadata in the plist");
            return NO;
        }
    }
    
    if(![FavoriteFileUtils unsave:filename])
    {
        if(previousInfo)
        {
            [[self readMetadata] setObject:previousInfo forKey:filename];
            // We assume this will not fail since we already wrote it
            [self writeMetadata];
        }
        
        NSLog(@"Cannot delete the file: %@", filename);
        return NO;
    }
    
    return YES;
}

- (void) removeDownloadInfoForAllFiles
{
    NSArray *favFiles = [[FavoriteFileUtils list] copy];
    
    for(int i =0; i < [favFiles count]; i++)
    {
        [self removeDownloadInfoForFilename:[favFiles objectAtIndex:i]];
    }
    [favFiles release];
}

- (void) reloadInfo
{
    reload = YES;
}

- (void) deleteDownloadInfo
{
    NSString *path = [self metadataPath];
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

- (BOOL) downloadExistsForKey: (NSString *) key
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[FavoriteFileUtils pathToSavedFile:key]];
}

#pragma mark - PrivateMethods

- (NSMutableDictionary *) readMetadata
{
    if(downloadMetadata && !reload)
    {
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
        
        if (!downloadMetadata)
        {
            NSLog(@"Error reading plist from file '%s', error = '%s'", [path UTF8String], [error UTF8String]);  
            [error release];
        } 
    }
    else
    {
        downloadMetadata = [[NSMutableDictionary alloc] init];
    }
    
    return downloadMetadata;
}

- (BOOL) writeMetadata
{
    NSString *path = [self metadataPath];
    //[downloadMetadata writeToFile:path atomically:YES];
    NSData *binaryData;  
    NSString *error;
    
    NSDictionary *downloadPlist = [self readMetadata];
    binaryData = [NSPropertyListSerialization dataFromPropertyList:downloadPlist format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];  
    if (binaryData)
    {
        [binaryData writeToFile:path atomically:YES];
        //Complete protection in metadata since the file is always read one time and we write it when the application is active
        [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:path];
    }
    else
    {
        NSLog(@"Error writing plist to file '%s', error = '%s'", [path UTF8String], [error UTF8String]);  
        [error release];
        return NO;
    }  
    return YES;
}

- (NSString *)oldMetadataPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *configPath = [documentsDirectory stringByAppendingPathComponent:@"config"];
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:configPath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:configPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }
    
    return [configPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", FavoriteMetadataFileName, FavoriteMetadataFileExtension]];
}

- (NSString *)metadataPath
{
    NSString *filename = [NSString stringWithFormat:@"%@.%@", FavoriteMetadataFileName, FavoriteMetadataFileExtension];
    return [FavoriteFileUtils pathToConfigFile:filename];
}

@end

