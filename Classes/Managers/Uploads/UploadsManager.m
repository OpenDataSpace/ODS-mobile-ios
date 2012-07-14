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
#import "TaggingHttpRequest.h"
#import "NodeRef.h"
#import "RepositoryItemParser.h"
#import "RepositoryItem.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "NSString+Utils.h"
#import "ActionServiceHTTPRequest.h"
#import "FileProtectionManager.h"

NSString * const kUploadConfigurationFile = @"UploadsMetadata.plist";

@interface UploadsManager ()
@property (nonatomic, retain, readwrite) ASINetworkQueue *uploadsQueue;

- (void)initQueue;
- (void)saveUploadsData;
- (void)startTaggingRequestWithUploadInfo:(UploadInfo *)uploadInfo;
- (void)startActionServiceRequestWithUploadInfo:(UploadInfo *)uploadInfo;
- (void)successUpload:(UploadInfo *)uploadInfo;
- (void)failedUpload:(UploadInfo *)uploadInfo withError:(NSError *)error;
@end

@implementation UploadsManager
@synthesize uploadsQueue = _uploadsQueue;

- (void)dealloc
{
    [_allUploads release];
    [_uploadsQueue release];
    [_taggingQueue release];
    [_nodeDocumentListings release];
    dispatch_release(_addUploadQueue);
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _addUploadQueue = dispatch_queue_create("FDAddUploadQueue", NULL);
        _nodeDocumentListings = [[NSMutableDictionary alloc] init];
        //We need to restore the uploads data source
        NSString *uploadsStorePath = [FileUtils pathToConfigFile:kUploadConfigurationFile];
        NSData *serializedUploadsData = [NSData dataWithContentsOfFile:uploadsStorePath];
        
        if (serializedUploadsData) 
        {
            //Complete protection for uploads metadata only if it already has data in it
            [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:uploadsStorePath];
            NSMutableDictionary *deserializedDict = [NSKeyedUnarchiver unarchiveObjectWithData:serializedUploadsData];
            if (deserializedDict)
            {
                _allUploads = [deserializedDict retain];
            }
        }
        
        if(!_allUploads)
        {
            _allUploads = [[NSMutableDictionary alloc] init];
        }
        
        _uploadsQueue = [[ASINetworkQueue alloc] init];
        [_uploadsQueue setMaxConcurrentOperationCount:2];
        [_uploadsQueue setDelegate:self];
        [_uploadsQueue setShowAccurateProgress:YES];
        [_uploadsQueue setShouldCancelAllRequestsOnFailure:NO];
        [_uploadsQueue setRequestDidFailSelector:@selector(requestFailed:)];
        [_uploadsQueue setRequestDidFinishSelector:@selector(requestFinished:)];
        [_uploadsQueue setRequestDidStartSelector:@selector(requestStarted:)];
        [_uploadsQueue setQueueDidFinishSelector:@selector(queueFinished:)];
        
        _taggingQueue = [[ASINetworkQueue alloc] init];
        [_taggingQueue setMaxConcurrentOperationCount:2];
        [_taggingQueue setDelegate:self];
        [_taggingQueue setShowAccurateProgress:YES];
        [_taggingQueue setShouldCancelAllRequestsOnFailure:NO];
        [_taggingQueue setRequestDidFailSelector:@selector(requestFailed:)];
        [_taggingQueue setRequestDidFinishSelector:@selector(requestFinished:)];
        [_taggingQueue setQueueDidFinishSelector:@selector(queueFinished:)];
        [self initQueue];
    }
    return self;
}

- (NSArray *)allUploads
{
    return [_allUploads allValues];
}

- (NSArray *)filterUploadsWithPredicate:(NSPredicate *)predicate
{
    NSArray *allUploads = [self allUploads];
    return [allUploads filteredArrayUsingPredicate:predicate];
}

- (NSArray *)activeUploads
{
    NSPredicate *activePredicate = [NSPredicate predicateWithFormat:@"uploadStatus == %@ OR uploadStatus == %@", [NSNumber numberWithInt:UploadInfoStatusActive], [NSNumber numberWithInt:UploadInfoStatusUploading]];
    return [self filterUploadsWithPredicate:activePredicate];
}

