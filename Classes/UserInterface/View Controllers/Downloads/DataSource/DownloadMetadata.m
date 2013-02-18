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
//  DownloadMetadata.m
//

#import "DownloadMetadata.h"
#import "FileDownloadManager.h"
#import "CMISConstants.h"

@interface DownloadMetadata()
@property (nonatomic, retain, readwrite) NSMutableDictionary *downloadInfo;
@end

@implementation DownloadMetadata

- (void)dealloc
{
    [_downloadInfo release];
    [super dealloc];
}

- (id)initWithDownloadInfo: (NSDictionary *) downInfo
{
    self = [super init];
    if (self)
    {
        self.downloadInfo = [NSMutableDictionary dictionaryWithDictionary:downInfo];
    }
    
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.downloadInfo = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (NSString *)accountUUID
{
    return _downloadInfo[@"accountUUID"];
}
- (void)setAccountUUID:(NSString *)accountUUID
{
    [self setObjectIfNotNil:accountUUID forKey:@"accountUUID"];
}

- (NSString *)tenantID 
{
    return _downloadInfo[@"tenantID"];
}
- (void)setTenantID:(NSString *)tenantID
{
    [self setObjectIfNotNil:tenantID forKey:@"tenantID"];
}

- (NSString *)objectId
{
    return _downloadInfo[@"objectId"];
}
- (void)setObjectId:(NSString *)objectId
{
    [self setObjectIfNotNil:objectId forKey:@"objectId"];
}

- (NSString *)filename
{
    return _downloadInfo[@"filename"];
}
- (void)setFilename:(NSString *)filename
{
    [self setObjectIfNotNil:filename forKey:@"filename"];
}

- (NSString *)versionSeriesId
{
    return _downloadInfo[@"versionSeriesId"];
}
- (void)setVersionSeriesId:(NSString *)versionSeriesId
{
    [self setObjectIfNotNil:versionSeriesId forKey:@"versionSeriesId"];
}

- (NSString *)contentStreamMimeType
{
    return _downloadInfo[@"contentStreamMimeType"];
}
- (void)setContentStreamMimeType:(NSString *)contentStreamMimeType
{
    [self setObjectIfNotNil:contentStreamMimeType forKey:@"contentStreamMimeType"];
}

- (NSString *)repositoryId
{
    return _downloadInfo[@"repositoryId"];
}
- (void)setRepositoryId:(NSString *)repositoryId
{
    [self setObjectIfNotNil:repositoryId forKey:@"repositoryId"];
}

- (NSDictionary *)metadata
{
    return _downloadInfo[@"metadata"];
}
- (void)setMetadata:(NSDictionary *)metadata
{
    [self setObjectIfNotNil:metadata forKey:@"metadata"];
}

- (NSArray *)aspects
{
    return _downloadInfo[@"aspects"];
}
- (void)setAspects:(NSArray *)aspects
{
    [self setObjectIfNotNil:aspects forKey:@"aspects"];
}

- (NSString *)describedByUrl
{
    return _downloadInfo[@"describedByUrl"];
}
- (void)setDescribedByUrl:(NSString *)describedByUrl
{
    [self setObjectIfNotNil:describedByUrl forKey:@"describedByUrl"];
}

- (NSString *)contentLocation
{
    return _downloadInfo[@"contentLocation"];
}
- (void)setContentLocation:(NSString *)contentLocation
{
    [self setObjectIfNotNil:contentLocation forKey:@"contentLocation"];
}

- (NSArray *)localComments
{
    NSArray *comments = _downloadInfo[@"localComments"];
    
    if (comments == nil)
    {
        comments = [NSArray array];
        [self setObjectIfNotNil:comments forKey:@"localComments"];
    }
    return comments;
}
- (void)setLocalComments:(NSArray *)localComments
{
    [self setObjectIfNotNil:localComments forKey:@"localComments"];
}

- (NSArray *)linkRelations
{
    return _downloadInfo[@"linkRelations"];
}
- (void)setLinkRelations:(NSArray *)linkRelations
{
    [self setObjectIfNotNil:linkRelations forKey:@"linkRelations"];
}

- (BOOL)canSetContentStream
{
    return [_downloadInfo[@"canSetContentStream"] boolValue];
}
- (void)setCanSetContentStream:(BOOL)canSetContentStream
{
    [self setObjectIfNotNil:[NSNumber numberWithBool:canSetContentStream] forKey:@"canSetContentStream"];
}

- (NSDictionary *)downloadInfo
{
    return [NSDictionary dictionaryWithDictionary:_downloadInfo];
}

- (NSString *)key
{
    if (kUseHash)
    {
        return _downloadInfo[@"versionSeriesId"];
    }
    return _downloadInfo[@"filename"];
}

- (BOOL)isMetadataAvailable
{
    return self.metadata && self.describedByUrl;
}

- (void)setObjectIfNotNil:(id)object forKey:(NSString *)key
{
    if (object != nil)
    {
        [_downloadInfo setObject:object forKey:key];
    }
}

- (RepositoryItem *)repositoryItem
{
    RepositoryItem *item = [[[RepositoryItem alloc] init] autorelease];
    item.title = self.filename;
    item.guid = self.objectId;
    item.metadata = [NSMutableDictionary dictionaryWithDictionary:self.metadata];
    item.aspects = [NSMutableArray arrayWithArray:self.aspects];
    item.describedByURL = self.describedByUrl;
    item.contentLocation = self.contentLocation;
    item.linkRelations = [NSMutableArray arrayWithArray:self.linkRelations];
    item.lastModifiedBy = [self.metadata objectForKey:kCMISLastModifiedPropertyName];
    item.lastModifiedDate = [self.metadata objectForKey:kCMISLastModificationDatePropertyName];
    item.fileType = [self.metadata objectForKey:kCMISBaseTypeIdPropertyName];
    item.contentStreamLengthString = [self.metadata objectForKey:kCMISContentStreamLengthPropertyName];
    item.versionSeriesId = [self.metadata objectForKey:kCMISVersionSeriesIdPropertyName];
    item.canSetContentStream = self.canSetContentStream;
    
    return item;
}


@end
