//
//  PreviewCacheManager.h
//  FreshDocs
//
//  Created by bdt on 3/5/14.
//
//

#import <Foundation/Foundation.h>

@class DownloadInfo;
@class RepositoryItem;

@interface PreviewCacheManager : NSObject

+ (PreviewCacheManager *)sharedManager;

//check the file is exists
- (BOOL) previewFileExists:(RepositoryItem*) item;

//get cached file path
- (NSDictionary*) downloadInfoFromCache:(RepositoryItem*) item;

//cache new file
- (BOOL) cachePreviewFile:(DownloadInfo*) info;

//clear all cache
- (void) removeAllCacheFiles;

//Cache size
- (NSString*) previewCahceSize;

//generate cache file path
- (NSString*) generateCachePath:(RepositoryItem*)item;
@end
