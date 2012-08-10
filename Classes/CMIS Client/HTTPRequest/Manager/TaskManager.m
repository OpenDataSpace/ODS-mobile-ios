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
#import "TaskListHTTPRequest.h"

NSString * const kTaskManagerErrorDomain = @"TaskManagerErrorDomain";

@interface TaskManager () {
    NSInteger requestCount;
    NSInteger requestsFailed;
    NSInteger requestsFinished;
    
    BOOL showOfflineAlert;
    BOOL loadedRepositoryInfos;
}

@property (atomic, readonly) NSMutableArray *tasks;

- (void)loadTasks;

@end

@implementation TaskManager

@synthesize tasksQueue = _tasksQueue;
@synthesize error = _error;
@synthesize delegate = _delegate;

// Private
@synthesize tasks = _tasks;

- (void)dealloc 
{
    [_tasks release];
    
    [_tasksQueue cancelAllOperations];
    [_tasksQueue release];
    [_error release];
    
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
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
                if (![account isMultitenant]) {
                    TaskListHTTPRequest *request = [TaskListHTTPRequest taskRequestForAllTasksWithAccountUUID:[account uuid] tenantID:nil];
                    [request setShouldContinueWhenAppEntersBackground:YES];
                    [request setSuppressAllErrors:YES];
                    [self.tasksQueue addOperation:request];
                } 
                else {
                    NSArray *repos = [repoService getRepositoryInfoArrayForAccountUUID:account.uuid];
                    NSArray *tenantIDs = [repos valueForKeyPath:KeyPath];
                    
                    //For cloud accounts, there is one activities request for each tenant the cloud account contains
                    for (NSString *anID in tenantIDs) 
                    {
                        TaskListHTTPRequest *request = [TaskListHTTPRequest taskRequestForAllTasksWithAccountUUID:[account uuid] 
                                                                                                           tenantID:anID];
                        [request setShouldContinueWhenAppEntersBackground:YES];
                        [request setSuppressAllErrors:YES];
                        [self.tasksQueue addOperation:request];
                    }
                }
            }
        }
        
        if([self.tasksQueue requestsCount] > 0) {
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
        } else { 
            // There is no account/alfresco account configured or there's a cloud account with no tenants
            NSString *description = @"There was no request to process";
            [self setError:[NSError errorWithDomain:kTaskManagerErrorDomain code:0 
                                           userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
            
            if(self.delegate && [self.delegate respondsToSelector:@selector(taskManagerRequestFailed:)]) {
                [self.delegate taskManagerRequestFailed:self];
                self.delegate = nil;
            }
        }
    }
    
}

- (void)startTasksRequest 
{
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

- (void)requestFinished:(ASIHTTPRequest *)request 
{
    requestsFinished++;
    TaskListHTTPRequest *tasksRequest = (TaskListHTTPRequest *)request;
    [self.tasks addObjectsFromArray:tasksRequest.tasks];
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
    if(requestsFailed == requestCount) {
        NSString *description = @"All requests failed";
        [self setError:[NSError errorWithDomain:kTaskManagerErrorDomain code:1 
                                       userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(taskManagerRequestFailed:)]) {
            [self.delegate taskManagerRequestFailed:self];
            self.delegate = nil;
        }
    } else {
        if(self.delegate && [self.delegate respondsToSelector:@selector(taskManager:requestFinished:)]) {
            [self.delegate taskManager:self requestFinished:[NSArray arrayWithArray:self.tasks]];
            self.delegate = nil;
        }
    }
}

#pragma mark -
#pragma mark CMISServiceManagerService
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
        [self startTasksRequest];
    }
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    //if the requests failed for some reason we still want to try and load tasks
    // if the tasks fail we just ignore all errors
    [self loadTasks];
}

#pragma mark -
#pragma mark Singleton

static TaskManager *sharedTaskManager = nil;

+ (TaskManager *)sharedManager
{
    if (sharedTaskManager == nil) {
        sharedTaskManager = [[super allocWithZone:NULL] init];
    }
    return sharedTaskManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end
