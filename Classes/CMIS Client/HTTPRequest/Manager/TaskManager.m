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
//  TaskManager.m
//

#import "TaskManager.h"
#import "AccountManager.h"
#import "AccountInfo.h"
#import "RepositoryServices.h"
#import "RepositoryInfo.h"
#import "Utility.h"
#import "MyTaskListHTTPRequest.h"
#import "StartedByMeTaskListHTTPRequest.h"
#import "TaskItemListHTTPRequest.h"
#import "TaskItemDetailsHTTPRequest.h"
#import "TaskCreateHTTPRequest.h"
#import "PeopleManager.h"
#import "ASIHTTPRequest.h"
#import "TaskUpdateHTTPRequest.h"
#import "Person.h"

NSString * const kTaskManagerErrorDomain = @"TaskManagerErrorDomain";

static NSString *MY_TASKS = @"mytasks";
static NSString *TASKS_STARTED_BY_ME = @"tasksstartedbyme";

@interface TaskManager ()
{
    NSInteger requestCount;
    NSInteger requestsFailed;
    NSInteger requestsFinished;
    
    BOOL showOfflineAlert;
    BOOL loadedRepositoryInfos;
}

@property (nonatomic, retain) TaskItemListHTTPRequest *taskItemsRequest;
@property (nonatomic, retain) TaskItemDetailsHTTPRequest *taskItemDetailsrequest;
@property (nonatomic, retain) TaskCreateHTTPRequest *taskCreateRequest;
@property (nonatomic, retain) TaskUpdateHTTPRequest *taskUpdateRequest;
@property (atomic, readonly) NSMutableArray *tasks;
@property (nonatomic, retain) NSString *taskFilter;

- (void)loadTasks;

@end

@implementation TaskManager

@synthesize tasksQueue = _tasksQueue;
@synthesize error = _error;
@synthesize delegate = _delegate;

// Private
@synthesize taskItemsRequest = _taskItemsRequest;
@synthesize taskItemDetailsrequest = _taskItemDetailsrequest;
@synthesize taskCreateRequest = _taskCreateRequest;
@synthesize taskUpdateRequest = _taskUpdateRequest;
@synthesize tasks = _tasks;
@synthesize taskFilter = _taskFilter;

