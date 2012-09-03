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
//  TaskUpdateHTTPRequest.m
//

#import "TaskUpdateHTTPRequest.h"
#import "SBJSON.h"

@implementation TaskUpdateHTTPRequest

- (void)requestFinishedWithSuccessResponse
{
	// create a JSON parser
	SBJSON *jsonObj = [SBJSON new];
    
    // parse the returned string
    NSDictionary *responseJSONObject = [jsonObj objectWithString:[self responseString]];
    NSLog(@"response %@", responseJSONObject);
    [jsonObj release];
}

+ (TaskUpdateHTTPRequest *)taskUpdateRequestForTask:(TaskItem *)task accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:task.taskId forKey:@"TASKID"];
    
    TaskUpdateHTTPRequest *request = [TaskUpdateHTTPRequest requestForServerAPI:kServerAPITaskUpdate accountUUID:uuid tenantID:tenantID infoDictionary:infoDictionary];
    request.accountUUID = uuid;
    request.tenantID = tenantID;
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithCapacity:1];
    [postDict setValue:task.ownerUserName forKey:@"cm_owner"];
        
    SBJSON *jsonObj = [[SBJSON new] autorelease];
    NSString *postBody = [jsonObj stringWithObject:postDict];
    NSMutableData *postData = [NSMutableData dataWithData:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    [request setPostBody:postData];
    
    [request setRequestMethod:@"PUT"];
    [request setContentLength:[postData length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    
    return request;
}

@end
