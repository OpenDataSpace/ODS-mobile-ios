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
//  AbstractFileDownloadManager.m
//

#import "AbstractFileDownloadManager.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "DownloadInfo.h"
#import "DownloadMetadata.h"
#import "AccountInfo.h"
#import "AccountManager.h"

@implementation AbstractFileDownloadManager
@synthesize overwriteExistingDownloads = _overwriteExistingDownloads;

#pragma mark - Public methods

- (NSString *)setDownload:(NSDictionary *)downloadInfo forKey:(NSString *)key withFilePath:(NSString *)tempFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!tempFile || ![fileManager fileExistsAtPath:[FileUtils pathToTempFile:tempFile]])
    {
        return nil;
    }
    
    NSString *fileID = [key lastPathComponent];
    NSString *md5Id = kUseHash ? fileID.MD5 : fileID;
    NSString *md5Path = key;
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:md5Id];
    
    if (![FileUtils saveTempFile:tempFile withName:md5Path overwriteExisting:self.overwriteExistingDownloads])
    {
        NSLog(@"Cannot move tempFile: %@ to the downloadFolder, newName: %@", tempFile, md5Path);
        return nil;
    }
    
    // Saving a legacy file or a document sent through document interaction
    if (downloadInfo)
    {
        NSMutableDictionary *tempDownloadInfo = [[downloadInfo mutableCopy] autorelease];
        [tempDownloadInfo setObject:[NSDate date] forKey:@"lastDownloadedDate"];
        [[self readMetadata] setObject:tempDownloadInfo forKey:md5Id];
        if (![self writeMetadata])
        {
            [FileUtils unsave:md5Path];
            [[self readMetadata] setObject:previousInfo forKey:md5Id];
            NSLog(@"Cannot save the metadata plist");
            return nil;
        }
        else
        {
            NSURL *fileURL = [NSURL fileURLWithPath:[FileUtils pathToSavedFile:md5Path]];
            addSkipBackupAttributeToItemAtURL(fileURL);
        }
    }
    return md5Path;
}

- (void)updateMetadata:(RepositoryItem *)repositoryItem forFilename:(NSString *)filename accountUUID:(NSString *)accountUUID tenantID:(NSString *)tenantID
{
    NSString *fileID = [filename lastPathComponent];
    DownloadInfo *downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:repositoryItem] autorelease];
    downloadInfo.selectedAccountUUID = accountUUID;
    downloadInfo.tenantID = tenantID;

    NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithDictionary:downloadInfo.downloadMetadata.downloadInfo];
    NSString *newPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:filename];
    
    // Set downloaded date to now
    [fileInfo setObject:[NSDate date] forKey:@"lastDownloadedDate"];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[fileInfo objectForKey:@"objectId"], @"objectId",
                              repositoryItem, @"repositoryItem",
                              newPath, @"newPath", nil];
    [[NSNotificationCenter defaultCenter] postDocumentUpdatedNotificationWithUserInfo:userInfo];
    
    [[self readMetadata] setObject:fileInfo forKey:fileID];
    [self writeMetadata];
}

- (void)updateMDMInfo:(NSString*)expiresAfter forFileName:(NSString*)fileName
{
    NSString *fileID = [fileName lastPathComponent];
    
    [[[[self readMetadata] objectForKey:fileID] objectForKey:@"aspects"] setValue:@"P:mdm:restrictedAspect" forKey:@"P:mdm:restrictedAspect"];
    [[[[self readMetadata] objectForKey:fileID] objectForKey:@"metadata"] setValue:expiresAfter forKey:@"mdm:offlineExpiresAfter"];
    
    [self writeMetadata];
}

- (NSString *)setDownload:(NSDictionary *)downloadInfo forKey:(NSString *)key
{
    NSString *fileID = [key lastPathComponent];
    NSString *md5Id = kUseHash ? fileID.MD5 : fileID;
    
    [[self readMetadata] setObject:downloadInfo forKey:md5Id];
    
    if (![self writeMetadata])
    {
        NSLog(@"Cannot save the metadata plist");
        return nil;
    }
    
    return md5Id;
}

- (NSDictionary *)downloadInfoForKey:(NSString *)key
{
    NSString *fileID = [key lastPathComponent];
    if (kUseHash)
    {
        fileID = [fileID MD5];
    } 
    return [self downloadInfoForFilename:fileID];
}