- (void)dealloc 
{
    [_taskItemsRequest release];
    [_taskItemDetailsrequest release];
    [_taskCreateRequest release];
    [_taskUpdateRequest release];
    [_tasks release];
    [_taskFilter release];
    
    [_tasksQueue cancelAllOperations];
    [_tasksQueue release];
    [_error release];
    
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
    {
        _tasks = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)loadRepositoryInfo
{
    [[CMISServiceManager sharedManager] addQueueListener:self];
    //If the cmisservicemanager is running we need to wait for it to finish, and then load the requests
    //since it may be requesting only the accounts with credentials, we need it to load all accounts
    if(![[CMISServiceManager sharedManager] isActive])
    {
        loadedRepositoryInfos = YES;
        [[CMISServiceManager sharedManager] loadAllServiceDocuments];
    }
}

- (void)loadTasks
{
    static NSString *KeyPath = @"tenantID";
    if(!self.tasksQueue || [self.tasksQueue requestsCount] == 0) 
    {
        RepositoryServices *repoService = [RepositoryServices shared];
        NSArray *accounts = [[AccountManager sharedManager] activeAccounts];
        [self setTasksQueue:[ASINetworkQueue queue]];
        
        for(AccountInfo *account in accounts) 
        {
            if([[account vendor] isEqualToString:kFDAlfresco_RepositoryVendorName] && 
               [repoService getRepositoryInfoArrayForAccountUUID:account.uuid]) 
            {
                if (![account isMultitenant])
                {
                    BaseHTTPRequest *request;
                    if ([self.taskFilter isEqualToString:MY_TASKS])
                    {
                        request = [MyTaskListHTTPRequest taskRequestForAllTasksWithAccountUUID:[account uuid] tenantID:nil];
                    }
                    else
                    {
                        request = [StartedByMeTaskListHTTPRequest taskRequestForTasksStartedByMeWithAccountUUID:[account uuid] tenantID:nil];
                    }
                    [request setShouldContinueWhenAppEntersBackground:YES];
                    [request setSuppressAllErrors:YES];
                    [self.tasksQueue addOperation:request];
                } 
                else
                {
                    NSArray *repos = [repoService getRepositoryInfoArrayForAccountUUID:account.uuid];
                    NSArray *tenantIDs = [repos valueForKeyPath:KeyPath];
                    
                    //For cloud accounts, there is one activities request for each tenant the cloud account contains
                    for (NSString *anID in tenantIDs) 
                    {
                        BaseHTTPRequest *request;
                        if ([self.taskFilter isEqualToString:MY_TASKS])
                        {
                            request = [MyTaskListHTTPRequest taskRequestForAllTasksWithAccountUUID:[account uuid] tenantID:anID];
                        }
                        else
                        {
                            request = [StartedByMeTaskListHTTPRequest taskRequestForTasksStartedByMeWithAccountUUID:[account uuid] tenantID:anID];
                        }
                        [request setShouldContinueWhenAppEntersBackground:YES];
                        [request setSuppressAllErrors:YES];
                        [self.tasksQueue addOperation:request];
                    }
                }
            }
        }
        
        if([self.tasksQueue requestsCount] > 0)
        {
            requestCount = [self.tasksQueue requestsCount];
            requestsFailed = 0;
            requestsFinished = 0;
            
            [self.tasks removeAllObjects];
            
            //setup of the queue
            [self.tasksQueue setDelegate:self];
            [self.tasksQueue setShowAccurateProgress:NO];
            [self.tasksQueue setShouldCancelAllRequestsOnFailure:NO];
            [self.tasksQueue setRequestDidFailSelector:@selector(requestFailed:)];
            [self.tasksQueue setRequestDidFinishSelector:@selector(requestFinished:)];
            [self.tasksQueue setQueueDidFinishSelector:@selector(queueFinished:)];
            
            showOfflineAlert = YES;
            [self.tasksQueue go];
        }
        else
        {
            // There is no account/alfresco account configured or there's a cloud account with no tenants
            NSString *description = @"There was no request to process";
            [self setError:[NSError errorWithDomain:kTaskManagerErrorDomain code:0 
                                           userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(taskManagerRequestFailed:)])
            {
                [self.delegate taskManagerRequestFailed:self];
                self.delegate = nil;
            }
        }
    }
    
}

- (void)startMyTasksRequest 
{
    self.taskFilter = MY_TASKS;
    RepositoryServices *repoService = [RepositoryServices shared];
    NSArray *accounts = [[AccountManager sharedManager] activeAccounts];
    //We have to make sure the repository info are loaded before requesting the activities
    for(AccountInfo *account in accounts) 
    {
        if(![repoService getRepositoryInfoArrayForAccountUUID:account.uuid])
        {
            loadedRepositoryInfos = NO;
            [self loadRepositoryInfo];
            return;
        }
    }
    [self loadTasks];
}

- (void)startInitiatorTasksRequest
{
    self.taskFilter = TASKS_STARTED_BY_ME;
    RepositoryServices *repoService = [RepositoryServices shared];
    NSArray *accounts = [[AccountManager sharedManager] activeAccounts];
    //We have to make sure the repository info are loaded before requesting the activities
    for(AccountInfo *account in accounts) 
    {
        if(![repoService getRepositoryInfoArrayForAccountUUID:account.uuid])
        {
            loadedRepositoryInfos = NO;
            [self loadRepositoryInfo];
            return;
        }
    }
    [self loadTasks];
}

- (void)startTaskItemRequestForTaskId:(NSString *)taskId accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self.taskItemsRequest = [TaskItemListHTTPRequest taskItemRequestForTaskId:taskId accountUUID:uuid tenantID:tenantID];
    [self.taskItemsRequest setShouldContinueWhenAppEntersBackground:YES];
    [self.taskItemsRequest setSuppressAllErrors:YES];
    [self.taskItemsRequest setDelegate:self];
    
    requestsFailed = 0;
    requestsFinished = 0;
    
    [self.taskItemsRequest startAsynchronous];
}

- (void)startTaskCreateRequestForTask:(TaskItem *)task assignees:(NSArray *)assignees accountUUID:(NSString *)uuid 
                             tenantID:(NSString *)tenantID delegate:(id<ASIHTTPRequestDelegate>)delegate
{
    NSMutableArray *assigneeNodeRefs = [NSMutableArray arrayWithCapacity:assignees.count];
    for (Person *person in assignees) {
        NSString *assigneeNodeRef = [[PeopleManager sharedManager] getPersonNodeRefSearchWithUsername:person.userName accountUUID:uuid tenantID:tenantID];
        [assigneeNodeRefs addObject:assigneeNodeRef];
    }
    
    NSArray *assigneeArray = [NSArray arrayWithArray:assigneeNodeRefs];
    
    self.taskCreateRequest = [TaskCreateHTTPRequest taskCreateRequestForTask:task assigneeNodeRefs:assigneeArray
                                                                 accountUUID:uuid tenantID:tenantID];
    [self.taskCreateRequest setShouldContinueWhenAppEntersBackground:YES];
    [self.taskCreateRequest setSuppressAllErrors:YES];
    [self.taskCreateRequest setDelegate:delegate];
    
    requestsFailed = 0;
    requestsFinished = 0;
    
    [self.taskCreateRequest startAsynchronous];
}

