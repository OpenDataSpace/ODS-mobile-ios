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

@implementation FavoriteFileDownloadManager
NSString * const FavoriteMetadataFileName = @"FavoriteFilesMetadata.plist";

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

- (id)init
{
    if (self = [super init])
    {
        self.overwriteExistingDownloads = YES;
        self.metadataConfigFileName = FavoriteMetadataFileName;
    }
    return self;
}

// @override to calculate different key value
- (NSString *)setDownload:(NSDictionary *)downloadInfo forKey:(NSString *)key withFilePath:(NSString *)tempFile
{
    return [super setDownload:downloadInfo forKey:[self pathComponentToFile:key] withFilePath:tempFile];
}

- (void)removeDownloadInfoForAllFiles
{
    NSArray *favFiles = [[FileUtils listSyncedFiles] copy];
    
    for (int i = 0; i < [favFiles count]; i++)
    {
        [self removeDownloadInfoForFilename:[favFiles objectAtIndex:i]];
    }
    [favFiles release];
}

// @override
- (NSString *)pathComponentToFile:(NSString *)fileName
{
    return [kSyncedFilesDirectory stringByAppendingPathComponent:fileName];
}

- (NSString *)generatedNameForFile:(NSString *)fileName withObjectID:(NSString *)objectID
{
    NSString *newName = @"";
    
    NSString *fileExtension = [fileName pathExtension];
    
    if (fileExtension == nil || [fileExtension isEqualToString:@""])
    {
        newName = [objectID lastPathComponent];
    }
    else
    {
        newName = [NSMutableString stringWithFormat:@"%@.%@", [objectID lastPathComponent], fileExtension];
    }
    
    return newName;
}

@end
