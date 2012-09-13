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
#import "SBJSON.h"
#import "RepositoryItem.h"
#import "AccountManager.h"

@implementation SiteJoinHTTPRequest

+ (SiteJoinHTTPRequest *)httpRequestToJoinSite:(NSString *)siteName withAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:siteName forKey:@"SITEID"];
    
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:uuid];
    
    NSDictionary *postParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"SiteConsumer", @"role",
                                    [NSDictionary dictionaryWithObject:accountInfo.username forKey:@"userName"], @"person",
                                    nil];
    
    SBJSON *jsonObj = [[SBJSON new] autorelease];
    NSString *postBody = [jsonObj stringWithObject:postParameters];
    
    SiteJoinHTTPRequest *request = [SiteJoinHTTPRequest requestForServerAPI:kServerAPISiteJoin accountUUID:uuid tenantID:tenantID infoDictionary:infoDictionary];
    [request setPostBody:[NSMutableData dataWithData:[postBody dataUsingEncoding:NSUTF8StringEncoding]]];
    [request setContentLength:[postBody length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setRequestMethod:@"PUT"];
    
    return request;
}

@end
