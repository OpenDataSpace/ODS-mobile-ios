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
//  DownloadMetadata.h
//

#import <Foundation/Foundation.h>
@class RepositoryItem;

@interface DownloadMetadata : NSObject {
    NSMutableDictionary *downloadInfo;
}

@property (readonly) NSDictionary *downloadInfo;
@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) NSString *objectId;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *versionSeriesId;
@property (nonatomic, retain) NSString *contentStreamMimeType;
@property (nonatomic, retain) NSString *repositoryId;
@property (nonatomic, retain) NSDictionary *metadata;
@property (nonatomic, retain) NSArray *aspects;
@property (nonatomic, retain) NSString *describedByUrl;
@property (nonatomic, retain) NSString *contentLocation;
@property (nonatomic, retain) NSArray *localComments;
@property (nonatomic, retain) NSArray *linkRelations;
@property (readonly) NSString *key;
@property (readonly) RepositoryItem *repositoryItem;

- (id)initWithDownloadInfo: (NSDictionary *) downInfo;

- (BOOL) isMetadataAvailable;

@end
