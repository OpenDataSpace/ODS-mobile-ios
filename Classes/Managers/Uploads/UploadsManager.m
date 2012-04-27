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
#import "UploadInfo.h"
#import "FileUtils.h"
#import "BaseHTTPRequest.h"
#import "CMISMediaTypes.h"
#import "Utility.h"
#import "CMISUploadFileHTTPRequest.h"
#import "AccountManager.h"

NSString * const kUploadConfigurationFile = @"UploadsMetadata.plist";

@interface UploadsManager ()
- (void)initQueue;
- (void)saveUploadsData;
@end

@implementation UploadsManager

- (void)dealloc
{
    [_allUploads release];
    [_uploadsQueue release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        //We need to restore the uploads data source
        NSString *uploadsStorePath = [FileUtils pathToConfigFile:kUploadConfigurationFile];
        NSData *serializedUploadsData = [NSData dataWithContentsOfFile:uploadsStorePath];
        
        if (serializedUploadsData) 
        {
            NSMutableDictionary *deserializedDict = [NSKeyedUnarchiver unarchiveObjectWithData:serializedUploadsData];
            if (deserializedDict)
            {
                _allUploads = [deserializedDict retain];
            }
        }
        
        _uploadsQueue = [[ASINetworkQueue alloc] init];
        [_uploadsQueue setDelegate:self];
        [_uploadsQueue setShowAccurateProgress:NO];
        [_uploadsQueue setShouldCancelAllRequestsOnFailure:NO];
        [_uploadsQueue setRequestDidFailSelector:@selector(requestFailed:)];
        [_uploadsQueue setRequestDidFinishSelector:@selector(requestFinished:)];
        [_uploadsQueue setQueueDidFinishSelector:@selector(queueFinished:)];
        [self initQueue];
    }
    return self;
}

- (NSArray *)allUploads
{
    return [_allUploads allValues];
}

- (void)queueUpload:(UploadInfo *)uploadInfo
{
    [_allUploads setObject:uploadInfo forKey:uploadInfo.uuid];
    
    CMISUploadFileHTTPRequest *request = [CMISUploadFileHTTPRequest cmisUploadRequestWithUploadInfo:uploadInfo];
    [uploadInfo setUploadStatus:UploadInfoStatusActive];
    [_uploadsQueue addOperation:request];
    
    [self saveUploadsData];
    // We call go to the queue to start it, if the queue has already started it will not have any effect in the queue.
    [_uploadsQueue go];
}

- (void)clearUpload:(NSString *)uploadUUID
{
    [_allUploads removeObjectForKey:uploadUUID];
    [self saveUploadsData];
}

#pragma mark - ASINetworkQueueDelegateMethod
- (void)requestFinished:(CMISUploadFileHTTPRequest *)request 
{
    UploadInfo *uploadInfo = [request uploadInfo];
    [uploadInfo setUploadStatus:UploadInfoStatusUploaded];
    [self saveUploadsData];
    _GTMDevLog(@"Successful upload for file %@ and uuid %@", [uploadInfo completeFileName], [uploadInfo uuid]);
}

- (void)requestFailed:(CMISUploadFileHTTPRequest *)request 
{
    UploadInfo *uploadInfo = [request uploadInfo];
    [uploadInfo setUploadStatus:UploadInfoStatusFailed];
    [self saveUploadsData];
    _GTMDevLog(@"Upload Failed for file %@ and uuid %@ with error: %@", [uploadInfo completeFileName], [uploadInfo uuid], [request error]);
    
    // It shows an error alert only one time for a given queue
    if(_showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
        showOfflineModeAlert([request.url absoluteString]);
        _showOfflineAlert = NO;
    }
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
}

#pragma mark - private methods
- (void)initQueue
{
    CMISUploadFileHTTPRequest *request = nil;
    BOOL pendingUploads = NO;
    
    for(UploadInfo *uploadInfo in [_allUploads allValues])
    {
        // Only Active uploads should be initialized, included the Inactive ones just to be sure
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[uploadInfo.uploadFileURL absoluteString]];
        BOOL accountExists = [[AccountManager sharedManager] accountInfoForUUID:uploadInfo.selectedAccountUUID] != nil;
        
        if((uploadInfo.uploadStatus == UploadInfoStatusActive || uploadInfo.uploadStatus == UploadInfoStatusInactive) && fileExists && accountExists)
        {
            [uploadInfo setUploadStatus:UploadInfoStatusActive];
            
            request = [CMISUploadFileHTTPRequest cmisUploadRequestWithUploadInfo:uploadInfo];
            [_uploadsQueue addOperation:request];
            pendingUploads = YES;
        }
    }
    
    if(pendingUploads)
    {
        [self saveUploadsData];
        [_uploadsQueue go];
    }
}

- (void)saveUploadsData
{
    NSString *uploadsStorePath = [FileUtils pathToConfigFile:kUploadConfigurationFile];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_allUploads];
    [data writeToFile:uploadsStorePath atomically:YES];
}

#pragma mark - Singleton

static UploadsManager *sharedUploadsManager = nil;

+ (id)sharedManager
{
    if (sharedUploadsManager == nil) {
        sharedUploadsManager = [[super allocWithZone:NULL] init];
    }
    return sharedUploadsManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end
