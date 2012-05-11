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
//  UploadsManager.h
//
// The UploadsManager will manage all uploads in an ASINetworkQueue
// Also will track all current, finished and failed uploads to serve as a DataSource
// for the view controller that will show the current progress and status of the upload

#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"
#import "ASIProgressDelegate.h"

@class UploadInfo;

@interface UploadsManager : NSObject
{
    NSMutableDictionary *_allUploads;
    ASINetworkQueue *_uploadsQueue;
    ASINetworkQueue *_taggingQueue;
    NSMutableDictionary *_nodeDocumentListings;
}

@property (nonatomic, retain, readonly) ASINetworkQueue *uploadsQueue;

// Returns all the current uploads managed by this object
- (NSArray *)allUploads;

// Returns all the active uploads managed by this object
- (NSArray *)activeUploads;

- (NSArray *)activeUploadsInUplinkRelation:(NSString *)upLinkRelation;

// Returns all the failed uploads managed by this object
- (NSArray *)failedUploads;

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

- (void)setQueueProgressDelegate:(id<ASIProgressDelegate>)progressDelegate;

- (void)setExistingDocuments:(NSArray *)documentNames forUpLinkRelation:(NSString *)upLinkRelation;
- (NSArray *)existingDocumentsForUplinkRelation:(NSString *)upLinkRelation;

// Static selector to access this class singleton instance
+ (id)sharedManager;

@end
