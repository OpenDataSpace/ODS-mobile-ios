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

#import <objc/runtime.h>
#import "DownloadInfo.h"
#import "DownloadMetadata.h"
#import "FileUtils.h"
#import "RepositoryItem.h"
#import "RepositoryServices.h"

@implementation DownloadInfo
@synthesize repositoryItem = _repositoryItem;
@synthesize tempFilePath = _tempFilePath;
@synthesize downloadFileURL = _downloadFileURL;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;
@synthesize downloadStatus = _downloadStatus;
@synthesize downloadRequest = _downloadRequest;
@synthesize error = _error;

- (void)dealloc 
{
    [_repositoryItem release];
    [_tempFilePath release];
    [_downloadFileURL release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [_downloadRequest release];
    [_error release];
    [super dealloc];
}

- (id)initWithRepositoryItem:(RepositoryItem *)repositoryItem
{
    self = [super init];
    if (self)
    {
        [self setRepositoryItem:repositoryItem];
    }
    
    return self;
}

- (void)setRepositoryItem:(RepositoryItem *)repositoryItem
{
    [_repositoryItem autorelease];
    _repositoryItem = [repositoryItem retain];
    
    if (repositoryItem != nil)
    {
        [self setTempFilePath:[FileUtils pathToTempFile:repositoryItem.title]];
        [self setDownloadFileURL:[NSURL URLWithString:repositoryItem.contentLocation]];
    }
}

- (DownloadMetadata *)downloadMetadata 
{
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
                                
    DownloadMetadata *downloadMetadata = [[DownloadMetadata alloc] init];
    downloadMetadata.filename = self.repositoryItem.title;
    downloadMetadata.accountUUID = self.selectedAccountUUID;
    downloadMetadata.tenantID = self.tenantID;
    downloadMetadata.objectId = self.repositoryItem.guid;
    downloadMetadata.contentStreamMimeType = [self.repositoryItem.metadata objectForKey:@"cmis:contentStreamMimeType"]; // TODO Constants
    downloadMetadata.versionSeriesId = self.repositoryItem.versionSeriesId;
    downloadMetadata.repositoryId = repoInfo.repositoryId;
    downloadMetadata.metadata = self.repositoryItem.metadata;
    downloadMetadata.describedByUrl = self.repositoryItem.describedByURL;
    downloadMetadata.contentLocation = self.repositoryItem.contentLocation;
    downloadMetadata.linkRelations = self.repositoryItem.linkRelations;
    
    return [downloadMetadata autorelease];
}

- (NSString *)cmisObjectId
{
    return self.repositoryItem.guid;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"DownloadInfo: %@, objectId: %@, status %u", [self class], self.cmisObjectId, self.downloadStatus];
}

@end
