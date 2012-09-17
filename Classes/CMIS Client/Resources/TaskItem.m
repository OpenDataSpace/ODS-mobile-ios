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
//  TaskItem.m
//

#import "TaskItem.h"
#import "Utility.h"

@implementation TaskItem

@synthesize taskId = _taskId;
@synthesize name = _name;
@synthesize title = _title;
@synthesize description = _description;
@synthesize taskItemType = _taskItemType;
@synthesize workflowType = _workflowType;
@synthesize state = _state;
@synthesize initiatorUserName = _initiatorUserName;
@synthesize ownerUserName = _owner;
@synthesize startDate = _startDate;
@synthesize dueDate = _dueDate;
@synthesize priorityInt = _priorityInt;
@synthesize priority = _priority;
@synthesize emailNotification = _emailNotification;
@synthesize approvalPercentage = _approvalPercentage;
@synthesize ownerFullName = _ownerFullName;
@synthesize documentItems = _documentItems;
@synthesize accountUUID = _accountUUID;
@synthesize tenantId = _tenantId;
@synthesize taskType = _taskType;
@synthesize comment = _comment;
@synthesize completionDate = _completionDate;
@synthesize outcome = _outcome;
@synthesize message = _message;
@synthesize initiatorFullName = _initiatorFullName;


- (void)dealloc
{
    [_taskId release];
	[_name release];
	[_title release];
	[_description release];
    [_state release];
    [_initiatorUserName release];
    [_owner release];
    [_startDate release];
    [_dueDate release];
    [_priority release];
    [_documentItems release];
    [_ownerFullName release];
    [_accountUUID release];
    [_tenantId release];
    [_comment release];
    [_completionDate release];
    [_outcome release];
    [_message release];
    [_initiatorFullName release];
    [super dealloc];
}

- (TaskItem *)initWithMyTaskJsonDictionary:(NSDictionary *)json
{
    self = [self initWithCommonTaskJsonDictionary:json];
    
    if(self)
    {
        [self setTaskItemType:TASKITEM_TYPE_MYTASKS];
        [self setDescription:[json valueForKeyPath:@"properties.bpm_description"]];
        
        [self setStartDate:dateFromIso([json valueForKeyPath:@"properties.bpm_startDate"])];

        if ([[json valueForKeyPath:@"properties.bpm_dueDate"] class] != [NSNull class])
        {
            [self setDueDate:dateFromIso([json valueForKeyPath:@"properties.bpm_dueDate"])];
        }

        if ([[json valueForKeyPath:@"properties.bpm_completionDate"] class] != [NSNull class])
        {
            [self setCompletionDate:dateFromIso([json valueForKeyPath:@"properties.bpm_completionDate"])];
        }
        
        // Workflow Type
        
        // todo types @"wf:adhocTask", @"wf:completedAdhocTask
        NSArray *reviewWorkflows = [NSArray arrayWithObjects:@"wf:activitiReviewTask", @"wf:approvedTask", @"wf:rejectedTask", 
                                    @"wf:reviewTask", @"wf:approvedParallelTask", @"wf:rejectedParallelTask", nil];
        NSString *name = [json valueForKey:@"name"];
        if ([reviewWorkflows containsObject:name])
        {
            [self setWorkflowType:WORKFLOW_TYPE_REVIEW];
        }
        else 
        {
            [self setWorkflowType:WORKFLOW_TYPE_TODO];
        }
        
        // Task type
        if ([name isEqualToString:@"wf:activitiReviewTask"])
        {
            [self setTaskType:TASK_TYPE_REVIEW];
        }
        else
        {
            [self setTaskType:TASK_TYPE_DEFAULT];
        }

        [self setPriorityInt:[[json valueForKeyPath:@"properties.bpm_priority"] intValue]];
        [self setPriority:[json valueForKeyPath:@"propertyLabels.bpm_priority"]];
        [self setOwnerUserName:[json valueForKeyPath:@"owner.userName"]];
        [self setOwnerFullName:[NSString stringWithFormat:@"%@ %@", [json valueForKeyPath:@"owner.firstName"], [json valueForKeyPath:@"owner.lastName"]]];
        [self setInitiatorUserName:[json valueForKeyPath:@"workflowInstance.initiator.userName"]];
        [self setInitiatorFullName:[NSString stringWithFormat:@"%@ %@", [json valueForKeyPath:@"workflowInstance.initiator.firstName"], [json valueForKeyPath:@"workflowInstance.initiator.lastName"]]];
    }
    
    return self;
}

- (TaskItem *)initWithStartedByMeTaskJsonDictionary:(NSDictionary *)json
{
    self = [self initWithCommonTaskJsonDictionary:json];
    
    if(self)
    {
        [self setTaskItemType:TASKITEM_TYPE_STARTEDBYME];
        [self setDescription:[json valueForKeyPath:@"description"]];
        
        [self setStartDate:dateFromIso([json valueForKeyPath:@"startDate"])];
        
        if ([[json valueForKeyPath:@"dueDate"] class] != [NSNull class])
        {
            [self setDueDate:dateFromIso([json valueForKeyPath:@"dueDate"])];
        }

        if ([[json valueForKey:@"message"] class] != [NSNull class])
        {
            [self setMessage:[json valueForKey:@"message"]];
        }

        NSArray *reviewWorkflows = [NSArray arrayWithObjects:@"activiti$activitiReview", @"activiti$activitiParallelReview", nil];
        NSString *name = [json valueForKey:@"name"];
        if ([reviewWorkflows containsObject:name])
        {
            [self setWorkflowType:WORKFLOW_TYPE_REVIEW];
            [self setTaskType:TASK_TYPE_REVIEW];
        }
        else 
        {
            [self setWorkflowType:WORKFLOW_TYPE_TODO];
            [self setTaskType:TASK_TYPE_DEFAULT];
        }
        
        [self setPriorityInt:[[json valueForKeyPath:@"priority"] intValue]];
        [self setOwnerUserName:[json valueForKeyPath:@"initiator.userName"]];
        [self setOwnerFullName:[NSString stringWithFormat:@"%@ %@", [json valueForKeyPath:@"initiator.firstName"], [json valueForKeyPath:@"initiator.lastName"]]];
    }
    return self;
}

- (TaskItem *)initWithCommonTaskJsonDictionary:(NSDictionary *)json
{
    self = [super init];
    
    if(self)
    {
        [self setTaskId:[json valueForKey:@"id"]];
        [self setName:[json valueForKey:@"name"]];
        [self setTitle:[json valueForKey:@"title"]];

        if ([[json valueForKeyPath:@"properties.bpm_comment"] class]!= [NSNull class])
        {
            [self setComment:[json valueForKeyPath:@"properties.bpm_comment"]];
        }

        if ([[json valueForKeyPath:@"properties.bpm_outcome"] class] != [NSNull class])
        {
            [self setOutcome:[json valueForKeyPath:@"properties.bpm_outcome"]];
        }
        
        [self setAccountUUID:[json valueForKey:@"accountUUID"]];
        [self setTenantId:[json valueForKey:@"tenantId"]];
    }
    
    return self;
}

@end