- (NSDictionary *)downloadInfoForDocumentWithID:(NSString *)objectID
{
    NSString * objID = [objectID lastPathComponent];
    
    [self readMetadata];
    
    for (NSString *key in downloadMetadata)
    {
        if ([key hasPrefix:objID])
        {
            return [downloadMetadata objectForKey:key];
        }
    }
    return nil;
}

- (NSDictionary *)downloadInfoForFilename:(NSString *)filename
{
    NSString * fileID = [filename lastPathComponent];
    return [[self readMetadata] objectForKey:fileID];
}

- (BOOL)removeDownloadInfoForFilename:(NSString *)filename
{
    NSString *fileID = [filename lastPathComponent];
    NSDictionary *previousInfo = [[self readMetadata] objectForKey:fileID];
    
    if ([FileUtils moveFileToTemporaryFolder:[FileUtils pathToSavedFile:filename]])
    {
        // If we can get an objectId, then notify interested parties that the file has moved
        NSString *objectId = [previousInfo objectForKey:@"objectId"];
        if (objectId)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:objectId, @"objectId",
                                      [FileUtils pathToTempFile:filename], @"newPath", nil];
            [[NSNotificationCenter defaultCenter] postDocumentUpdatedNotificationWithUserInfo:userInfo];
        }

        if (previousInfo)
        {
            [[self readMetadata] removeObjectForKey:fileID];
            
            if (![self writeMetadata])
            {
                NSLog(@"Cannot delete the metadata in the plist");
                return NO;
            }
        }
        
        return YES;
    }

    return NO;
}

- (void)removeDownloadInfoForAllFiles
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)reloadInfo
{
    reload = YES;
}

- (void)deleteDownloadInfo
{
    NSString *path = [self metadataPath];
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

- (BOOL)downloadExistsForKey:(NSString *)key
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:key]];
}

- (void) removeExpiredFiles
{
    [self readMetadata];
    
    NSDictionary * temp = [downloadMetadata mutableCopy];
    for(id t in temp)
    {
        /*
        AccountManager *accountManager = [AccountManager sharedManager];
        AccountInfo *info = [accountManager accountInfoForUUID:[[downloadMetadata objectForKey:t] objectForKey:@"accountUUID"]];
        NSUInteger num = [info.accountStatusInfo successTimestamp];
        NSDate *da = [NSDate dateWithTimeIntervalSince1970:num];
        NSLog(@"Last Active account --- %f", [[NSDate date] timeIntervalSinceDate:da]);
         */
        NSDictionary * metaData = [downloadMetadata objectForKey:t];
        NSDate *d = [metaData objectForKey:@"lastDownloadedDate"];
        
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:d]; 
        NSUInteger expiresAfter = [([[metaData objectForKey:@"metadata"] objectForKey:@"mdm:offlineExpiresAfter"]) intValue] * 60 * 60;
        
        if(interval > expiresAfter)
        {
            NSLog(@"Delete Fiel: %@===============", t);
            [self removeDownloadInfoForFilename:t];
        }
    }
    [temp release];
}

- (BOOL)isFileRestricted:(NSString*)fileName
{
    NSDictionary * downloadInfo = [self downloadInfoForFilename:fileName];
    
    NSString * restrictionAspect = [[downloadInfo objectForKey:@"aspects"] objectForKey:@"P:mdm:restrictedAspect"];
    
    return restrictionAspect != nil;
}

- (BOOL)isFileExpired:(NSString*)fileName
{
    NSDictionary * downloadInfo = [self downloadInfoForFilename:fileName];
    
    AccountManager *accountManager = [AccountManager sharedManager];
    AccountInfo *info = [accountManager accountInfoForUUID:[downloadInfo objectForKey:@"accountUUID"]];
    NSDate *lastSuccesssfullLogin = [NSDate dateWithTimeIntervalSince1970:[info.accountStatusInfo successTimestamp]];
    NSLog(@"Last Active account --- %@", lastSuccesssfullLogin);
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:lastSuccesssfullLogin];
    
    NSUInteger expiresAfter = [([[downloadInfo objectForKey:@"metadata"] objectForKey:@"mdm:offlineExpiresAfter"]) intValue] * 60;
    
    
    NSLog(@"****** interval: %f ****** expiresAfter: %d", interval, expiresAfter);
    if(interval > expiresAfter)
    {
        return YES;
    }
    return NO;
}

#pragma mark - PrivateMethods

- (NSMutableDictionary *)readMetadata
{
    if (downloadMetadata && !reload)
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

- (BOOL)writeMetadata
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
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)metadataPath
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)pathComponentToFile:(NSString *)fileName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)pathToFileDirectory:(NSString*)fileName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
