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
//  TaskListHTTPRequest.m
//

#import "TaskListHTTPRequest.h"
#import "SBJSON.h"
#import "TaskItem.h"

@interface TaskListHTTPRequest () // Private
@property (nonatomic, readwrite, retain) NSArray *tasks;
@end

@implementation TaskListHTTPRequest

@synthesize tasks = _tasks;

- (void) dealloc
{
	[_tasks release];
	[super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
	// create a JSON parser
	SBJSON *jsonObj = [SBJSON new];
    
    // parse the returned string
    NSDictionary *responseJSONObject = [jsonObj objectWithString:[self responseString]];
    NSArray *taskJSONArray = [responseJSONObject objectForKey:@"data"];

    NSArray *taskTypes = [NSArray arrayWithObjects:@"wf:adhocTask", @"wf:completedAdhocTask",
                         @"wf:activitiReviewTask", @"wf:approvedTask", @"wf:rejectedTask", @"wf:reviewTask", nil];
    NSMutableArray *resultArray = [NSMutableArray array];
    // Adding account uuid and tenantID to the response, as the consumers of the data will need it
    for (id taskJson in taskJSONArray)
    {
        NSString *taskType = [taskJson valueForKey:@"name"];
        if ([taskTypes containsObject:taskType])
        {
            if (self.accountUUID)
            {
                [taskJson setObject:self.accountUUID forKey:@"accountUUID"];
            }
            if (self.tenantID)
            {
                [taskJson setObject:self.tenantID forKey:@"tenantId"];
            }
            [resultArray addObject:taskJson];
        }
    }
    
#if MOBILE_DEBUG
    NSLog(@"Tasks: %@", resultArray);
#endif
    
    [jsonObj release];
    
	[self setTasks:resultArray];
}

+ (TaskListHTTPRequest *)taskRequestForAllTasksWithAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    TaskListHTTPRequest *request = [TaskListHTTPRequest requestForServerAPI:kServerAPITaskCollection accountUUID:uuid tenantID:tenantID];
    [request setRequestMethod:@"GET"];
    
    return request;
}

@end
