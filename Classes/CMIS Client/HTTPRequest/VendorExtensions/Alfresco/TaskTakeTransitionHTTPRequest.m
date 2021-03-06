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
// TaskTakeTransitionHTTPRequest 
//
#import "TaskTakeTransitionHTTPRequest.h"
#import "TaskItem.h"

@implementation TaskTakeTransitionHTTPRequest

+ (TaskTakeTransitionHTTPRequest *)taskTakeTransitionRequestForTask:(TaskItem *)task outcome:(NSString *)outcome
                                 comment:(NSString *)comment accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    // Construct request
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:task.taskId forKey:@"TASKID"];
    TaskTakeTransitionHTTPRequest *request = [TaskTakeTransitionHTTPRequest requestForServerAPI:kServerAPITaskTakeTransition
                                                   accountUUID:uuid tenantID:tenantID infoDictionary:infoDictionary];
    request.accountUUID = uuid;
    request.tenantID = tenantID;

    // Construct json body
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    
    if ([task.taskId hasPrefix:@"activiti$"])
    {
        // Activiti transitions
        [postDict setValue:@"Next" forKey:@"prop_transitions"];
    }
    else
    {
        // JBPM transitions
        if (outcome)
        {
            [postDict setValue:[outcome lowercaseString] forKey:@"prop_transitions"];
        }
        else
        {
            [postDict setValue:@"" forKey:@"prop_transitions"];
        }
    }
    
    [postDict setValue:@"Completed" forKey:@"prop_bpm_status"];

    if (outcome)
    {
        [postDict setValue:outcome forKey:@"prop_wf_reviewOutcome"];
    }

    if (comment && comment.length > 0)
    {
        [postDict setValue:comment forKey:@"prop_bpm_comment"];
    }

    [request setPostBody:[request mutableDataFromJSONObject:postDict]];
    [request setContentLength:[request.postBody length]];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];

    return request;
}

@end
