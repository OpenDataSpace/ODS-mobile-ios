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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  SitesManagerService.h
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

@class SitesManagerService;
@class SiteListHTTPRequest;
@class FavoritesSitesHttpRequest;

@protocol SitesManagerListener <NSObject>

-(void)siteManagerFinished:(SitesManagerService *)siteManager;
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
    NSInteger requestsRunning;
    
    NSString *selectedAccountUUID;
    NSString *tenantID;
    
    BOOL showOfflineAlert;
}
@property (atomic, retain) NSArray *allSites;
@property (atomic, retain) NSArray *mySites;
@property (atomic, retain) NSArray *favoriteSites;
@property (atomic, retain) NSArray *favoriteSiteNames;
@property (nonatomic, retain) SiteListHTTPRequest *allSitesRequest;
@property (nonatomic, retain) SiteListHTTPRequest *mySitesRequest;
@property (nonatomic, retain) FavoritesSitesHttpRequest *favoriteSitesRequest;
@property (nonatomic, readonly) BOOL hasResults;
@property (nonatomic, readonly) BOOL isExecuting;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;


-(void)addListener:(id<SitesManagerListener>)newListener;
-(void)removeListener:(id<SitesManagerListener>)newListener;
//Will perform all the needed requests to retrieve the sites
-(void)startOperations;

//Used to signal the siteManager that the current results are no longer valid
-(void)invalidateResults;

-(void)cancelOperations;

//+ (SitesManagerService *)sharedInstanceForAccountUUID:(NSString *)uuid;
+ (SitesManagerService *)sharedInstanceForAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
@end
