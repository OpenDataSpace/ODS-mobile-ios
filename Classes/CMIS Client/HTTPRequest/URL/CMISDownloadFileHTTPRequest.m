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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  DownloadObjectRequest.m
//

#import "CMISDownloadFileHTTPRequest.h"
#import "DownloadInfo.h"

@implementation CMISDownloadFileHTTPRequest
@synthesize downloadInfo = _downloadInfo;

-(void)dealloc
{
    [_downloadInfo release];
    [super dealloc];
}

+(CMISDownloadFileHTTPRequest *)cmisDownloadRequestWithDownloadInfo:(DownloadInfo *)downloadInfo
{
    CMISDownloadFileHTTPRequest *request = [CMISDownloadFileHTTPRequest requestWithURL:[downloadInfo downloadFileURL] accountUUID:[downloadInfo selectedAccountUUID]];
    [request setShowAccurateProgress:YES];
    [request setDownloadDestinationPath:[downloadInfo tempFilePath]];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setSuppressAllErrors:YES];
    [request setDownloadInfo:downloadInfo];
    [request setDownloadProgressDelegate:self];
    
    return request;
}

@end
