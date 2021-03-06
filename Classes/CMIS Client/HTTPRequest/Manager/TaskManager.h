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
//  TaskManager.h
//

#import <Foundation/Foundation.h>
#import "CMISServiceManager.h"
#import "TaskItem.h"

@class TaskManager;
@class ASIHTTPRequest;

extern NSString * const kTaskManagerErrorDomain;

/**
 * As a Delegate, this singleton will report the finish or fail for *all* the task requests
 * only if all of the task request fail, the taskManagerRequestFailed: method will be called
 * in the delegate. The failed task requests will be ignored and a success will be reported.
 */
@protocol TaskManagerDelegate <NSObject>

@optional
- (void)taskManager:(TaskManager *)taskManager requestFinished:(NSArray *)tasks;
- (void)itemRequestFinished:(NSArray *)taskItems;
- (void)taskManagerRequestFailed:(TaskManager *)taskManager;

@end

/*
 * Task sync type, either manually initiated or done automatically
 */
typedef enum {
    TasksSyncTypeAutomatic,
    TasksSyncTypeManual
} TasksSyncType;

@interface TaskManager : NSObject <CMISServiceManagerListener>

@property (nonatomic, retain) ASINetworkQueue *tasksQueue;
@property (nonatomic, retain) NSError *error;

@property (nonatomic, assign) id<TaskManagerDelegate> delegate;

/**
 * This method will queue and start the my tasks request for all the configured 
 * accounts.
 */
- (void)startMyTasksRequest:(TasksSyncType)syncType;

/**
 * This method will queue and start the task initiator request for all the configured 
 * accounts.
 */
- (void)startInitiatorTasksRequest:(TasksSyncType)syncType;

/**
 * This method will fire 2 REST calls to retrieve the task item details
 */
- (void)startTaskItemRequestForTaskId:(NSString *)taskId accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;

/**
 * Starts a request to create the task with the provided details.
 */
- (void)startTaskCreateRequestForTask:(TaskItem *)task
                            assignees:(NSArray *)assignees
                          accountUUID:(NSString *)uuid
                             tenantID:(NSString *)tenantID
                             delegate:(id<ASIHTTPRequestDelegate>)delegate;

/**
 * Starts a request to update the task with the provided details.
 */
- (void)startTaskUpdateRequestForTask:(TaskItem *)task 
                          accountUUID:(NSString *)uuid 
                             tenantID:(NSString *)tenantID 
                             delegate:(id<ASIHTTPRequestDelegate>)delegate;

/**
 * Log whether a repository attached to an account supports Activiti or not
 */
- (void)enableActivitiForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID enabled:(BOOL)enabled;

/**
 * Returns the shared singleton
 */
+ (TaskManager *)sharedManager;

@end
