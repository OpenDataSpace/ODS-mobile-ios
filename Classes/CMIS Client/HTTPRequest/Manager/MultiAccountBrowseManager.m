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
//  MultiAccountBrowseManager.m
//

#import "MultiAccountBrowseManager.h"
#import "RepositoryServices.h"
#import "AccountManager.h"

@implementation MultiAccountBrowseManager

- (void)dealloc
{
    [requestAccountUUID release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _listeners = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark - private methods

// Helper to call the listener with the success update and a given update type
- (void)updateListenersWithType:(MultiAccountUpdateType)type
{
    for (id<MultiAccountBrowseListener> listener in self.listeners)
    {
        if ([listener respondsToSelector:@selector(multiAccountBrowseUpdated:forType:)])
        {
            [listener multiAccountBrowseUpdated:self forType:type];
        }
    }
}

// Helper to call the listener with the fail update and a given update type

- (void)failListenersWithType:(MultiAccountUpdateType)type
{
    for (id<MultiAccountBrowseListener> listener in self.listeners)
    {
        if ([listener respondsToSelector:@selector(multiAccountBrowseFailed:forType:)])
        {
            [listener multiAccountBrowseFailed:self forType:type];
        }
    }
}

#pragma mark - public methods

- (void)addListener:(id<MultiAccountBrowseListener>)listener
{
    [self.listeners addObject:listener];
}

- (void)removeListener:(id<MultiAccountBrowseListener>)listener
{
    [self.listeners removeObject:listener];
}

- (void)loadSitesForAccountUUID:(NSString *)uuid
{
    // If there are cached results, just update the listeners about it
    if ([[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] hasResults])
    {
        [self updateListenersWithType:MultiAccountUpdateTypeSites];
    }
    else
    {
        // .. else, proceed to request the sites.
        [self reloadSitesForAccountUUID:uuid];
    }
}

- (void)reloadSitesForAccountUUID:(NSString *)uuid
{
    [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] addListener:self];
    [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] startOperations];
}

- (void)loadNetworksForAccountUUID:(NSString *)uuid
{
    CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
    [serviceManager addQueueListener:self];
    [serviceManager loadServiceDocumentForAccountUuid:uuid];
    [requestAccountUUID release];
    requestAccountUUID = [uuid copy];
}

- (void)loadSitesForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    // If there are cached results, just update the listeners about it
    if ([[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] hasResults])
    {
        [self updateListenersWithType:MultiAccountUpdateTypeNetworkSites];
    }
    else
    {
        [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] addListener:self];
        [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] startOperations];
    }
}

/**
 * SitesMangerService, AccountManager and RepositoryServices are used to access the sites, accounts and networks,
 *  cached results, respectively.
 */
- (NSArray *)sitesForAccountUUID:(NSString *)uuid
{
    if ([[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] hasResults])
    {
        return [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:nil] allSites];
    }
    return nil;
}

- (NSArray *)networksForAccountUUID:(NSString *)uuid
{
    NSArray *networks = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:uuid]];
    if (networks)
    {
        return networks;
    }

    return nil;
}

- (NSArray *)sitesForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    if ([[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] hasResults])
    {
        return [[SitesManagerService sharedInstanceForAccountUUID:uuid tenantID:tenantID] allSites];
    }

    return nil;
}

- (NSArray *)accounts
{
    return [[AccountManager sharedManager] activeAccounts];
}

/**
 * This class depends on the CMISServiceManagerListener and SitesMangerService to requests the
 * Networks, sites, etc.
 */
#pragma mark - CMISServiceManagerListener

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    NSArray *array = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:requestAccountUUID]];
    if (array)
    {
        [self updateListenersWithType:MultiAccountUpdateTypeNetworks];
    }
    else
    {
        [self failListenersWithType:MultiAccountUpdateTypeNetworks];
    }
    
    [requestAccountUUID release];
    requestAccountUUID = nil;
    [[CMISServiceManager sharedManager] removeQueueListener:self];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [self failListenersWithType:MultiAccountUpdateTypeNetworks];
    [[CMISServiceManager sharedManager] removeQueueListener:self];
}

#pragma mark - SitesMangerService delegate

- (void)siteManagerFinished:(SitesManagerService *)siteManager
{
    if ([[siteManager tenantID] isEqualToString:kDefaultTenantID])
    {
        [self updateListenersWithType:MultiAccountUpdateTypeSites];
    }
    else
    {
        [self updateListenersWithType:MultiAccountUpdateTypeNetworkSites];
    }
    
    [siteManager removeListener:self];
}

- (void)siteManagerFailed:(SitesManagerService *)siteManager
{
    if ([[siteManager tenantID] isEqualToString:kDefaultTenantID])
    {
        [self failListenersWithType:MultiAccountUpdateTypeNetworkSites];
    }
    else
    {
        [self failListenersWithType:MultiAccountUpdateTypeNetworkSites];
    }
    
    [siteManager removeListener:self];
}

#pragma mark - Singleton methods

+ (MultiAccountBrowseManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end
