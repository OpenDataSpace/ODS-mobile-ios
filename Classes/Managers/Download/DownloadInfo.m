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
//  DownloadInfo.m
//

#import "DownloadInfo.h"
#import "RepositoryItem.h"
#import "DownloadMetadata.h"
#import "RepositoryServices.h"

@implementation DownloadInfo
@synthesize nodeItem = _nodeItem;
@synthesize isBase64Encoded = _isBase64Encoded;
@synthesize isCompleted = _isCompleted;
@synthesize tempFilePath = _tempFilePath;
@synthesize accountUUID = _accountUUID;
@synthesize tenantID = _tenantID;

-(void) dealloc 
{
    [_nodeItem release];
    [_tempFilePath release];
    [_accountUUID release];
    [_tenantID release];
    [super dealloc];
}

- (id)initWithNodeItem: (RepositoryItem *) nodeItem
{
    self = [super init];
    if (self) {
        self.nodeItem = nodeItem;
    }
    
    return self;
}

- (DownloadMetadata *)downloadMetadata 
{
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:self.accountUUID tenantID:self.tenantID];
                                
    DownloadMetadata *downloadMetadata = [[DownloadMetadata alloc] init];
    downloadMetadata.filename = _nodeItem.title;
    downloadMetadata.accountUUID = _accountUUID;
    downloadMetadata.tenantID = _tenantID;
    downloadMetadata.objectId = _nodeItem.guid;
    downloadMetadata.contentStreamMimeType = [[_nodeItem metadata] objectForKey:@"cmis:contentStreamMimeType"]; // TODO Constants
    downloadMetadata.versionSeriesId = _nodeItem.versionSeriesId;
    downloadMetadata.repositoryId = [repoInfo repositoryId];
    downloadMetadata.metadata = _nodeItem.metadata;
    downloadMetadata.describedByUrl = _nodeItem.describedByURL;
    downloadMetadata.contentLocation = _nodeItem.contentLocation;
    downloadMetadata.linkRelations = _nodeItem.linkRelations;
    
    return [downloadMetadata autorelease];
}

@end
