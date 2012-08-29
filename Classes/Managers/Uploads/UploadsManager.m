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
//  UploadsManager.m
//

#import "UploadsManager.h"

NSString * const kUploadConfigurationFile = @"UploadsMetadata.plist";

@implementation UploadsManager


- (void)dealloc
{
    [super dealloc];
}

- (id)init
{
    self = [super initWithConfigFile:kUploadConfigurationFile andUploadQueue:@"FDAddUploadQueue"];
    if(self)
    {
        
    }
    return self;
}

- (void)queueUpload:(UploadInfo *)uploadInfo
{
    dispatch_async(self.addUploadQueue, ^{
        
    [super queueUpload:uploadInfo];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:userInfo];
        
        
    });
}

- (void)queueUploadArray:(NSArray *)uploads
{
    dispatch_async(self.addUploadQueue, ^{
        
    [super queueUploadArray:uploads];
        
        [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
        
    });  
}

- (void)clearUpload:(NSString *)uploadUUID
{
    [super clearUpload:uploadUUID];
    
    UploadInfo *uploadInfo = [[self.allUploadsDictionary objectForKey:uploadUUID] retain];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:userInfo];
    [uploadInfo release];
}

- (void)clearUploads:(NSArray *)uploads
{
    [super clearUploads:uploads];
    
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
}

- (void)cancelActiveUploads
{
    [super cancelActiveUploads];
    
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
}

- (void)cancelActiveUploadsForAccountUUID:(NSString *)accountUUID
{
    [super cancelActiveUploadsForAccountUUID:accountUUID];
    
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
}

- (BOOL)retryUpload:(NSString *)uploadUUID
{
    [super retryUpload:uploadUUID];
    
    UploadInfo *uploadInfo = [self.allUploadsDictionary objectForKey:uploadUUID];
    
    [[NSNotificationCenter defaultCenter] postUploadWaitingNotificationWithUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:uploadUUID, @"uploadUUID", uploadInfo, @"uploadInfo", nil]];
    
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
    [[NSNotificationCenter defaultCenter] postUploadStartedNotificationWithUserInfo:userInfo];
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
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
}

#pragma mark - private methods

- (void)successUpload:(UploadInfo *)uploadInfo
{
    if([self.allUploadsDictionary objectForKey:uploadInfo.uuid])
    {
       [super successUpload:uploadInfo];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
        [[NSNotificationCenter defaultCenter] postUploadFinishedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:userInfo];
        
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
        [[NSNotificationCenter defaultCenter] postUploadFailedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:userInfo];
    }
    else 
    {
        _GTMDevLog(@"The failed upload %@ is no longer managed by the UploadsManager, ignoring", [uploadInfo completeFileName]);
    }
}

#pragma mark - Singleton

+ (UploadsManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end
