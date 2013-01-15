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
//  MyTaskListHTTPRequest.m
//

#import "MyTaskListHTTPRequest.h"

@interface MyTaskListHTTPRequest () // Private
@property (nonatomic, readwrite, retain) NSArray *tasks;
@end

@implementation MyTaskListHTTPRequest

@synthesize tasks = _tasks;

- (void) dealloc
{
	[_tasks release];
	[super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
    // parse the returned JSON
    NSDictionary *responseJSONObject = [self dictionaryFromJSONResponse];
    NSArray *taskJSONArray = [responseJSONObject objectForKey:@"data"];

    NSArray *workflowTypes = [NSArray arrayWithObjects:@"wf:adhocTask", @"wf:completedAdhocTask",
                         @"wf:activitiReviewTask", @"wf:approvedTask", @"wf:rejectedTask", @"wf:reviewTask", @"wf:approvedParallelTask", @"wf:rejectedParallelTask", nil];
    NSMutableArray *resultArray = [NSMutableArray array];

    // Adding account uuid and tenantID to the response, as the consumers of the data will need it
    for (id taskJson in taskJSONArray)
    {
        NSString *workflowType = [taskJson valueForKey:@"name"];
        if ([workflowTypes containsObject:workflowType])
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
    
	[self setTasks:resultArray];
}

+ (MyTaskListHTTPRequest *)taskRequestForAllTasksWithAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    MyTaskListHTTPRequest *request = [MyTaskListHTTPRequest requestForServerAPI:kServerAPIMyTaskCollection accountUUID:uuid tenantID:tenantID];
    [request setRequestMethod:@"GET"];
    
    return request;
}

@end
