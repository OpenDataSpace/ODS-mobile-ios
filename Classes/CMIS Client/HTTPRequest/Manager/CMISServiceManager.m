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
//  CMISServiceManager.m
//

#import <Security/SecureTransport.h>
#import "CMISServiceManager.h"
#import "ServiceDocumentRequest.h"
#import "AccountManager+FileProtection.h"
#import "RepositoryServices.h"
#import "TenantsHTTPRequest.h"
#import "Utility.h"
#import "FileProtectionManager.h"
#import "WorkflowDefinitionsHTTPRequest.h"
#import "MDMEnabledHTTPRequest.h"
#import "SDWebImageManager.h"
#import "FolderDescendantsRequest.h"
#import "LogoManager.h"
#import "NSURL+HTTPURLUtils.h"
#import "LinkRelationService.h"

NSString * const kCMISServiceManagerErrorDomain = @"CMISServiceManagerErrorDomain";
NSString * const kQueueListenersKey = @"queueListenersKey";
NSString * const kProductNameEnterprise = @"Enterprise";


@interface CMISServiceManager ()
// Private dictionary with the cache of tentants ID (Only for cloud account)
@property (atomic, readonly) NSMutableDictionary *cachedTenantIDDictionary;
// Private dictionary with the listeners of queue and individual requests
// Queue lists are an array under a special key, and individual listeners are an array under
// its account UUID as a key
@property (atomic, readonly) NSMutableDictionary *listeners;

/**
 * Utility method to start the requests for all the accounts UUID in the array
 */
- (void)startServiceRequestsForAccountUUIDs:(NSArray *)accountUUIDsArray;
- (void)saveEnterpriseAccount:(NSString *)accountUUID;
- (void)removeEnterpriseAccount:(NSString *)accountUUID;
@end


@implementation CMISServiceManager
@synthesize networkQueue = _networkQueue;
@synthesize servicesLoaded = _servicesLoaded;
@synthesize error = _error;
@synthesize cachedTenantIDDictionary = _cachedTenantIDDictionary;
@synthesize listeners = _listeners;
@synthesize accountsRunning = _accountsRunning;

#pragma mark dealloc & init methods

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_networkQueue release];
    [_error release];
    [_cachedTenantIDDictionary release];
    [_listeners release];
    [_accountsRunning release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self) 
    {
        _listeners = [[NSMutableDictionary alloc] init];
        
        _networkQueue = [[ASINetworkQueue alloc] init];
        [_networkQueue setDelegate:self];
        [_networkQueue setShowAccurateProgress:NO];
        [_networkQueue setShouldCancelAllRequestsOnFailure:NO];
        [_networkQueue setRequestDidFailSelector:@selector(requestFailed:)];
        [_networkQueue setRequestDidFinishSelector:@selector(requestFinished:)];
        [_networkQueue setQueueDidFinishSelector:@selector(queueFinished:)];
        
        _cachedTenantIDDictionary = [[NSMutableDictionary dictionary] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated:) name:kNotificationAccountListUpdated object:nil];
    }
    return self;
}

- (void)removeAllListeners:(id<CMISServiceManagerListener>)aListner
{
    [self removeQueueListener:aListner];
    // Searches in all the listeners dictionary for a given listener
    NSSet *keys = [self.listeners keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return ([obj isEqual:aListner]);
    }];
    [self.listeners removeObjectsForKeys:[keys allObjects]];
}

- (void)addListener:(id<CMISServiceManagerListener>)newListener forAccountUuid:(NSString *)uuid 
{
    NSMutableArray *listenersForAccount = [self.listeners objectForKey:uuid];
    if(!listenersForAccount) 
    {
        listenersForAccount = [NSMutableArray array];
        [self.listeners setObject:listenersForAccount forKey:uuid];
    }
    
    [listenersForAccount addObject:newListener];
}

