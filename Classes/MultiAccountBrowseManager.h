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
//  MultiAccountBrowseManager.h
//

#import <Foundation/Foundation.h>
#import "CMISServiceManager.h"
#import "SitesManagerService.h"

@class MultiAccountBrowseManager;

typedef enum {
    MultiAccountSitesUpdate,
    MultiAccountAccountsUpdate,
    MultiAccountNetworksUpdate,
    MultiAccountNetworkSitesUpdate
} MultiAccountUpdateType;

@protocol MultiAccountBrowseListener <NSObject>
@optional
-(void)multiAccountBrowseUpdated:(MultiAccountBrowseManager *)manager forType:(MultiAccountUpdateType)type;
-(void)multiAccountBrowseFailed:(MultiAccountBrowseManager *)manager forType:(MultiAccountUpdateType)type;
@end

@interface MultiAccountBrowseManager : NSObject <SitesManagerListener, CMISServiceManagerListener> {
    BOOL isUpdated;
    NSString *requestAccountUUID;
}
@property (atomic, readonly) NSMutableSet *listeners;

- (void)addListener:(id<MultiAccountBrowseListener>)listener;
- (void)removeListener:(id<MultiAccountBrowseListener>)listener;

- (void)loadSitesForAccountUUID:(NSString *)uuid;
- (void)reloadSitesForAccountUUID:(NSString *)uuid;

- (void)loadNetworksForAccountUUID:(NSString *)uuid;
- (void)loadSitesForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;
 
//load all account and network sites
//- (void)loadAllSites;

//Returns nil if the sites are not loaded yet
- (NSArray *)sitesForAccountUUID:(NSString *)uuid;
- (NSArray *)networksForAccountUUID:(NSString *)uuid;
- (NSArray *)sitesForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;
- (NSArray *)accounts;

+ (MultiAccountBrowseManager *)sharedManager;
@end