- (NSArray *)uploadsInUplinkRelation:(NSString *)upLinkRelation
{
    NSArray *activeUploads = [self allUploads];
    NSPredicate *uplinkPredicate = [NSPredicate predicateWithFormat:@"upLinkRelation == %@", upLinkRelation];
    NSArray *uploadsInSameUplink = [activeUploads filteredArrayUsingPredicate:uplinkPredicate];

    return uploadsInSameUplink;
}

- (NSArray *)failedUploads
{
    NSPredicate *failedPredicate = [NSPredicate predicateWithFormat:@"uploadStatus == %@", [NSNumber numberWithInt:UploadInfoStatusFailed]];
    return [self filterUploadsWithPredicate:failedPredicate];
}

- (BOOL)isManagedUpload:(NSString *)uuid
{
    return [_allUploads objectForKey:uuid] != nil;
}

- (void)addUploadToManaged:(UploadInfo *)uploadInfo
{
    [_allUploads setObject:uploadInfo forKey:uploadInfo.uuid];
    
    CMISUploadFileHTTPRequest *request = [CMISUploadFileHTTPRequest cmisUploadRequestWithUploadInfo:uploadInfo];
    [uploadInfo setUploadStatus:UploadInfoStatusActive];
    [uploadInfo setUploadRequest:request];
    [_uploadsQueue addOperation:request];
}

- (void)queueUpload:(UploadInfo *)uploadInfo
{
    dispatch_async(_addUploadQueue, ^{
        [self addUploadToManaged:uploadInfo];
        
        [self saveUploadsData];
        // We call go to the queue to start it, if the queue has already started it will not have any effect in the queue.
        [_uploadsQueue go];
        _GTMDevLog(@"Starting the upload for file %@ with uuid %@", [uploadInfo completeFileName], [uploadInfo uuid]);
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
        [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:userInfo];
    });
}

- (void)queueUploadArray:(NSArray *)uploads
{
    dispatch_async(_addUploadQueue, ^{
        [self.uploadsQueue setSuspended:YES];
        for(UploadInfo *uploadInfo in uploads)
        {
            [self addUploadToManaged:uploadInfo];
        }
        
        [self saveUploadsData];
        // We call go to the queue to start it, if the queue has already started it will not have any effect in the queue.
        [_uploadsQueue go];
        _GTMDevLog(@"Starting the upload of %d items", [uploads count]);
        
        [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
    });    
}

- (void)clearUpload:(NSString *)uploadUUID
{
    UploadInfo *uploadInfo = [[_allUploads objectForKey:uploadUUID] retain];
    [_allUploads removeObjectForKey:uploadUUID];
    
    if(uploadInfo.uploadRequest)
    {
        [uploadInfo.uploadRequest clearDelegatesAndCancel];
        CGFloat remainingBytes = [uploadInfo.uploadRequest postLength] - [uploadInfo.uploadRequest totalBytesSent];
        [self.uploadsQueue setTotalBytesToUpload:[self.uploadsQueue totalBytesToUpload]-remainingBytes ];
    }
    
    
    [self saveUploadsData];

    [uploadInfo autorelease];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:userInfo];
}

- (void)clearUploads:(NSArray *)uploads
{
    if([[uploads lastObject] isKindOfClass:[NSString class]])
    {
        [_allUploads removeObjectsForKeys:uploads];
        [self saveUploadsData];
        
        [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
    }
}

- (void)cancelActiveUploads
{
    NSArray *activeUploads = [self activeUploads];
    for(UploadInfo *activeUpload in activeUploads)
    {
        [_allUploads removeObjectForKey:activeUpload.uuid];
    }
    [self saveUploadsData];
    
    [_uploadsQueue cancelAllOperations];
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
}


- (BOOL)retryUpload:(NSString *)uploadUUID
{
    UploadInfo *uploadInfo = [_allUploads objectForKey:uploadUUID];
    
    NSString *uploadPath = [uploadInfo.uploadFileURL path];
    if(!uploadInfo || ![[NSFileManager defaultManager] fileExistsAtPath:uploadPath])
    {
        // We clear the upload since there's no reason to keep the upload visible
        if(uploadInfo)
        {
            [self clearUpload:uploadUUID];
        }
        UIAlertView *noFileAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploads.cancelAll.title", @"Uploads") message:@"The selected upload has been deleted from the temp folder, please try again from the Upload menu in the + button above" delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"Close") otherButtonTitles:nil];
        [noFileAlert show];
        [noFileAlert release];
        return NO;
    }
    [self queueUpload:uploadInfo];
    [[NSNotificationCenter defaultCenter] postUploadWaitingNotificationWithUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:uploadUUID, @"uploadUUID", uploadInfo, @"uploadInfo", nil]];
    return YES;
}

