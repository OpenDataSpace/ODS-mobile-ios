//
//  FavoritesUploadManager.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 21/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "FavoritesUploadManager.h"

NSString * const kFavoritesUploadConfigurationFile = @"FavoriteUploadsMetadata.plist";

@implementation FavoritesUploadManager

- (void)dealloc
{
    [super dealloc];
}

- (id)init
{
    self = [super initWithConfigFile:kFavoritesUploadConfigurationFile andUploadQueue:@"FavoritesUploadQueue"];
    if(self)
    {
        
    }
    return self;
}

-(void) queueUpdateUpload:(UploadInfo *)uploadInfo
{
    dispatch_async(self.addUploadQueue, ^{
        
        [super queueUpdateUpload:uploadInfo];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
        [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:userInfo];
        
        
    });
}

- (void)queueUploadArray:(NSArray *)uploads
{
    dispatch_async(self.addUploadQueue, ^{
        
        [super queueUploadArray:uploads];
        
        [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
        
    });  
}

- (void)clearUpload:(NSString *)uploadUUID
{
    [super clearUpload:uploadUUID];
    
    UploadInfo *uploadInfo = [[self.allUploadsDictionary objectForKey:uploadUUID] retain];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:userInfo];
    [uploadInfo release];
}

- (void)clearUploads:(NSArray *)uploads
{
    [super clearUploads:uploads];
    
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
}

- (void)cancelActiveUploads
{
    [super cancelActiveUploads];
    
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
}

- (void)cancelActiveUploadsForAccountUUID:(NSString *)accountUUID
{
    [super cancelActiveUploadsForAccountUUID:accountUUID];
    
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
}

- (BOOL)retryUpload:(NSString *)uploadUUID
{
    [super retryUpload:uploadUUID];
    
    UploadInfo *uploadInfo = [self.allUploadsDictionary objectForKey:uploadUUID];
    
    [[NSNotificationCenter defaultCenter] postFavoriteUploadWaitingNotificationWithUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:uploadUUID, @"uploadUUID", uploadInfo, @"uploadInfo", nil]];
    
    return YES;
}

/*
 - (void)setQueueProgressDelegate:(id<ASIProgressDelegate>)progressDelegate
 {
 [self.uploadsQueue setUploadProgressDelegate:progressDelegate];
 }
 */


#pragma mark - ASINetworkQueueDelegateMethod
- (void)requestStarted:(CMISUploadFileHTTPRequest *)request
{
    [super requestStarted:request];
    
    UploadInfo *uploadInfo = request.uploadInfo;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadStartedNotificationWithUserInfo:userInfo];
}

- (void)requestFinished:(BaseHTTPRequest *)request 
{
    [super requestFinished:request];
}

- (void)requestFailed:(BaseHTTPRequest *)request 
{
    [super requestFailed:request];
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    [super queueFinished:queue];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
}

#pragma mark - private methods

- (void)successUpload:(UploadInfo *)uploadInfo
{
    if([self.allUploadsDictionary objectForKey:uploadInfo.uuid])
    {
        [super successUpload:uploadInfo];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
        [[NSNotificationCenter defaultCenter] postFavoriteUploadFinishedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:userInfo];
        
    }
    else {
        _GTMDevLog(@"The success upload %@ is no longer managed by the UploadsManager, ignoring", [uploadInfo completeFileName]);
    }
    
}
- (void)failedUpload:(UploadInfo *)uploadInfo withError:(NSError *)error
{
    if([self.allUploadsDictionary objectForKey:uploadInfo.uuid])
    {
        [super failedUpload:uploadInfo withError:error];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", error, @"uploadError", nil];
        [[NSNotificationCenter defaultCenter] postFavoriteUploadFailedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:userInfo];
    }
    else 
    {
        _GTMDevLog(@"The failed upload %@ is no longer managed by the UploadsManager, ignoring", [uploadInfo completeFileName]);
    }
}

#pragma mark - Singleton

+ (FavoritesUploadManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end

