//
//  FavoriteFileUtils.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 03/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FavoriteFileUtils : NSObject

+ (BOOL) isSaved: (NSString *) filename;
+ (BOOL) save: (NSString *) filename;
+ (BOOL) saveTempFile:(NSString *)filename withName: (NSString *) newName;
+ (BOOL) unsave: (NSString *) filename;
+ (NSArray *) list;
+ (NSString *) pathToTempFile: (NSString *) filename;
+ (NSString *) pathToSavedFile: (NSString *) filename;
+ (NSString *) pathToConfigFile:(NSString *)filename;
+ (NSString *) sizeOfSavedFile: (NSString *) filename;

+ (NSDate *) lastDownloadedDateForFile:(NSString *) filename;

+ (NSString *)stringForLongFileSize:(long)size;
+ (NSString *)stringForUnsignedLongLongFileSize:(unsigned long long)size;

+ (void)enumerateSavedFilesUsingBlock: ( void ( ^ )( NSString * ) )filesBlock;

/*
 Returns the next valid filename to avoid name crashing in a folder/repository node
 by adding a -{num} where {num} is the next available number that avoids a name conflict in the
 folder/repository node
 */
+ (NSString *)nextFilename:(NSString *)filename inNodeWithDocumentNames:(NSArray *)documentNames;

@end

