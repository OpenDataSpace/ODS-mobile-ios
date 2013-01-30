//
//  AlfrescoMDMLite.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 18/12/2012.
//
//

#import "AlfrescoMDMLite.h"
#import "FileDownloadManager.h"
#import "FavoriteFileDownloadManager.h"

@implementation AlfrescoMDMLite


- (BOOL)isRestrictedDownload:(NSString*)fileName
{
    return [[FileDownloadManager sharedInstance] isFileRestricted:fileName];
}

- (BOOL)isRestrictedSync:(NSString*) fileName
{
    return [[FavoriteFileDownloadManager sharedInstance] isFileRestricted:fileName];
}

- (BOOL)isDownloadExpired:(NSString*)fileName
{
    return [[FileDownloadManager sharedInstance] isFileExpired:fileName];
}

- (BOOL)isSyncExpired:(NSString*)fileName
{
    return [[FavoriteFileDownloadManager sharedInstance] isFileExpired:fileName];
}


#pragma mark - Singleton methods

+ (AlfrescoMDMLite *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end
