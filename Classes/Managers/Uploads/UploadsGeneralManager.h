//
//  UploadsGeneralManager.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 20/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"
#import "ASIProgressDelegate.h"

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

@class UploadInfo;

@interface UploadsGeneralManager : NSObject


@property (nonatomic, retain, readonly) ASINetworkQueue *uploadsQueue;

// Returns all the current uploads managed by this object
- (NSArray *)allUploads;

// Returns all the active uploads managed by this object
- (NSArray *)activeUploads;

- (NSArray *)uploadsInUplinkRelation:(NSString *)upLinkRelation;

// Returns all the failed uploads managed by this object
- (NSArray *)failedUploads;

- (BOOL)isManagedUpload:(NSString *)uuid;

// Adds an upload to the uploads queue and will be part of the uploads managed by the
// Uploads Manager
- (void)queueUpload:(UploadInfo *)uploadInfo;
// Adds an aray of upload infos to the uploads queue and will be part of the uploads managed by the
// Uploads Manager
- (void)queueUploadArray:(NSArray *)uploads;
// Deletes the upload from the upload datasource.
- (void)clearUpload:(NSString *)uploadUUID;
// Deletes an array of uploads upload datasource.
- (void)clearUploads:(NSArray *)uploads;
// Tries to cancel and delete the active uploads
- (void)cancelActiveUploads;
// Tries to retry an upload. returns YES if sucessful, NO if there was a problem (upload file missing, upload no longer managed) 
- (BOOL)retryUpload:(NSString *)uploadUUID;

- (void)setQueueProgressDelegate:(id<ASIProgressDelegate>)progressDelegate;

- (void)setExistingDocuments:(NSArray *)documentNames forUpLinkRelation:(NSString *)upLinkRelation;
- (NSArray *)existingDocumentsForUplinkRelation:(NSString *)upLinkRelation;




@property (nonatomic, retain) NSMutableDictionary *allUploadsDictionary;
@property (nonatomic, retain) ASINetworkQueue *taggingQueue;
@property (nonatomic, retain) NSMutableDictionary *nodeDocumentListings;
@property (nonatomic, assign) dispatch_queue_t addUploadQueue;


- (void)initQueue;
- (void)saveUploadsData;
- (void)startTaggingRequestWithUploadInfo:(UploadInfo *)uploadInfo;
- (void)startActionServiceRequestWithUploadInfo:(UploadInfo *)uploadInfo;
- (void)successUpload:(UploadInfo *)uploadInfo;
- (void)failedUpload:(UploadInfo *)uploadInfo withError:(NSError *)error;

// Static selector to access this class singleton instance
+ (id)sharedManager;

@end
