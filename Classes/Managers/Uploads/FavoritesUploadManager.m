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
//  FavoritesUploadManager.m
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
    return [super initWithConfigFile:kFavoritesUploadConfigurationFile andUploadQueue:@"FavoritesUploadQueue"];
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

    UploadInfo *uploadInfo = [self.allUploadsDictionary objectForKey:uploadUUID];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadCancelledNotificationWithUserInfo:userInfo];
}

- (void)clearUploads:(NSArray *)uploads
{
    [super clearUploads:uploads];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
}

- (void)cancelActiveUploads
{
    [super cancelActiveUploads];
    [self.allUploadsDictionary removeAllObjects];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
}

- (void)cancelActiveUploadsForAccountUUID:(NSString *)accountUUID
{
    [super cancelActiveUploadsForAccountUUID:accountUUID];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
}

- (BOOL)retryUpload:(NSString *)uploadUUID
{
    UploadInfo *uploadInfo = [self.allUploadsDictionary objectForKey:uploadUUID];
    NSString *uploadPath = [uploadInfo.uploadFileURL path];

    if (!uploadInfo || ![[NSFileManager defaultManager] fileExistsAtPath:uploadPath])
    {
        // We clear the upload since there's no reason to keep the upload visible
        if (uploadInfo)
        {
            [self clearUpload:uploadUUID];
        }
        
        return NO;
    }

    [self queueUpload:uploadInfo];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadWaitingNotificationWithUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:uploadUUID, @"uploadUUID", uploadInfo, @"uploadInfo", nil]];
    
    return YES;
}

#pragma mark - ASINetworkQueueDelegateMethod

- (void)requestStarted:(CMISUploadFileHTTPRequest *)request
{
    [super requestStarted:request];
    
    UploadInfo *uploadInfo = request.uploadInfo;
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadStartedNotificationWithUserInfo:userInfo];
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    [super queueFinished:queue];
    [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:nil];
}

#pragma mark - private methods

- (void)successUpload:(UploadInfo *)uploadInfo
{
    if ([self.allUploadsDictionary objectForKey:uploadInfo.uuid])
    {
        [super successUpload:uploadInfo];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
        [[NSNotificationCenter defaultCenter] postFavoriteUploadFinishedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postFavoriteUploadQueueChangedNotificationWithUserInfo:userInfo];
        
    }
    else
    {
        _GTMDevLog(@"The success upload %@ is no longer managed by the UploadsManager, ignoring", [uploadInfo completeFileName]);
    }
    
}

- (void)failedUpload:(UploadInfo *)uploadInfo withError:(NSError *)error
{
    if ([self.allUploadsDictionary objectForKey:uploadInfo.uuid])
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

