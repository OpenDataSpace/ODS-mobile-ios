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
// WorkflowDetailsHTTPRequest 
//
#import "WorkflowDetailsHTTPRequest.h"
#import "WorkflowItem.h"
#import "JSON.h"

@interface WorkflowDetailsHTTPRequest ()

@property (nonatomic, readwrite, retain) WorkflowItem *workflowItem;

@end


@implementation WorkflowDetailsHTTPRequest
@synthesize workflowItem = _workflowItem;

- (void)dealloc
{
    [_workflowItem release];
    [super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
	SBJSON *jsonObj = [SBJSON new];

    NSDictionary *responseJSONObject = [jsonObj objectWithString:[self responseString]];
    NSDictionary *workflowDictionary = [responseJSONObject objectForKey:@"data"];
    WorkflowItem * workflowItem = [[WorkflowItem alloc] initWithJsonDictionary:workflowDictionary];
    self.workflowItem = workflowItem;
    [workflowItem release];

    self.workflowItem.accountUUID = self.accountUUID;
    self.workflowItem.tenantId = self.tenantID;

    [jsonObj release];
}

+ (WorkflowDetailsHTTPRequest *)workflowDetailsRequestForWorkflow:(NSString *)workflowId accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:workflowId forKey:@"WORKFLOWID"];
    WorkflowDetailsHTTPRequest *request = [WorkflowDetailsHTTPRequest requestForServerAPI:kServerAPIWorkflowInstance
                                                              accountUUID:uuid tenantID:tenantID infoDictionary:infoDict];
    [request setRequestMethod:@"GET"];
    return request;
}

@end
