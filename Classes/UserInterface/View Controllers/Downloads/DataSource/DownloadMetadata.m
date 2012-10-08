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

@interface DownloadMetadata (PrivateMethods)
- (void) setObjectIfNotNil: (id) object forKey: (NSString *) key;
@end

@implementation DownloadMetadata

- (void) dealloc {
    [downloadInfo release];
    [super dealloc];
}

- (id)initWithDownloadInfo: (NSDictionary *) downInfo
{
    self = [super init];
    if (self) {
        downloadInfo = [[NSMutableDictionary dictionaryWithDictionary:downInfo] retain];
    }
    
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        downloadInfo = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (NSString *)accountUUID {
    return [downloadInfo objectForKey:@"accountUUID"];
}

- (void) setAccountUUID:(NSString *)accountUUID{
    [self setObjectIfNotNil:accountUUID forKey:@"accountUUID"];
}

- (NSString *)tenantID 
{
    return [downloadInfo objectForKey:@"tenantID"];
}

- (void)setTenantID:(NSString *)tenantID
{
    [self setObjectIfNotNil:tenantID forKey:@"tenantID"];
}

- (NSString *) objectId {
    return [downloadInfo objectForKey:@"objectId"];
}

- (void) setObjectId: (NSString *) objectId {
    [self setObjectIfNotNil:objectId forKey:@"objectId"];
}

- (NSString *) filename {
    return [downloadInfo objectForKey:@"filename"];
}

- (void) setFilename: (NSString *) filename {
    [self setObjectIfNotNil:filename forKey:@"filename"];
}

- (NSString *) versionSeriesId {
    return [downloadInfo objectForKey:@"versionSeriesId"];
}

- (void) setVersionSeriesId: (NSString *) versionSeriesId {
    [self setObjectIfNotNil:versionSeriesId forKey:@"versionSeriesId"];
}

- (NSString *) contentStreamMimeType {
    return [downloadInfo objectForKey:@"contentStreamMimeType"];
}

- (void) setContentStreamMimeType: (NSString *) contentStreamMimeType {
    [self setObjectIfNotNil:contentStreamMimeType forKey:@"contentStreamMimeType"];
}

- (NSString *) repositoryId {
    return [downloadInfo objectForKey:@"repositoryId"];
}

- (void) setRepositoryId: (NSString *) repositoryId {
    [self setObjectIfNotNil:repositoryId forKey:@"repositoryId"];
}

- (NSDictionary *) metadata {
    return [downloadInfo objectForKey:@"metadata"];
}

- (void) setMetadata:(NSDictionary *)metadata {
    [self setObjectIfNotNil:metadata forKey:@"metadata"];
}

- (NSString *) describedByUrl {
    return [downloadInfo objectForKey:@"describedByUrl"];
}

- (void) setDescribedByUrl:(NSString *)describedByUrl {
    [self setObjectIfNotNil:describedByUrl forKey:@"describedByUrl"];
}

- (NSString *) contentLocation {
    return [downloadInfo objectForKey:@"contentLocation"];
}

- (void) setContentLocation:(NSString *)contentLocation {
    [self setObjectIfNotNil:contentLocation forKey:@"contentLocation"];
}

- (NSArray *) localComments {
    NSArray *comments = [downloadInfo objectForKey:@"localComments"];
    
    if(comments == nil) {
        comments = [NSArray array];
        [self setObjectIfNotNil:comments forKey:@"localComments"];
    }
    return comments;
}

- (void) setLocalComments:(NSArray *)localComments {
    [self setObjectIfNotNil:localComments forKey:@"localComments"];
}

- (NSArray *)linkRelations {
    return [downloadInfo objectForKey:@"linkRelations"];
}

- (void) setLinkRelations:(NSArray *)linkRelations {
    [self setObjectIfNotNil:linkRelations forKey:@"linkRelations"];
}

- (NSDictionary *) downloadInfo {
    return [NSDictionary dictionaryWithDictionary:downloadInfo];
}

- (NSString *) key {
    if(kUseHash) {
        return [downloadInfo objectForKey:@"versionSeriesId"];
    } else {
        return [downloadInfo objectForKey:@"filename"];
    }
}

- (BOOL) isMetadataAvailable {
    return self.metadata && self.describedByUrl;
}

- (void) setObjectIfNotNil: (id) object forKey: (NSString *) key {
    if(object) {
        [downloadInfo setObject:object forKey:key];
    }
}

- (RepositoryItem *)repositoryItem {
    RepositoryItem *item = [[RepositoryItem alloc] init];
    item.title = [self filename];
    item.guid = [self objectId];
    item.metadata = [NSMutableDictionary dictionaryWithDictionary:[self metadata]];
    item.describedByURL = [self describedByUrl];
    item.contentLocation = [self contentLocation];
    item.linkRelations = [NSMutableArray arrayWithArray:[self linkRelations]];
    item.lastModifiedBy = [self.metadata objectForKey:kCMISLastModifiedPropertyName];
    item.lastModifiedDate = [self.metadata objectForKey:kCMISLastModificationDatePropertyName];
    item.fileType = [self.metadata objectForKey:kCMISBaseTypeIdPropertyName];
    item.contentStreamLengthString = [self.metadata objectForKey:kCMISContentStreamLengthPropertyName];
    item.versionSeriesId = [self.metadata objectForKey:kCMISVersionSeriesIdPropertyName];
    
    return [item autorelease];
}


@end
