//
//  FavoriteFileDownloadManager.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 03/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>

#define kUseHash NO

@interface FavoriteFileDownloadManager : NSObject

+ (FavoriteFileDownloadManager *) sharedInstance;
+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;

- (NSDictionary *) downloadInfoForKey:(NSString *) key;
- (NSDictionary *) downloadInfoForFilename:(NSString *) filename;
// Set Download will persist the metadataInfo and also save the file document
// Will revert everything back if something went wrong
// returns the saved file name if everything was successful, nil if something went wrong
- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key withFilePath: (NSString *) tempFile;
- (NSString *) setDownload: (NSDictionary *) downloadInfo forKey:(NSString *) key;

-(void) updateDownloadInfo:(NSDictionary *) downloadInfo ForFilename:(NSString *) filename;

-(void) deleteUnFavoritedItems:(NSArray*)favorites excludingItemsFromAccounts:(NSArray*) failedAccounts;

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
@end

