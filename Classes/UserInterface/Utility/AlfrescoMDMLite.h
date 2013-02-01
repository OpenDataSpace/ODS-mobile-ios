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
//  AlfrescoMDMLite.h
//

#import <Foundation/Foundation.h>
#import "CMISMDMRequest.h"
#import "ASINetworkQueue.h"
#import "CMISServiceManager.h"
#import "DownloadMetadata.h"

extern NSTimeInterval const kDocExpiryCheckingInterval;

@class AlfrescoMDMLite;

@protocol AlfrescoMDMLiteDelegate <NSObject>
@optional
- (void)mdmLiteRequestFinishedWithItems:(NSArray *)items;
@end

@protocol AlfrescoMDMServiceManagerDelegate <NSObject>
@optional
- (void)mdmServiceManagerRequestFinishedForAccount:(NSString *)accountUUID withSuccess:(BOOL)success;
@end

@interface AlfrescoMDMLite : NSObject <CMISServiceManagerListener>

@property (nonatomic, retain) ASINetworkQueue *requestQueue;
@property (nonatomic, assign) id<AlfrescoMDMLiteDelegate> delegate;
@property (nonatomic, assign) id<AlfrescoMDMServiceManagerDelegate> serviceDelegate;

- (BOOL)isRestrictedDownload:(NSString *)fileName;
- (BOOL)isRestrictedSync:(NSString *)fileName;
- (BOOL)isRestrictedDocument:(DownloadMetadata *)metadata;
- (BOOL)isRestrictedRepoItem:(RepositoryItem *)repoItem;

- (BOOL)isDownloadExpired:(NSString *)fileName withAccountUUID:(NSString *)accountUUID;
- (BOOL)isSyncExpired:(NSString *)fileName withAccountUUID:(NSString *)accountUUID;

- (void)setRestrictedAspect:(BOOL)setAspect forItem:(RepositoryItem *)repoItem;

- (void)loadMDMInfo:(NSArray *)nodes withAccountUUID:(NSString *)accountUUID andTenantId:(NSString *)tenantID;
- (void)loadRepositoryInfoForAccount:(NSString *)accountUUID;

+ (AlfrescoMDMLite *)sharedInstance;

/**
 * Log whether a repository attached to an account supports MDM or not
 */
- (void)enableMDMForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID enabled:(BOOL)enabled;

/**
 * Query whether a repository attached to an account supports MDM or not
 */
- (BOOL)isMDMEnabledForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;

@end
