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
//  CMISUploadFileHTTPRequest.m
//

#import "CMISUploadFileHTTPRequest.h"
#import "UploadInfo.h"
#import "CMISMediaTypes.h"
#import "CMISAtomEntryWriter.h"
#import "UploadsManager.h"

@implementation CMISUploadFileHTTPRequest
@synthesize uploadInfo = _uploadInfo;

- (void)dealloc
{
    [_uploadInfo release];
    [super dealloc];
}

+ (CMISUploadFileHTTPRequest *)cmisUploadRequestWithUploadInfo:(UploadInfo *)uploadInfo
{
    CMISUploadFileHTTPRequest *request = [CMISUploadFileHTTPRequest requestWithURL:[uploadInfo uploadURL] accountUUID:[uploadInfo selectedAccountUUID]];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Content-Type" value:kAtomEntryMediaType];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setUploadInfo:uploadInfo];
    [request setShouldResetUploadProgress:NO];
    // Give the server more time to decode potentially large CMIS bodies from base64
    [request setTimeOutSeconds:60];
    
    // Last minute setting the filename with the default {MEDIA_TYPE} {DATE_TIME}.{EXTENSION}
    if(![uploadInfo.filename isNotEmpty])
    {
        NSArray *existingDocuments = [[UploadsManager sharedManager] existingDocumentsForUplinkRelation:uploadInfo.upLinkRelation];
        NSDate *now = [NSDate date];
        [uploadInfo setFilenameWithDate:now andExistingDocuments:existingDocuments];
    }

    // Write the atompub data to a temporary file
    NSString *xmlFilePath = [CMISAtomEntryWriter generateAtomEntryXmlForFilePath:[uploadInfo.uploadFileURL path] uploadFilename:uploadInfo.completeFileName];
    [request setPostBodyFilePath:xmlFilePath];
    [request setShouldStreamPostDataFromDisk:YES];
    
    return request;
}
@end