- (void)removeListener:(id<CMISServiceManagerListener>)newListener forAccountUuid:(NSString *)uuid 
{
    NSMutableArray *listenersForAccount = [self.listeners objectForKey:uuid];
    if(listenersForAccount) {
        [listenersForAccount removeObject:newListener];
    }
}

- (void)addQueueListener:(id<CMISServiceManagerListener>) newListener 
{
    NSMutableArray *listenersForAccount = [self.listeners objectForKey:kQueueListenersKey];
    if(!listenersForAccount) {
        listenersForAccount = [NSMutableArray array];
        [self.listeners setObject:listenersForAccount forKey:kQueueListenersKey];
    }
    
    [listenersForAccount addObject:newListener];
}
- (void)removeQueueListener:(id<CMISServiceManagerListener>)newListener 
{
    NSMutableArray *listenersForAccount = [self.listeners objectForKey:kQueueListenersKey];
    if(listenersForAccount) {
        [listenersForAccount removeObject:newListener];
    }
}


#pragma mark - Network

- (BOOL)isActive
{
    return [[self accountsRunning] count] > 0;
}

- (BOOL)queueIsRunning 
{
    return [self networkQueue] && ![[self networkQueue] isSuspended];
}

- (void)callListeners:(SEL)selector forAccountUuid:(NSString *)uuid withObject:(id)object 
{
    NSArray *listenersForAccount = [[self.listeners objectForKey:uuid] copy];
    if(listenersForAccount) {
        for(id listener in listenersForAccount) {
            if([listener respondsToSelector:selector]) {
                [listener performSelector:selector withObject:object];
            }
        }
    }
    [listenersForAccount release];
}

- (void)callQueueListeners:(SEL)selector 
{
    NSArray *listenersForAccount = [[self.listeners objectForKey:kQueueListenersKey] copy];
    if(listenersForAccount) {
        for(id listener in listenersForAccount) {
            if([listener respondsToSelector:selector]) {
                [listener performSelector:selector withObject:self];
            }
        }
    }
    [listenersForAccount release];
}