- (void)setQueueProgressDelegate:(id<ASIProgressDelegate>)progressDelegate
{
    [_uploadsQueue setUploadProgressDelegate:progressDelegate];
}

- (void)setExistingDocuments:(NSArray *)documentNames forUpLinkRelation:(NSString *)upLinkRelation;
{
    [_nodeDocumentListings setObject:documentNames forKey:upLinkRelation];
}

- (NSArray *)existingDocumentsForUplinkRelation:(NSString *)upLinkRelation
{
    NSArray *existingDocuments = [_nodeDocumentListings objectForKey:upLinkRelation];    
    
    NSPredicate *uplinkPredicate = [NSPredicate predicateWithFormat:@"upLinkRelation == %@", upLinkRelation];
    NSArray *uploadsInSameUplink = [[self allUploads] filteredArrayUsingPredicate:uplinkPredicate];
    NSMutableSet *managedUploadNames = [NSMutableSet setWithArray:existingDocuments];
    
    for(UploadInfo *uploadInfo in uploadsInSameUplink)
    {
        NSString *filename = [uploadInfo completeFileName];
        if([filename isNotEmpty])
        {
            [managedUploadNames addObject:filename];
        }
    }
    
    return [NSArray arrayWithArray:[managedUploadNames allObjects]];
}

#pragma mark - ASINetworkQueueDelegateMethod
- (void)requestStarted:(CMISUploadFileHTTPRequest *)request
{
    UploadInfo *uploadInfo = request.uploadInfo;
    [uploadInfo setUploadStatus:UploadInfoStatusUploading];
    [self saveUploadsData];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
    [[NSNotificationCenter defaultCenter] postUploadStartedNotificationWithUserInfo:userInfo];
}

- (void)requestFinished:(BaseHTTPRequest *)request 
{
    
    if([request isKindOfClass:[CMISUploadFileHTTPRequest class]])
    {
        UploadInfo *uploadInfo = [(CMISUploadFileHTTPRequest *)request uploadInfo];
        _GTMDevLog(@"Successful upload for file %@ and uuid %@", [uploadInfo completeFileName], [uploadInfo uuid]);
        RepositoryItemParser *itemParser = [[RepositoryItemParser alloc] initWithData:request.responseData];
        RepositoryItem *repositoryItem = [itemParser parse];
        [itemParser release];
        [uploadInfo setCmisObjectId:repositoryItem.guid];
        [uploadInfo setRepositoryItem:repositoryItem];
        [uploadInfo setUploadRequest:nil];
        [self saveUploadsData];
        
        if([uploadInfo.tags count] > 0)
        {
            _GTMDevLog(@"Starting the tagging request for file %@ and tags %@", [uploadInfo completeFileName], [uploadInfo tags]);
            [self startTaggingRequestWithUploadInfo:uploadInfo];
        }
        else 
        {
            // If no tags were selected, we procceed to mark the upload as success
            [self successUpload:uploadInfo];
        }
        
        _GTMDevLog(@"Starting the Action Service extract-metadata request for file %@", [uploadInfo completeFileName]);
        [self startActionServiceRequestWithUploadInfo:uploadInfo];
    }
    else if([request isKindOfClass:[TaggingHttpRequest class]])
    {
        NSString *uploadUUID = [(TaggingHttpRequest *)request uploadUUID];
        UploadInfo *uploadInfo = [_allUploads objectForKey:uploadUUID];
        // Mark the upload as success after a successful tagging request
        [self successUpload:uploadInfo];
    }
    else if([request isKindOfClass:[ActionServiceHTTPRequest class]])
    {
        _GTMDevLog(@"The Action Service extract-metadata request was successful for request %@", [request responseString]);
    }
}

