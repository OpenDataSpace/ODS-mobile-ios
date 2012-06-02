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
#import "NSString+Utils.h"

NSString * const kDownloadInfoUUID = @"uuid";
NSString * const kDownloadInfoDownloadFileURL = @"downloadFileURL";
NSString * const kDownloadInfoCmisObjectId = @"cmidObjectId";
NSString * const kDownloadInfoRepositoryItem = @"repositoryItem";
NSString * const kDownloadInfoDownloadStatus = @"downloadStatus";
NSString * const kDownloadInfoDownloadRequest = @"downloadRequest";
NSString * const kDownloadInfoError = @"error";
NSString * const kDownloadInfoDownloadDestinationPath = @"downloadDestinationPath";
NSString * const kDownloadInfoSelectedAccountUUID = @"selectedAccountUUID";
NSString * const kDownloadInfoTenantID = @"tenantId";

@implementation DownloadInfo
@synthesize uuid = _uuid;
@synthesize downloadFileURL = _downloadFileURL;
@synthesize cmisObjectId = _cmisObjectId;
@synthesize repositoryItem = _repositoryItem;
@synthesize downloadStatus = _downloadStatus;
@synthesize downloadRequest = _downloadRequest;
@synthesize error = _error;
@synthesize downloadDestinationPath = _downloadDestinationPath;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

-(void) dealloc 
{
    [_uuid release];
    [_downloadFileURL release];
    [_cmisObjectId release];
    [_repositoryItem release];
    [_downloadRequest release];
    [_error release];
    [_downloadDestinationPath release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [super dealloc];
}

#pragma mark - NSCoding

- (id)initWithRepositoryItem:(RepositoryItem *)repositoryItem
{
    self = [super init];
    if (self)
    {
        [self setUuid:[NSString generateUUID]];
        [self setDownloadStatus:DownloadInfoStatusInactive];
        [self setRepositoryItem:repositoryItem];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) 
    {
        [self setUuid:[aDecoder decodeObjectForKey:kDownloadInfoUUID]];
        if (nil == self.uuid)
        {
            // We should never get here.
            [self setUuid:[NSString generateUUID]];
        }
        
        [self setDownloadFileURL:[aDecoder decodeObjectForKey:kDownloadInfoDownloadFileURL]];
        [self setCmisObjectId:[aDecoder decodeObjectForKey:kDownloadInfoCmisObjectId]];
        [self setDownloadStatus:[[aDecoder decodeObjectForKey:kDownloadInfoDownloadStatus] intValue]];
        [self setError:[aDecoder decodeObjectForKey:kDownloadInfoError]];
        [self setDownloadDestinationPath:[aDecoder decodeObjectForKey:kDownloadInfoDownloadDestinationPath]];
        [self setSelectedAccountUUID:[aDecoder decodeObjectForKey:kDownloadInfoSelectedAccountUUID]];
        [self setTenantID:[aDecoder decodeObjectForKey:kDownloadInfoTenantID]];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.uuid forKey:kDownloadInfoUUID];
    [aCoder encodeObject:self.downloadFileURL forKey:kDownloadInfoDownloadFileURL];
    [aCoder encodeObject:self.cmisObjectId forKey:kDownloadInfoCmisObjectId];
    [aCoder encodeObject:[NSNumber numberWithInt:self.downloadStatus] forKey:kDownloadInfoDownloadStatus];
    [aCoder encodeObject:self.error forKey:kDownloadInfoError];
    [aCoder encodeObject:self.downloadDestinationPath forKey:kDownloadInfoDownloadDestinationPath];
    [aCoder encodeObject:self.selectedAccountUUID forKey:kDownloadInfoSelectedAccountUUID];
    [aCoder encodeObject:self.tenantID forKey:kDownloadInfoTenantID];
}

- (void)setRepositoryItem:(RepositoryItem *)repositoryItem
{
    [_repositoryItem autorelease];
    _repositoryItem = [repositoryItem retain];
}

- (DownloadMetadata *)downloadMetadata 
{
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
                                
    DownloadMetadata *downloadMetadata = [[DownloadMetadata alloc] init];
    downloadMetadata.filename = self.repositoryItem.title;
    downloadMetadata.accountUUID = self.selectedAccountUUID;
    downloadMetadata.tenantID = self.tenantID;
    downloadMetadata.objectId = self.repositoryItem.guid;
    downloadMetadata.contentStreamMimeType = [[self.repositoryItem metadata] objectForKey:@"cmis:contentStreamMimeType"]; // TODO Constants
    downloadMetadata.versionSeriesId = self.repositoryItem.versionSeriesId;
    downloadMetadata.repositoryId = [repoInfo repositoryId];
    downloadMetadata.metadata = self.repositoryItem.metadata;
    downloadMetadata.describedByUrl = self.repositoryItem.describedByURL;
    downloadMetadata.contentLocation = self.repositoryItem.contentLocation;
    downloadMetadata.linkRelations = self.repositoryItem.linkRelations;
    
    return [downloadMetadata autorelease];
}

@end
