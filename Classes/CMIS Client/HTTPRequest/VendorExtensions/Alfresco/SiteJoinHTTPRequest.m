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
//  SiteJoinHTTPRequest.m
//

#import "SiteJoinHTTPRequest.h"
#import "AccountManager.h"
#import "RepositoryServices.h"
#import "RepositoryInfo.h"

@implementation SiteJoinHTTPRequest

+ (SiteJoinHTTPRequest *)httpRequestToJoinSite:(NSString *)siteName withAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:siteName forKey:@"SITEID"];
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:uuid];
    NSDictionary *postParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"SiteConsumer", @"role",
                                    [NSDictionary dictionaryWithObject:accountInfo.username forKey:@"userName"], @"person",
                                    nil];
    
    /**
     * Due to a breaking API change between 3.4 and 4.0, we need to know which version of the Join request to use
     */
    NSString *serverAPI = kServerAPISiteJoin;
    RepositoryInfo *repositoryInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:uuid tenantID:tenantID];
    if (repositoryInfo && [repositoryInfo.productVersion integerValue] < 4)
    {
        // We can re-use the Leave URL for 3.4 servers, which has the required format
        serverAPI = kServerAPISiteLeave;
    }
        
    SiteJoinHTTPRequest *request = [SiteJoinHTTPRequest requestForServerAPI:serverAPI accountUUID:uuid tenantID:tenantID infoDictionary:infoDictionary];
    [request setPostBody:[request mutableDataFromJSONObject:postParameters]];
    [request setContentLength:[request.postBody length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setRequestMethod:@"PUT"];
    
    return request;
}

@end
