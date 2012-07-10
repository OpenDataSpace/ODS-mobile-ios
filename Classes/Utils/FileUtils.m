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
//  FileUtils.m
//

#import "FileUtils.h"
#import "FileProtectionManager.h"
#import "NSArray+Utils.h"

@implementation FileUtils

+ (BOOL)isSaved:(NSString *)filename {
	return [[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:filename]];
}

+ (BOOL)save:(NSString *)filename {
    return [FileUtils saveTempFile:filename withName:filename];
}

+ (BOOL)saveTempFile:(NSString *)filename withName: (NSString *) newName  {
    
	// the source is in the temp dir
	NSString *source = [FileUtils pathToTempFile:filename];
	
	// the destination is in the documents dir
	NSString *destination = [FileUtils pathToSavedFile:newName];
    NSError *error = nil;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:destination])
    {
        [[NSFileManager defaultManager] removeItemAtPath:destination error:&error];
    }
    
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:&error];
    
    if (! success) {
        NSLog(@"Failed to create file %@, with error: %@", destination, [error description]);
    } else {
        success = [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:destination];
    }
    
    if (! success) {
        NSLog(@"Failed to protect file %@, with error: %@", destination, [error description]);
    }
    return success;
}

// aka "delete" :)
+ (BOOL) unsave: (NSString *) filename {
	
	NSError *error = nil;
	
	[[NSFileManager defaultManager] removeItemAtPath:[FileUtils pathToSavedFile:filename] error:&error];
    
    if(error) {
        NSLog(@"Error: %@ deleting file: %@", [error description], filename);
        return NO;
    }
    
    return YES;
}

+ (NSArray *) list {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDir = [paths objectAtIndex:0];
	
	NSError *error = nil;
	
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:docDir error:&error];
	return files;
}

+ (NSString *) pathToSavedFile: (NSString *) filename {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDir = [paths objectAtIndex:0];
	NSString *path = [docDir stringByAppendingPathComponent:filename];
	NSLog(@"path: %@", path);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory; 
	// [paths release];
    if(![fileManager fileExistsAtPath:docDir isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:docDir withIntermediateDirectories:YES attributes:nil error:&error];
        
        if(error) {
            NSLog(@"Error creating the %@ folder: %@", @"Documents", [error description]);
            return  nil;
        }
    }
    
	return path;
}

+ (NSString *) pathToTempFile: (NSString *) filename {
	return [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
}

+ (NSString *)pathToConfigFile:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *configDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:kFDLibraryConfigFolderName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory; 
    
    if(![fileManager fileExistsAtPath:configDir isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:configDir withIntermediateDirectories:NO attributes:nil error:&error];
        
        if(error) {
            NSLog(@"Error creating the %@ folder: %@", kFDLibraryConfigFolderName, [error description]);
            return  nil;
        }
    }
    
    NSString *path = [configDir stringByAppendingPathComponent:filename];
    NSLog(@"path: %@", path);
    return path;
}

+ (NSString *) sizeOfSavedFile: (NSString *) filename {
	NSError *error = nil;

	NSString *path = [FileUtils pathToSavedFile:filename];
	NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];

	NSArray *keys = [attrs allKeys];
	for (NSString *key in keys)
		NSLog(@"  %@ = %@", key, [attrs objectForKey:key]);
	
	NSNumber *sizeInBytes = [attrs objectForKey:NSFileSize];
    
	return [FileUtils stringForLongFileSize:[sizeInBytes longValue]];
}



+ (NSString *)stringForLongFileSize:(long)size
{
	float floatSize = size;
	if (size < 1023)
		return([NSString stringWithFormat:@"%ld %@", size, NSLocalizedString(@"bytes", @"file bytes, used as follows: '100 bytes'")]);
    
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"kb", @"Abbreviation for Kilobytes, used as follows: '17KB'")]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"mb", @"Abbreviation for Megabytes, used as follows: '2MB'")]);
	floatSize = floatSize / 1024;
	
	// Add as many as you like
	
	return([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"GB", @"Abbrevation for Gigabyte, used as follows: '1GB'")]);
}

+ (NSString *)stringForUnsignedLongLongFileSize:(unsigned long long)size
{
	NSString *formattedStr = nil;
    if (size == 0) 
		formattedStr = @"Empty";
	else 
		if (size > 0 && size < 1024) 
			formattedStr = [NSString stringWithFormat:@"%qu %@", size, NSLocalizedString(@"bytes", @"file bytes, used as follows: '100 Bytes'")];
        else 
            if (size >= 1024 && size < pow(1024, 2)) 
                formattedStr = [NSString stringWithFormat:@"%.1f %@", (size / 1024.), NSLocalizedString(@"kb", @"Abbreviation for Kilobytes, used as follows: '17 KB'")];
            else 
                if (size >= pow(1024, 2) && size < pow(1024, 3))
                    formattedStr = [NSString stringWithFormat:@"%.2f %@", (size / pow(1024, 2)), NSLocalizedString(@"mb", @"Abbreviation for Megabytes, used as follows: '2 MB'")];
                else 
                    if (size >= pow(1024, 3)) 
                        formattedStr = [NSString stringWithFormat:@"%.3f %@", (size / pow(1024, 3)), NSLocalizedString(@"gb", @"Abbrevation for Gigabyte, used as follows: '1 GB'")];
	
	return formattedStr;
}

+ (NSArray *)allSavedFilePaths
{
    NSMutableArray *savedFiles = [NSMutableArray array];
    NSString *folderPath = [self pathToSavedFile:@""];
    NSArray *folderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: folderPath
                                                                                  error:NULL];
    
    for (NSString *fileName in [folderContents objectEnumerator])
    {
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        // only add files, no directories nor the Inbox
        if (!isDirectory && ![fileName isEqualToString: @"Inbox"]) {
            [savedFiles addObject:filePath];
        }
    }
    
    return [NSArray arrayWithArray:savedFiles];
}

+ (void)enumerateSavedFilesUsingBlock: ( void ( ^ )( NSString * ) )filesBlock
{
    for(NSString *path in [self allSavedFilePaths])
    {
        filesBlock(path);
    }
}

+ (NSString *)nextFilename:(NSString *)filename inNodeWithDocumentNames:(NSArray *)documentNames
{
    int ct = 0;
    NSString *extension = [filename pathExtension];
    
    NSString *originalName = [filename stringByDeletingPathExtension];
    NSString *newName = [originalName copy];
  
    if (extension == nil || [extension isEqualToString:@""])
    {
        while ([documentNames containsString:newName caseInsensitive:YES]) {
            _GTMDevLog(@"File with name %@ exists, incrementing and trying again", newName);
            
            [newName release];
            newName = [[NSString alloc] initWithFormat:@"%@-%d", originalName, ++ct];
        }
    }
    else 
    {
        while ([documentNames containsString:[newName stringByAppendingPathExtension:extension] caseInsensitive:YES]) {
            _GTMDevLog(@"File with name %@ exists, incrementing and trying again", newName);
            
            [newName release];
            newName = [[NSString alloc] initWithFormat:@"%@-%d", originalName, ++ct];
        }
    }
    
    NSString *finalFilename = [newName stringByAppendingPathExtension:extension];
    
    if (extension == nil || [extension isEqualToString:@""]) {
        
        finalFilename = [finalFilename stringByDeletingPathExtension];
    }
    
    [newName release];
    return finalFilename;
}

@end
