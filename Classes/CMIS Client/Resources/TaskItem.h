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
//  TaskItem.h
//
// Representation of task information.
//

#import <Foundation/Foundation.h>

typedef enum {
    TASKITEM_TYPE_MYTASKS = 1,
    TASKITEM_TYPE_STARTEDBYME
} TaskItemType;

typedef enum {
    WORKFLOW_TYPE_TODO = 1,
    WORKFLOW_TYPE_REVIEW
} AlfrescoWorkflowType;

typedef enum {
    TASK_TYPE_DEFAULT, // normal task, a regular 'task done' button is enough
    TASK_TYPE_REVIEW // needs special care, eg showing 'approve' and 'reject' buttons
} AlfrescoTaskType;

@interface TaskItem : NSObject

@property (nonatomic, retain) NSString *taskId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *message;

@property (nonatomic) AlfrescoWorkflowType workflowType;
@property (nonatomic) AlfrescoTaskType taskType;
@property (nonatomic) TaskItemType taskItemType;

@property (nonatomic, retain) NSString *initiator;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *ownerUserName;
@property (nonatomic, retain) NSString *ownerFullName;

@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *dueDate;
@property (nonatomic, retain) NSDate *completionDate;

@property (nonatomic) int priorityInt;
@property (nonatomic, retain) NSString *priority;
@property (nonatomic) BOOL emailNotification;
@property (nonatomic) int approvalPercentage;

@property (nonatomic, retain) NSString *outcome;
@property (nonatomic, retain) NSString *comment;

@property (nonatomic, retain) NSArray *documentItems;

@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) NSString *tenantId;

- (TaskItem *)initWithMyTaskJsonDictionary:(NSDictionary *)json;

- (TaskItem *)initWithStartedByMeTaskJsonDictionary:(NSDictionary *)json;

@end
