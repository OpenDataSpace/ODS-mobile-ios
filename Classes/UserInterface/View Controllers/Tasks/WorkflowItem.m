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
// WorkflowItem 
//
#import "WorkflowItem.h"
#import "Utility.h"


@implementation WorkflowItem

@synthesize id = _id;
@synthesize name = _name;
@synthesize title = _title;
@synthesize description = _description;
@synthesize message = _message;
@synthesize startDate = _startDate;
@synthesize dueDate = _dueDate;
@synthesize priority = _priority;
@synthesize initiatorUserName = _initiatorUserName;
@synthesize initiatorFullName = _initiatorFullName;
@synthesize tasks = _tasks;
@synthesize accountUUID = _accountUUID;
@synthesize tenantId = _tenantId;
@synthesize documents = _documents;
@synthesize workflowType = _workflowType;
@synthesize startTask = _startTask;


- (void)dealloc
{
    [_id release];
    [_name release];
    [_title release];
    [_description release];
    [_message release];
    [_startDate release];
    [_dueDate release];
    [_initiatorUserName release];
    [_initiatorFullName release];
    [_tasks release];
    [_accountUUID release];
    [_tenantId release];
    [_documents release];
    [_startTask release];
    [super dealloc];
}

- (id)initWithJsonDictionary:(NSDictionary *)jsonDictionary
{
    self = [super init];
    if (self)
    {
        self.id = [jsonDictionary valueForKey:@"id"];
        self.name = [jsonDictionary valueForKey:@"name"];
        self.title = [jsonDictionary valueForKey:@"title"];
        self.description = [jsonDictionary valueForKey:@"description"];
        self.message = [jsonDictionary valueForKey:@"message"];

        NSArray *reviewWorkflows = [NSArray arrayWithObjects:@"activiti$activitiReview", @"activiti$activitiParallelReview", @"jbpm$wf:review", @"jbpm$wf:parallelreview", nil];
        NSString *name = [jsonDictionary valueForKey:@"name"];
        if ([reviewWorkflows containsObject:name])
        {
            [self setWorkflowType:AlfrescoWorkflowTypeReview];
        }
        else
        {
            [self setWorkflowType:AlfrescoWorkflowTypeTodo];
        }

        NSString *startDateString = [jsonDictionary valueForKey:@"startDate"];
        if (startDateString != nil && startDateString != NULL && [startDateString class] != [NSNull class])
        {
            self.startDate = dateFromIso(startDateString);
        }

        NSString *dueDateString = [jsonDictionary valueForKey:@"dueDate"];
        if (dueDateString != nil && dueDateString != NULL && [dueDateString class] != [NSNull class])
        {
            self.dueDate = dateFromIso(dueDateString);
        }

        self.priority = [[jsonDictionary valueForKey:@"priority"] intValue];
        self.initiatorUserName = [jsonDictionary valueForKeyPath:@"initiator.userName"];
        self.initiatorFullName = [NSString stringWithFormat:@"%@ %@", [jsonDictionary valueForKeyPath:@"initiator.firstName"],
                        [jsonDictionary valueForKeyPath:@"initiator.lastName"]];

        NSString *startTaskInstanceId = [jsonDictionary valueForKey:@"startTaskInstanceId"];

        NSArray *tasksJson = [jsonDictionary valueForKey:@"tasks"];
        NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:tasksJson.count];

        if (tasksJson && tasksJson.count > 0)
        {
            for (int i = tasksJson.count - 1; i >= 0; i--) // tasks are returned by creation date, but we use them in the other way always
            {
                TaskItem *taskItem = [[TaskItem alloc] initWithMyTaskJsonDictionary:[tasksJson objectAtIndex:i]];
                if ([taskItem.taskId isEqualToString:startTaskInstanceId])
                {
                    self.startTask = taskItem;
                }
                else
                {
                    [tasks addObject:taskItem];
                }

                [taskItem release];
            }
        }
        self.tasks = tasks;
    }
    return self;
}


@end