- (void)loadAllServiceDocuments 
{
    NSArray *accounts = [[AccountManager sharedManager] activeAccounts];
    NSMutableArray *accountsToRequest = [NSMutableArray arrayWithCapacity:[accounts count]];
    
    for (AccountInfo *account in accounts)
    {
        if (![[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:[account uuid]])
        {
            [accountsToRequest addObject:account];
        }
    }
    
    [self startServiceRequestsForAccountUUIDs:[accountsToRequest valueForKeyPath:@"uuid"]];
}

- (void)loadAllServiceDocumentsWithCredentials
{
    NSArray *accounts = [[AccountManager sharedManager] activeAccounts];
    NSMutableArray *accountsToRequest = [NSMutableArray arrayWithCapacity:[accounts count]];
    
    for (AccountInfo *account in accounts)
    {
        if (![[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:[account uuid]] && [account password] && 
            ![account.password isEqualToString:[NSString string]])
        {
            [accountsToRequest addObject:account];
        }
    }
    
    [self startServiceRequestsForAccountUUIDs:[accountsToRequest valueForKeyPath:@"uuid"]];
}

- (void)reloadAllServiceDocuments 
{
    NSArray *accounts = [[AccountManager sharedManager] activeAccounts];
    NSMutableArray *accountsToRequest = [NSMutableArray arrayWithCapacity:[accounts count]];
    
    for(AccountInfo *account in accounts) {
        [accountsToRequest addObject:account];
    }
    
    [self startServiceRequestsForAccountUUIDs:[accountsToRequest valueForKeyPath:@"uuid"]];
}

- (void)loadServiceDocumentForAccountUuid:(NSString *)uuid 
{
    [self loadServiceDocumentForAccountUuid:uuid isForRestrictedFiles:NO];
}

- (void)loadServiceDocumentForAccountUuid:(NSString *)uuid isForRestrictedFiles:(BOOL)isForRestrictedFiles
{
    AlfrescoLogDebug(@"CMISServiceManager - Loading service document for account: %@", uuid);
    
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:uuid];
    if (account.isMultitenant)
    {
        NSArray *repos = [[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:uuid];
        NSSet *storedSet = [NSMutableSet setWithArray:[repos valueForKeyPath:@"tenantID"]];
        NSSet *cachedSet = [NSSet setWithArray:[self.cachedTenantIDDictionary objectForKey:uuid]];
        
        NSMutableSet *resultSet = [NSMutableSet setWithSet:storedSet];
        [resultSet minusSet:cachedSet];
        
        if ((repos.count > 1) && (storedSet.count == cachedSet.count) && ([[resultSet allObjects] count] == 0))
        {
            [self callListeners:@selector(serviceDocumentRequestFinished:) forAccountUuid:uuid withObject:nil];
            [self callQueueListeners:@selector(serviceManagerRequestsFinished:)];
            return;
        }
    }
    else if ([[RepositoryServices shared] getRepositoryInfoForAccountUUID:uuid tenantID:nil])
    {
        [self callListeners:@selector(serviceDocumentRequestFinished:) forAccountUuid:uuid withObject:nil];
        return;
    }
    
    // Don't need to request the current queue since the account UUID is already being requestd
    if (![self.accountsRunning containsObject:uuid])
    {
        // Same process as reloading the service doc for the uuid
        [self reloadServiceDocumentForAccountUuid:uuid isForRestrictedFiles:isForRestrictedFiles];
    }
}


- (void)reloadServiceDocumentForAccountUuid:(NSString *)uuid 
{
    [self reloadServiceDocumentForAccountUuid:uuid isForRestrictedFiles:NO];
}

- (void)reloadServiceDocumentForAccountUuid:(NSString *)uuid isForRestrictedFiles:(BOOL)isForRestrictedFiles
{
    [[RepositoryServices shared] removeRepositoriesForAccountUuid:uuid];
    [[self cachedTenantIDDictionary] removeObjectForKey:uuid];
    [self startServiceRequestsForAccountUUIDs:[NSArray arrayWithObject:uuid] isForRestrictedFiles:isForRestrictedFiles];
}

- (void)deleteRepositoriesAndCachedTenantId:(NSString *)uuid
{
    [[RepositoryServices shared] removeRepositoriesForAccountUuid:uuid];
    [[self cachedTenantIDDictionary] removeObjectForKey:uuid];
}

- (void)deleteServiceDocumentForAccountUuid:(NSString *)uuid 
{
    if ([self queueIsRunning])
    {
        //Try to delete the  account's service document request if it's in the queue
        [[self networkQueue] setSuspended:YES];
        
        NSArray *operations = [[self networkQueue] operations];
        NSMutableArray *accountUUIDs = [NSMutableArray arrayWithCapacity:[operations count]];
        BOOL needsToRecreateQueue = NO;
        
        for(ServiceDocumentRequest *request in operations) {
            if([[request accountUUID] isEqualToString:uuid]) {
                if([request isExecuting]) [request clearDelegatesAndCancel];
                needsToRecreateQueue = YES;
            } // else - no need to recreate the queue if the request for the account uuid is not in the queue
            
            //the queue will not pause a current operation and we are going to let them finish
            //We do not reschedule a request that is running or is finished
            if((![request isExecuting] || ![request isFinished]) && ![[request accountUUID] isEqualToString:uuid]) {
                [accountUUIDs addObject:[request accountUUID]];
            }
        }
        
        if(needsToRecreateQueue) {
            [[self networkQueue] setDelegate:nil];
            [[self networkQueue] cancelAllOperations];
            [[self networkQueue] setDelegate:self];
            [self startServiceRequestsForAccountUUIDs:accountUUIDs];
        } else {
            [[self networkQueue] go];
        }
    }
    
    //If there are listeners we send a failure notification
    [self callListeners:@selector(serviceManagerRequestsFailed:) forAccountUuid:uuid withObject:nil];
    [self.listeners removeObjectForKey:uuid];
    [[RepositoryServices shared] removeRepositoriesForAccountUuid:uuid];
}

- (void)startServiceRequestsForAccountUUIDs:(NSArray *)accountUUIDsArray
{
    [self startServiceRequestsForAccountUUIDs:accountUUIDsArray isForRestrictedFiles:NO];
}

- (void)startServiceRequestsForAccountUUIDs:(NSArray *)accountUUIDsArray isForRestrictedFiles:(BOOL)isForRestrictedFiles
{
    AlfrescoLogDebug(@"CMISServiceManager - Starting service requests for accounts: %@", accountUUIDsArray);
    AccountManager *manager = [AccountManager sharedManager];
    NSMutableSet *accountsRunning = [NSMutableSet setWithSet:self.accountsRunning];
    
    if ([accountUUIDsArray count] > 0)
    {
        @synchronized(self.accountsRunning)
        {
            for (NSString *uuid in accountUUIDsArray)
            {
                if (![accountsRunning containsObject:uuid])
                {
                    AccountInfo *accountInfo = [manager accountInfoForUUID:uuid];
                    if(accountInfo)
                    {
                        [accountsRunning addObject:uuid];
                        if ([accountInfo isMultitenant])
                        {
                            //Cloud account list of tenants
                            TenantsHTTPRequest *request = [TenantsHTTPRequest tenantsRequestForAccountUUID:[accountInfo uuid]];
                            [request setSuppressAllErrors:YES];
                            [self.networkQueue addOperation:request];
                        }
                        else
                        {
                            //Alfresco server service document request
                            ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequestForAccountUUID:[accountInfo uuid] tenantID:nil];
                            [request setSuppressAllErrors:YES];
                            [request setIsRequestForExpiredFiles:isForRestrictedFiles];
                            [self.networkQueue addOperation:request];
                        }
                    }
                }
            }
            
            if ([accountsRunning count] > [self.accountsRunning count])
            {
                _showOfflineAlert = YES;
                [self setAccountsRunning:accountsRunning];
                [[self networkQueue] go];
            }
        }
    }
    else
    {
        [self callQueueListeners:@selector(serviceManagerRequestsFinished:)];
    }
}

- (void)requestFinished:(BaseHTTPRequest *)request
{
    if ([request isKindOfClass:[ServiceDocumentRequest class]])
    {
        ServiceDocumentRequest *serviceDocReq = (ServiceDocumentRequest *)request;
        AlfrescoLogDebug(@"Service document request success for UUID=%@", [serviceDocReq accountUUID]);
        NSString *authorization = [[request requestHeaders] objectForKey:@"Authorization"];
        [[[SDWebImageManager sharedManager] imageDownloader] setValue:authorization forHTTPHeaderField:@"Authorization"];

        RepositoryInfo *thisRepository = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:serviceDocReq.accountUUID tenantID:serviceDocReq.tenantID];
        AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:serviceDocReq.accountUUID];
        
        NSRange range = [thisRepository.productName rangeOfString:kProductNameEnterprise];
        // We want to add the paid account to a list of the paid accounts if the
        // product name contains the word "Enterprise" and remove it otherwise
        // Also, we check if the account isMultitenant we should not do anything since 
        // the paid account for cloud accounts is checked in the TenantsHTTPRequest case
        if(range.location != NSNotFound && ![account isMultitenant])
        {
            [self saveEnterpriseAccount:[serviceDocReq accountUUID]];
        } 
        else if(![account isMultitenant])
        {
            [self removeEnterpriseAccount:[serviceDocReq accountUUID]];
        }
#if 0
        // Check to see if the service document was correctly retrieved
        if (thisRepository)
        {
            // Request the workflow definitions from the server to determine whether the Activiti engine is available or not.
            // Note this will make one request per tenant
            WorkflowDefinitionsHTTPRequest *workflowRequest = [WorkflowDefinitionsHTTPRequest workflowDefinitionsRequestForAccountUUID:serviceDocReq.accountUUID tenantID:serviceDocReq.tenantID];
            [workflowRequest setUserInfo:[NSDictionary dictionaryWithObject:serviceDocReq forKey:@"serviceDocReq"]];
            [self.networkQueue addOperation:workflowRequest];
        }
        else
        {
            [self callListeners:@selector(serviceDocumentRequestFailed:) forAccountUuid:[serviceDocReq accountUUID] withObject:request];
        }
#else
        //check if we should load logos from server
        RepositoryInfo *repoConfig = [self getConfigRepoForAccountUUID:serviceDocReq.accountUUID];
        if (repoConfig && [repoConfig latestChangeLogToken]) {
            if ([[LogoManager shareManager] isNeedUpdateLogosWithRepository:repoConfig accountUUID:serviceDocReq.accountUUID]) {
                FolderDescendantsRequest *logoRequest = [self logosRequest:serviceDocReq.accountUUID];
                [logoRequest setUserInfo:[NSDictionary dictionaryWithObject:serviceDocReq forKey:@"serviceDocReq"]];
                [self.networkQueue addOperation:logoRequest];
            }
        }
        
#endif
        [self.accountsRunning removeObject:[serviceDocReq accountUUID]];
    }
    else if ([request isKindOfClass:[TenantsHTTPRequest class]])
    {
        AlfrescoLogDebug(@"TenantsHTTPRequest requestFinished");
        TenantsHTTPRequest *tenantsRequest = (TenantsHTTPRequest *)request;
        
        NSString *accountUUID = [tenantsRequest accountUUID];
        NSArray *tenantIdArray = [tenantsRequest allTenantIDs];
        AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
        
        if([tenantsRequest isPaidAccount] && ![account isQualifyingAccount])
        {
            [self saveEnterpriseAccount:accountUUID];
        }
        else if (![tenantsRequest isPaidAccount] && [account isQualifyingAccount])
        {
            [self removeEnterpriseAccount:accountUUID];
        }
        [[self cachedTenantIDDictionary] setObject:[NSArray arrayWithArray:tenantIdArray] forKey:accountUUID];
        //After the cloud account list of tenants is retrieved, the service document request is called for each tenant.
        for (NSString *tenantID in tenantIdArray) 
        {
            [[self networkQueue] addOperation:[ServiceDocumentRequest httpGETRequestForAccountUUID:accountUUID tenantID:tenantID]];
        }
        
        [[self networkQueue] go];
    }
    else if ([request isKindOfClass:[WorkflowDefinitionsHTTPRequest class]])
    {
        // Request the class definition for the MDM aspect to determine whether MDM is available or not.
        // Note this will make one request per tenant
        MDMEnabledHTTPRequest *mdmRequest = [MDMEnabledHTTPRequest mdmEnabledRequestForAccountUUID:request.accountUUID tenantID:request.tenantID];
        // Pass the serviceDocReq object along
        ServiceDocumentRequest *serviceDocReq = (ServiceDocumentRequest *)[request.userInfo objectForKey:@"serviceDocReq"];
        [mdmRequest setUserInfo:[NSDictionary dictionaryWithObject:serviceDocReq forKey:@"serviceDocReq"]];
        [self.networkQueue addOperation:mdmRequest];
    }
    else if ([request isKindOfClass:[MDMEnabledHTTPRequest class]])
    {
        ServiceDocumentRequest *serviceDocReq = (ServiceDocumentRequest *)[request.userInfo objectForKey:@"serviceDocReq"];
        [self callListeners:@selector(serviceDocumentRequestFinished:) forAccountUuid:[serviceDocReq accountUUID] withObject:serviceDocReq];
    }
    else if ([request isKindOfClass:[FolderDescendantsRequest class]]) {
        ServiceDocumentRequest *serviceDocReq = (ServiceDocumentRequest *)[request.userInfo objectForKey:@"serviceDocReq"];
        FolderDescendantsRequest *logoRequest = (FolderDescendantsRequest *)request;
        [[LogoManager shareManager] setLogoInfo:logoRequest.folderDescendants accountUUID:serviceDocReq.accountUUID configRepo:[self getConfigRepoForAccountUUID:logoRequest.accountUUID]];
        [self callListeners:@selector(serviceDocumentRequestFinished:) forAccountUuid:[serviceDocReq accountUUID] withObject:serviceDocReq];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    AlfrescoLogDebug(@"ServiceDocument Request Failed: %@", request.error);

    ServiceDocumentRequest *serviceDocReq = (ServiceDocumentRequest *)request;
    [self.accountsRunning removeObject:[serviceDocReq accountUUID]];
    [self callListeners:@selector(serviceDocumentRequestFailed:) forAccountUuid:serviceDocReq.accountUUID withObject:request];

    // It shows an error alert only one time for a given queue
    if (_showOfflineAlert)
    {
        showConnectionErrorMessage(request);
        _showOfflineAlert = NO;
    }
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    [self callQueueListeners:@selector(serviceManagerRequestsFinished:)];
}

