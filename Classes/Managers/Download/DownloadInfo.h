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
//  DownloadInfo.h
//

#import <Foundation/Foundation.h>
@class RepositoryItem;
@class DownloadMetadata;
@class CMISDownloadFileHTTPRequest;

typedef enum
{
    DownloadInfoStatusInactive,
    DownloadInfoStatusActive,
    DownloadInfoStatusDownloading,
    DownloadInfoStatusDownloaded,
    DownloadInfoStatusFailed
} DownloadInfoStatus;

@interface DownloadInfo : NSObject

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, retain) NSURL *downloadFileURL;
@property (nonatomic, copy) NSString *cmisObjectId;
@property (nonatomic, retain) RepositoryItem *repositoryItem;
@property (nonatomic, assign) DownloadInfoStatus downloadStatus;
@property (nonatomic, retain) CMISDownloadFileHTTPRequest *downloadRequest;
@property (nonatomic, retain) NSError *error;

@property (nonatomic, copy) NSString *downloadDestinationPath;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, copy) NSString *tenantID;
@property (nonatomic, readonly) DownloadMetadata *downloadMetadata;

- (id)initWithRepositoryItem:(RepositoryItem *)repositoryItem;

@end