- (void)startTaskUpdateRequestForTask:(TaskItem *)task accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID delegate:(id<ASIHTTPRequestDelegate>)delegate
{
    self.taskUpdateRequest = [TaskUpdateHTTPRequest taskUpdateRequestForTask:task accountUUID:uuid tenantID:tenantID];
    [self.taskUpdateRequest setShouldContinueWhenAppEntersBackground:YES];
    [self.taskUpdateRequest setSuppressAllErrors:YES];
    [self.taskUpdateRequest setDelegate:delegate];
    
    requestsFailed = 0;
    requestsFinished = 0;
    
    [self.taskUpdateRequest startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request 
{
    if ([request class] == [MyTaskListHTTPRequest class])
    {
        requestsFinished++;
        MyTaskListHTTPRequest *tasksRequest = (MyTaskListHTTPRequest *)request;
        [self.tasks addObjectsFromArray:tasksRequest.tasks];
    }
    else if ([request class] == [StartedByMeTaskListHTTPRequest class])
    {
        requestsFinished++;
        StartedByMeTaskListHTTPRequest *tasksRequest = (StartedByMeTaskListHTTPRequest *)request;
        [self.tasks addObjectsFromArray:tasksRequest.tasks];
    }
    else if (self.taskItemsRequest && [request isEqual:self.taskItemsRequest])
    {
        if (self.taskItemsRequest.taskItems.count > 0)
        {
            self.taskItemDetailsrequest = [TaskItemDetailsHTTPRequest taskItemDetailsRequestForItems:self.taskItemsRequest.taskItems 
                                                                                                 accountUUID:self.taskItemsRequest.accountUUID 
                                                                                                    tenantID:self.taskItemsRequest.tenantID];
            [self.taskItemDetailsrequest setShouldContinueWhenAppEntersBackground:YES];
            [self.taskItemDetailsrequest setSuppressAllErrors:YES];
            [self.taskItemDetailsrequest setDelegate:self];
            
            requestsFailed = 0;
            requestsFinished = 0;
            
            [self.taskItemDetailsrequest startAsynchronous];
            
            self.taskItemsRequest = nil;
        }
        else 
        {
            if(self.delegate && [self.delegate respondsToSelector:@selector(itemRequestFinished:)])
            {
                [self.delegate itemRequestFinished:self.taskItemsRequest.taskItems];
                self.delegate = nil;
            }
        }
    }
    else if (self.taskItemDetailsrequest && [request isEqual:self.taskItemDetailsrequest])
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(itemRequestFinished:)])
        {
            [self.delegate itemRequestFinished:self.taskItemDetailsrequest.taskItems];
            self.delegate = nil;
        }
        
        self.taskItemDetailsrequest = nil;
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request 
{
    NSLog(@"Tasks Request Failed: %@", [request error]);
    requestsFailed++;
    
    //Just show one alert if there's no internet connection
    if(showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
        showOfflineModeAlert([request.url absoluteString]);
        showOfflineAlert = NO;
    }
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    //Checking if all the requests failed
    if(requestsFailed == requestCount)
    {
        NSString *description = @"All requests failed";
        [self setError:[NSError errorWithDomain:kTaskManagerErrorDomain code:1 
                                       userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(taskManagerRequestFailed:)])
        {
            [self.delegate taskManagerRequestFailed:self];
            self.delegate = nil;
        }
    }
    else
    {
        if(self.delegate && [self.delegate respondsToSelector:@selector(taskManager:requestFinished:)])
        {
            [self.delegate taskManager:self requestFinished:[NSArray arrayWithArray:self.tasks]];
            self.delegate = nil;
        }
    }
}

#pragma mark - CMISServiceManagerService

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    if(loadedRepositoryInfos)
    {
        //The service documents were loaded correctly we proceed to request the activities
        loadedRepositoryInfos = NO;
        [self loadTasks];
    }
    else 
    {
        //We were just waiting for the current load, we need to fetch the repository info again
        //Calling the startTasksRequest to restart trying to load tasks, etc.
        if ([self.taskFilter isEqualToString:MY_TASKS])
        {
            [self startMyTasksRequest];
        }
        else
        {
            [self startInitiatorTasksRequest];
        }
    }
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    //if the requests failed for some reason we still want to try and load tasks
    // if the tasks fail we just ignore all errors
    [self loadTasks];
}

#pragma mark - Singleton

+ (TaskManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end