- (void)saveEnterpriseAccount:(NSString *)accountUUID
{
    BOOL success = [[AccountManager sharedManager] addAsQualifyingAccount:accountUUID];
    if(success)
    {
        [[FileProtectionManager sharedInstance] enterpriseAccountDetected];
    } // If success is NO it means we couldn't add the account since is an excluded account
}

- (void)removeEnterpriseAccount:(NSString *)accountUUID
{
    [[AccountManager sharedManager] removeAsQualifyingAccount:accountUUID];
    
    //If there's no other enterprise account, we want to prompt the user after another enterprise account is added later
    //to enable/disable data protection
    if(![[AccountManager sharedManager] hasQualifyingAccount])
    {
        [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"dataProtectionEnabled"];
        [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"dataProtectionPrompted"];
        [[FDKeychainUserDefaults standardUserDefaults] synchronize];
    }
}

//Called when an account is removed or updated
- (void)accountUpdated:(NSNotification *)notification
{
    NSString *updateType = [[notification userInfo] objectForKey:@"type"];
    // We want to dismiss other updates and just check for deletes
    if([updateType isEqualToString:kAccountUpdateNotificationDelete] && ![[AccountManager sharedManager] hasQualifyingAccount])
    {
        [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"dataProtectionEnabled"];
        [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"dataProtectionPrompted"];
        [[FDKeychainUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark -
#pragma mark Load logos for open data space
- (RepositoryInfo*) getConfigRepoForAccountUUID:(NSString*) accountUUID {
    NSArray *array = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:accountUUID]];
    for (RepositoryInfo *repo in array) {
        if (repo && [repo.repositoryName caseInsensitiveCompare:@"config"] == NSOrderedSame) {
            return repo;
        }
    }
    return nil;
}

- (FolderDescendantsRequest*) logosRequest:(NSString*) accountUUID {
    //find config repository first
    RepositoryInfo *configRepo = [self getConfigRepoForAccountUUID:accountUUID];
    
    NSString *folder = [configRepo rootFolderHref];
    NSString *folderDescendants = [folder stringByReplacingOccurrencesOfString:@"children" withString:@"descendants"];
    //NSString *folderDescendantsUrl = [folderDescendants stringByAppendingString:@"&depth=-1"];
    NSDictionary *defaultParamsDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];
    [defaultParamsDictionary setValue:@"-1" forKey:@"depth"];
    NSURL *folderChildrenCollectionURL = [[NSURL URLWithString:folderDescendants] URLByAppendingParameterDictionary:defaultParamsDictionary];
    
    AlfrescoLogDebug(@"logos request url:%@", folderChildrenCollectionURL);
    
    FolderDescendantsRequest *newRequest = [FolderDescendantsRequest requestWithURL:folderChildrenCollectionURL accountUUID:accountUUID];
    [newRequest setRequestMethod:@"GET"];
    [newRequest setShouldContinueWhenAppEntersBackground:YES];
    
    return newRequest;
}

#pragma mark - Singleton

+ (id)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end
