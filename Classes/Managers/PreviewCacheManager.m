//
//  PreviewCacheManager.m
//  FreshDocs
//
//  Created by bdt on 3/5/14.
//
//

#import "PreviewCacheManager.h"
#import "RepositoryItem.h"
#import "DownloadInfo.h"
#import "FileUtils.h"
#import "FileProtectionManager.h"

NSString * const PreviewMetadataFileName = @"PreviewFilesMetadata.plist";

@interface PreviewCacheManager()
@property (nonatomic, strong) NSMutableDictionary *previewFilesMetadata;
@end

@implementation PreviewCacheManager
@synthesize previewFilesMetadata = _previewFilesMetadata;

#pragma mark - Shared Instance

+ (PreviewCacheManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (id) init {
    if (self = [super init]) {
        _previewFilesMetadata = [self readPreviewFileMetadata];
    }
    
    return self;
}

//check the file is exists
- (BOOL) previewFileExists:(RepositoryItem*) item {
    NSDictionary *fileInfo = [self readPreviewFileMetadata];
    if (fileInfo && [fileInfo objectForKey:item.guid]) {
        return YES;
    }
    
    return NO;
}

//get cached file path
- (NSDictionary*) downloadInfoFromCache:(RepositoryItem*) item {
    NSDictionary *fileInfo = [self readPreviewFileMetadata];
    
    return [fileInfo objectForKey:item.guid];
}

//cache new file
- (BOOL) cachePreviewFile:(DownloadInfo*) info {
    NSError *error = nil;
    NSString *tempFile = info.tempFilePath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!tempFile || ![fileManager fileExistsAtPath:[FileUtils pathToTempFile:tempFile]])
    {
        return NO;
    }
    
    NSString *destination = [self generateCachePath:info.repositoryItem];
    if ([fileManager fileExistsAtPath:destination])
    {
        [fileManager removeItemAtPath:destination error:&error];
    }
    
    BOOL success = [fileManager copyItemAtPath:info.tempFilePath toPath:destination error:&error];
    
    if (!success)
    {
        AlfrescoLogError(@"Failed to create file %@, with error: %@", destination, [error description]);
        return NO;
    }
    else
    {
        success = [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:destination];
        if (!success)
        {
            AlfrescoLogError(@"Failed to protect file %@, with error: %@", destination, [error description]);
            return NO;
        }
    }

    RepositoryItem *item = [info repositoryItem];
    NSString *fileID = [item guid];
    
    //we only store file name.
    NSMutableDictionary *tempDownloadInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[destination lastPathComponent], @"path", info.repositoryItem.title, @"title", nil];
    [[self readPreviewFileMetadata] setObject:tempDownloadInfo forKey:fileID];
    
    if (![self writeMetadata])
    {
        AlfrescoLogDebug(@"Cannot save the metadata plist");
        return NO;
    }
    
    return YES;
}

//clear all cache
- (void) removeAllCacheFiles {
    NSError *error = nil;
    NSMutableDictionary *previewFileMetadataList = [self readPreviewFileMetadata];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[FileUtils pathToCacheFile:@""] error:&error];
    [previewFileMetadataList removeAllObjects];
    
    [self writeMetadata];
}

//Cache size
- (NSString*) previewCahceSize {
    NSString *folderPath = [FileUtils pathToCacheFile:@""];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
    
    //Formatted size from bytes ....
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    return folderSizeStr;
}

//generate cache file path
- (NSString*) generateCachePath:(RepositoryItem*) item {
    NSString *newName = @"";
    
    NSString *fileExtension = [item.title pathExtension];
    if (fileExtension == nil || [fileExtension isEqualToString:@""])
    {
        newName = [item guid];
    }
    else
    {
        newName = [NSMutableString stringWithFormat:@"%@.%@", [item guid], fileExtension];
    }
    
    return [FileUtils pathToCacheFile: newName];
}

#pragma mark -
#pragma mark PrivateMethods

- (NSString*) previewMetadataPath {
    return [FileUtils pathToConfigFile:PreviewMetadataFileName];
}

- (NSMutableDictionary *)readPreviewFileMetadata {
    if (_previewFilesMetadata)
    {
        return _previewFilesMetadata;
    }
    
    NSString *path = [self previewMetadataPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // We create an empty NSMutableDictionary if the file doesn't exists otherwise
    // we create it from the file
    if ([fileManager fileExistsAtPath:path])
    {
        NSError *error = nil;
        NSData *plistData = [NSData dataWithContentsOfFile:path];
        
        //We assume the stored data must be a dictionary
        
        _previewFilesMetadata = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainers format:NULL error:&error];
        
        if (!_previewFilesMetadata)
        {
            AlfrescoLogDebug(@"Error reading plist from file '%@', error = '%@'", path, error.localizedDescription);
        }
    }
    else
    {
        _previewFilesMetadata = [[NSMutableDictionary alloc] init];
    }
    
    return _previewFilesMetadata;
}

- (BOOL)writeMetadata
{
    NSString *path = [self previewMetadataPath];
    NSError *error = nil;
    NSDictionary *previewPlist = [self readPreviewFileMetadata];
    NSData *binaryData = [NSPropertyListSerialization dataWithPropertyList:previewPlist format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (binaryData)
    {
        [binaryData writeToFile:path atomically:YES];
        //Complete protection in metadata since the file is always read one time and we write it when the application is active
        [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:path];
    }
    else
    {
        AlfrescoLogDebug(@"Error writing plist to file '%@', error = '%@'", path, error.localizedDescription);
        return NO;
    }
    return YES;
}

@end
