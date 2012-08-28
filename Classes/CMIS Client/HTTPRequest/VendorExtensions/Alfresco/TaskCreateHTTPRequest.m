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
//  TaskCreateHTTPRequest.m
//

#import "TaskCreateHTTPRequest.h"
#import "SBJSON.h"
#import "DocumentItem.h"

@implementation TaskCreateHTTPRequest

- (void)requestFinishedWithSuccessResponse
{
	// create a JSON parser
	SBJSON *jsonObj = [SBJSON new];
    
    // parse the returned string
    NSDictionary *responseJSONObject = [jsonObj objectWithString:[self responseString]];
    NSLog(@"response %@", responseJSONObject);
}

+ (TaskCreateHTTPRequest *)taskCreateRequestForTask:(TaskItem *)task assigneeNodeRef:(NSString *)assigneeNodeRef
                                        accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *infoDictionary;
    if (task.taskType == TASK_TYPE_TODO)
    {
        infoDictionary = [NSDictionary dictionaryWithObject:@"activiti$activitiAdhoc" forKey:@"WORKFLOWNAME"];
    }
    else 
    {
        infoDictionary = [NSDictionary dictionaryWithObject:@"activiti$activitiReview" forKey:@"WORKFLOWNAME"];
    }
    
    TaskCreateHTTPRequest *request = [TaskCreateHTTPRequest requestForServerAPI:kServerAPITaskCreate accountUUID:uuid tenantID:tenantID infoDictionary:infoDictionary];
    request.accountUUID = uuid;
    request.tenantID = tenantID;
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    [postDict setValue:task.title forKey:@"prop_bpm_workflowDescription"];
    [postDict setValue:assigneeNodeRef forKey:@"assoc_bpm_assignee_added"];
    
    if (task.documentItems && task.documentItems.count > 1)
    {
        NSString *documentsAdded;
        for (DocumentItem *document in task.documentItems) {
            if (!documentsAdded || documentsAdded.length == 0)
            {
                documentsAdded = [NSString stringWithString:document.nodeRef];
            }
            else 
            {
                documentsAdded = [NSString stringWithFormat:@"%@,%@", documentsAdded, document.nodeRef];
            }
        }
        [postDict setValue:documentsAdded forKey:@"assoc_packageItems_added"];
    }
    
    SBJSON *jsonObj = [[SBJSON new] autorelease];
    NSString *postBody = [jsonObj stringWithObject:postDict];
    NSMutableData *postData = [NSMutableData dataWithData:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    [request setPostBody:postData];
    
    [request setRequestMethod:@"POST"];
    [request setContentLength:[postData length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    
    return request;
}

@end
