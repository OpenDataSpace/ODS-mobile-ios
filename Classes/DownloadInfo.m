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
 * Portions created by the Initial Developer are Copyright (C) 2011
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

-(void) dealloc {
    [_nodeItem release];
    [_tempFilePath release];
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

- (DownloadMetadata *) downloadMetadata {
    DownloadMetadata *downloadMetadata = [[DownloadMetadata alloc] init];
    downloadMetadata.filename = _nodeItem.title;
    downloadMetadata.objectId = _nodeItem.guid;
    downloadMetadata.contentStreamMimeType = [[_nodeItem metadata] objectForKey:@"cmis:contentStreamMimeType"];
    downloadMetadata.versionSeriesId = _nodeItem.versionSeriesId;
    downloadMetadata.repositoryId = [[[RepositoryServices shared] currentRepositoryInfo] repositoryId];
    downloadMetadata.metadata = _nodeItem.metadata;
    downloadMetadata.describedByUrl = _nodeItem.describedByURL;
    downloadMetadata.contentLocation = _nodeItem.contentLocation;
    downloadMetadata.linkRelations = _nodeItem.linkRelations;
    
    return [downloadMetadata autorelease];
}

@end