- (void)requestFailed:(BaseHTTPRequest *)request 
{
    
    // Only if the file upload failed we mark it as a failed upload
    if([request isKindOfClass:[CMISUploadFileHTTPRequest class]])
    {
        // Do something different with the error if there's no connection available?
        if(([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
        {
        }
        
        UploadInfo *uploadInfo = [(CMISUploadFileHTTPRequest *)request uploadInfo];
        [uploadInfo setUploadRequest:nil];
        [self failedUpload:uploadInfo withError:request.error];
        
    }
    else if([request isKindOfClass:[TaggingHttpRequest class]]) 
    {
        //We want to ignore the tagging fails, might change in the future
        NSString *uploadUUID = [(TaggingHttpRequest *)request uploadUUID];
        UploadInfo *uploadInfo = [_allUploads objectForKey:uploadUUID];
        [uploadInfo setUploadRequest:nil];
        // Mark the upload as success after a failed tagging request
        [self successUpload:uploadInfo];
    }
    else if([request isKindOfClass:[ActionServiceHTTPRequest class]])
    {
        NSLog(@"The Action Service extract-metadata request failed for request %@ and error: %@", [request postBody], [request error]);
    }
    
    
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:nil];
    [queue cancelAllOperations];
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
            
            if(uploadInfo.cmisObjectId)
            {
                // Means that the upload was complete but the tagging request was never finished
                [self startTaggingRequestWithUploadInfo:uploadInfo];
            }
            else {
                request = [CMISUploadFileHTTPRequest cmisUploadRequestWithUploadInfo:uploadInfo];
                [_uploadsQueue addOperation:request];
            }
            
            pendingUploads = YES;
        }
        else if(uploadInfo.uploadStatus != UploadInfoStatusFailed)
        {
            [_allUploads removeObjectForKey:uploadInfo.uuid];
        }
    }
    
    [self saveUploadsData];
    
    if(pendingUploads)
    {
        [_uploadsQueue go];
    }
}

- (void)saveUploadsData
{
    NSString *uploadsStorePath = [FileUtils pathToConfigFile:kUploadConfigurationFile];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_allUploads];
    [data writeToFile:uploadsStorePath atomically:YES];
    //Complete protection for uploads metadata
    [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:uploadsStorePath];
}

- (void)startTaggingRequestWithUploadInfo:(UploadInfo *)uploadInfo
{
    TaggingHttpRequest *request = [TaggingHttpRequest httpRequestAddTags:uploadInfo.tags
                                                                  toNode:[NodeRef nodeRefFromCmisObjectId:uploadInfo.cmisObjectId]
                                                             accountUUID:uploadInfo.selectedAccountUUID 
                                                                tenantID:uploadInfo.tenantID];
    [request setUploadUUID:uploadInfo.uuid];
    [_taggingQueue addOperation:request];
    [_taggingQueue go];
}

- (void)startActionServiceRequestWithUploadInfo:(UploadInfo *)uploadInfo
{
    ActionServiceHTTPRequest *request = [ActionServiceHTTPRequest requestWithDefinitionName:ActionDefinitionExtractMetadata withNode:uploadInfo.cmisObjectId accountUUID:uploadInfo.selectedAccountUUID  tenantID:uploadInfo.tenantID];
    [_taggingQueue addOperation:request];
    [_taggingQueue go];
}

- (void)successUpload:(UploadInfo *)uploadInfo
{
    if([_allUploads objectForKey:uploadInfo.uuid])
    {
        [uploadInfo setUploadStatus:UploadInfoStatusUploaded];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:uploadInfo, @"uploadInfo", uploadInfo.uuid, @"uploadUUID", nil];
        [[NSNotificationCenter defaultCenter] postUploadFinishedNotificationWithUserInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postUploadQueueChangedNotificationWithUserInfo:userInfo];
        
        //We don't manage successfull uploads
        [_allUploads removeObjectForKey:uploadInfo.uuid];
        [self saveUploadsData];
    }
    else {
        _GTMDevLog(@"The success upload %@ is no longer managed by the UploadsManager, ignoring", [uploadInfo completeFileName]);
    }
}
- (void)failedUpload:(UploadInfo *)uploadInfo withError:(NSError *)error
{
    if([_allUploads objectForKey:uploadInfo.uuid])
    {
        _GTMDevLog(@"Upload Failed for file %@ and uuid %@ with error: %@", [uploadInfo completeFileName], [uploadInfo uuid], error);
        [uploadInfo setUploadStatus:UploadInfoStatusFailed];
        [uploadInfo setError:error];
        [self saveUploadsData];
        
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
