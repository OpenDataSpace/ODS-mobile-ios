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
//  SitesManagerService.h
//
// The limited-instances class provides a unified way to request all the different kinds of sites into
// one single call. This includes a call to all the sites, my sites and favorites sites for a given account 
// and a tenant ID
//
// There is one instance for each combination of account UUID and tenant ID.

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

@class SitesManagerService;
@class SiteListHTTPRequest;
@class FavoritesSitesHttpRequest;

/**
 * As a SitesManagerListener you get updates for each operation that is started for a given instance.
 *
 */
@protocol SitesManagerListener <NSObject>
/**
 * Called in all listeners only when all the three of the requests are successful
 */
-(void)siteManagerFinished:(SitesManagerService *)siteManager;
/**
 * Called in all listeners when any the three of the requests fail
 */
-(void)siteManagerFailed:(SitesManagerService *)siteManager;

@end

@interface SitesManagerService : NSObject <ASIHTTPRequestDelegate> 
{
    NSArray *_allSites;
    NSArray *_mySites;
    NSArray *_favoriteSites;
    NSArray *_favoriteSiteNames;
    SiteListHTTPRequest *allSitesRequest;
    SiteListHTTPRequest *mySitesRequest;
    FavoritesSitesHttpRequest *favoriteSitesRequest;
    
    BOOL hasResults;
    BOOL isExecuting;
    // Internal counter for the request running
    NSInteger requestsRunning;
    
    NSString *selectedAccountUUID;
    NSString *tenantID;
    
    BOOL showOfflineAlert;
}
/**
 * All sites, my sites, favorites sites and favorite sites names are cached.
 * Any object that doesn't need to reload the sites can query the hasResults property
 * and decide to use the cached properties or try to request all of them again.
 */
@property (nonatomic, copy) NSArray *allSites;
@property (nonatomic, copy) NSArray *mySites;
@property (nonatomic, copy) NSArray *favoriteSites;
// The FavoritesSitesHttpRequest returns a list of sites names but not the whole site information
// we then proceed to search in the "allSites" array for the site names and put the site information
// in the favoritesSites array
@property (atomic, retain) NSArray *favoriteSiteNames;
/**
 * HTTP Request properties
 */
@property (nonatomic, retain) SiteListHTTPRequest *allSitesRequest;
@property (nonatomic, retain) SiteListHTTPRequest *mySitesRequest;
@property (nonatomic, retain) FavoritesSitesHttpRequest *favoriteSitesRequest;
// Flag to signal if there are cached results
@property (nonatomic, readonly) BOOL hasResults;
// Flag to signal if there is a request running. So it can register as a listener and wait for an update
@property (nonatomic, readonly) BOOL isExecuting;
/*
 * Since each instance of this class is made for each combination of accountUUID and tenantID, 
 * we should hold a reference for that information
 */
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;

// Register a new listener to the current instance
-(void)addListener:(id<SitesManagerListener>)newListener;
// Removes a listener to the current instance
-(void)removeListener:(id<SitesManagerListener>)newListener;

/*
 * This will invalidate the current results (if they exists) and start all the requests at once.
 * After all the operations finish, the favorites sites arrays get populated with the found sites
 * for the names in the request and all the listeners registered will be notificated.
 */
-(void)startOperations;

/*
 * Used to signal the siteManager that the current results are no longer valid. So the next query for the
 * hasResults property will tell that we should reload the results with the startOperations method
 */
-(void)invalidateResults;

// A call to this method will cancel any executing operation
-(void)cancelOperations;

//+ (SitesManagerService *)sharedInstanceForAccountUUID:(NSString *)uuid;

// Gets an instance for this class that is unique for a given account UUID (cannot be nil) and a tenantID
// (can be nil if not a cloud accoun)
+ (SitesManagerService *)sharedInstanceForAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
@end
