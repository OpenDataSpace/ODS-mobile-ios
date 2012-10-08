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
//  MultiAccountBrowseManager.h
//
// Singleton thats provides a single interface to query and access cached copies of
// Services documents and sites. Supporting both cloud accounts and single server accounts.

#import <Foundation/Foundation.h>
#import "CMISServiceManager.h"
#import "SitesManagerService.h"

@class MultiAccountBrowseManager;

/**
 * A listener gets a single call when any kind of update of this singleton is made
 * i.e. sites loaded, service document loaded, networks (tenants) in a cloud account were loaded, etc.
 * each listener will then have to check the update type and act according to it.
 */
typedef enum
{
    MultiAccountUpdateTypeSites,
    MultiAccountUpdateTypeNetworks,
    MultiAccountUpdateTypeNetworkSites
} MultiAccountUpdateType;


/**
 * A listener will get calls if any update in this singleton happen. Then, it will have to decide if
 * it's interested in the update type and act according. It cannot be configured the type of updates
 * a listener is interested in.
 */
@protocol MultiAccountBrowseListener <NSObject>
@optional
-(void)multiAccountBrowseUpdated:(MultiAccountBrowseManager *)manager forType:(MultiAccountUpdateType)type;
// An specific request failed. ie. sites request, service document request.
-(void)multiAccountBrowseFailed:(MultiAccountBrowseManager *)manager forType:(MultiAccountUpdateType)type;
@end

@interface MultiAccountBrowseManager : NSObject <SitesManagerListener, CMISServiceManagerListener>
{
    NSString *requestAccountUUID;
}
@property (atomic, readonly) NSMutableSet *listeners;

/**
 * Register a new listener for this singleton
 */
- (void)addListener:(id<MultiAccountBrowseListener>)listener;
/**
 * Removes a listener for this singleton
 */
- (void)removeListener:(id<MultiAccountBrowseListener>)listener;


/**
 * Any loading or reloading operation will cause an update call to the listeners even to report
 * if the results are already cached.
 */

// Single server accounts
/**
 * Will try to find the cached sites for a given uuid. IF there's no cached sites will proceed to call the
 * reloadSitesForAccountUUID: method
 */
- (void)loadSitesForAccountUUID:(NSString *)uuid;
/**
 * Requests the sites for account.
 */
- (void)reloadSitesForAccountUUID:(NSString *)uuid;

// Cloud accounts
/**
 * Will try to find the cached networks for a given uuid. If there's no cached networks will proceed to make the
 * request
 */
- (void)loadNetworksForAccountUUID:(NSString *)uuid;
/**
 * Will try to find the cached sites for a given uuid and tenantID. If there's no cached sites will proceed to make the
 * request
 */
- (void)loadSitesForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;
 
//load all account and network sites
//- (void)loadAllSites;

/**
 * The next helper methods provide a unified way to access the result for various requests.
 * Only use them if it's known the result is found, otherwise will return nil.
 */
// Looks into the SitesManagerService instance with an accountUUID and nil tenantID
- (NSArray *)sitesForAccountUUID:(NSString *)uuid;
// Looks into the RepositoryServices for the list of networks
- (NSArray *)networksForAccountUUID:(NSString *)uuid;
// Looks into the SitesManagerService instance with an accountUUID and a tenantID
- (NSArray *)sitesForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;
// Looks into the AccountsManager for the list of accounts
- (NSArray *)accounts;

// Returns
+ (MultiAccountBrowseManager *)sharedManager;
@end
