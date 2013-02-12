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
//  AlfrescoMDMLite.m
//

#import "AlfrescoMDMLite.h"
#import "CMISMDMRequest.h"
#import "FileDownloadManager.h"
#import "FavoriteFileDownloadManager.h"
#import "AccountManager.h"
#import "SessionKeychainManager.h"
#import "NSNotificationCenter+CustomNotification.h"

NSTimeInterval const kDocExpiryCheckingInterval = 5;

@interface AlfrescoMDMLite ()
@property (atomic, readonly) NSMutableDictionary *repoItemsForAccounts;
@property (atomic, retain) NSString *currentAccountUUID;
@property (nonatomic, retain) NSTimer *mdmTimer;
@property (nonatomic, retain) NSMutableDictionary *mdmEnabledStateForAccounts;
@end

@implementation AlfrescoMDMLite

- (void)enableMDMForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID enabled:(BOOL)enabled
{
    if (!tenantID)
    {
        tenantID = kDefaultTenantID;
    }
    
    NSNumber *mdmEnabled = [NSNumber numberWithBool:enabled];
    NSMutableDictionary *perTenantDictionary = [self.mdmEnabledStateForAccounts objectForKey:uuid];
    if (!perTenantDictionary)
    {
        perTenantDictionary = [NSMutableDictionary dictionary];
        [self.mdmEnabledStateForAccounts setObject:perTenantDictionary forKey:uuid];
    }
	[perTenantDictionary setObject:mdmEnabled forKey:tenantID];
}

- (BOOL)isMDMEnabledForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *perTenantDictionary = [self.mdmEnabledStateForAccounts objectForKey:uuid];
    NSNumber *mdmEnabled = [perTenantDictionary objectForKey:(tenantID != nil ? tenantID : kDefaultTenantID)];
    return [mdmEnabled boolValue];
}

- (BOOL)isRestrictedDownload:(NSString*)fileName
{
    return [[FileDownloadManager sharedInstance] isFileRestricted:fileName];
}

- (BOOL)isRestrictedSync:(NSString*) fileName
{
    return [[FavoriteFileDownloadManager sharedInstance] isFileRestricted:fileName];
}

- (BOOL)isRestrictedDocument:(DownloadMetadata*)metadata
{
    return [metadata.aspects containsObject:kMDMAspectKey];
}

- (BOOL)isRestrictedRepoItem:(RepositoryItem*)repoItem
{
    return [repoItem.aspects containsObject:kMDMAspectKey];
}

- (BOOL)isDownloadExpired:(NSString*)fileName withAccountUUID:(NSString*)accountUUID
{
    AccountInfo * accountInfo = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
    BOOL auth = [accountInfo password] != nil && ![[accountInfo password] isEqualToString:@""];
    
    return (!auth && [self isRestrictedDownload:fileName] && [[FileDownloadManager sharedInstance] isFileExpired:fileName]);
}

- (BOOL)isSyncExpired:(NSString*)fileName withAccountUUID:(NSString*)accountUUID
{
    AccountInfo * accountInfo = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
    BOOL auth = [accountInfo password] != nil && ![[accountInfo password] isEqualToString:@""];
    
    return (!auth && [self isRestrictedSync:fileName] && [[FavoriteFileDownloadManager sharedInstance] isFileExpired:fileName]);
}

#pragma mark - Utility Methods

- (void)setRestrictedAspect:(BOOL)setAspect forItem:(RepositoryItem*)repoItem
{
    if (setAspect)
    {
        if (![repoItem.aspects containsObject:kMDMAspectKey])
        {
            [repoItem.aspects addObject:kMDMAspectKey];
        }
    }
    else
    {
        [repoItem.aspects removeObject:kMDMAspectKey];
    }
}

- (void)trackRestrictedDocuments
{
    NSArray *expiredDownloadFiles = [[FileDownloadManager sharedInstance] getExpiredFilesList];
    NSArray *expiredSyncFiles = [[FavoriteFileDownloadManager sharedInstance] getExpiredFilesList];
    
    if([expiredDownloadFiles count] > 0 || [expiredSyncFiles count] > 0)
    {
        NSDictionary *userInfo = @{
                                   @"expiredDownloadFiles" : expiredDownloadFiles,
                                   @"expiredSyncFiles" : expiredSyncFiles
                                   };
        
        [[NSNotificationCenter defaultCenter] postExpiredFilesNotificationWithUserInfo:userInfo];
    }
}

#pragma mark - Load MDM Info

- (void)loadMDMInfo:(NSArray*)nodes withAccountUUID:(NSString*)accountUUID andTenantId:(NSString*)tenantID delegate:(id<AlfrescoMDMLiteDelegate>)delegate
{
    if (![self isMDMEnabledForAccountUUID:accountUUID tenantID:tenantID])
    {
        //return;
    }
    
    if (!self.requestQueue)
    {
        [self setRequestQueue:[ASINetworkQueue queue]];
    }
    
    if ([nodes count] > 0)
    {
        for(RepositoryItem *item in nodes)
        {
            [self setRestrictedAspect:YES forItem:item];
        }
        
        [self.repoItemsForAccounts setValue:nodes forKey:accountUUID];
        NSString *pattern = [NSString stringWithFormat:@"(d.cmis:objectId='%@')", [[nodes valueForKey:@"guid"] componentsJoinedByString:@"' OR d.cmis:objectId='"]];
        
        CMISMDMRequest *down = [[[CMISMDMRequest alloc] initWithSearchPattern:pattern
                                                               folderObjectId:nil
                                                                  accountUUID:accountUUID
                                                                     tenantID:tenantID] autorelease];
        
        down.mdmLiteDelegate = delegate;
        [self.requestQueue addOperation:down];
    }
    
    if ([self.requestQueue requestsCount] > 0)
    {
        [self.requestQueue setDelegate:self];
        [self.requestQueue setShowAccurateProgress:NO];
        [self.requestQueue setShouldCancelAllRequestsOnFailure:NO];
        [self.requestQueue setRequestDidFailSelector:@selector(requestFailed:)];
        [self.requestQueue setRequestDidFinishSelector:@selector(requestFinished:)];
        [self.requestQueue setQueueDidFinishSelector:@selector(queueFinished:)];
        [self.requestQueue go];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    CMISMDMRequest *mdmRequest = (CMISMDMRequest *)request;
    NSArray *searchedDocuments = [mdmRequest results];
    NSString *accountUUID = [mdmRequest accountUUID];
    
    NSArray *favNodes = [self.repoItemsForAccounts objectForKey:accountUUID];
    NSMutableArray *mdmList = [[NSMutableArray alloc] init];
    
    for (RepositoryItem *rItem in favNodes)
    {
        RepositoryItem *temp = nil;
        
        for (RepositoryItem *repoItem in searchedDocuments)
        {
            if ([repoItem.guid isEqualToString:rItem.guid])
            {
                temp = repoItem;
                [mdmList addObject:rItem];
                break;
            }
        }
        
        if (temp != nil)
        {
            [self setRestrictedAspect:YES forItem:rItem];
            [rItem.metadata setValue:[temp.metadata objectForKey:kFileExpiryKey] forKey:kFileExpiryKey];
        }
        else
        {
            [self setRestrictedAspect:NO forItem:rItem];
            [rItem.metadata removeObjectForKey:kFileExpiryKey];
        }
    }
    
    if (mdmRequest.mdmLiteDelegate && [mdmRequest.mdmLiteDelegate respondsToSelector:@selector(mdmLiteRequestFinishedWithItems:)])
    {
        [mdmRequest.mdmLiteDelegate mdmLiteRequestFinishedWithItems:favNodes];
    }
    else
    {
        [self.delegate mdmLiteRequestFinishedWithItems:mdmList];
    }

    [mdmList release];
    
    [self.repoItemsForAccounts removeObjectForKey:accountUUID];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"Error: %@ ", [request.error description]);
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
    
}

#pragma mark - Load CMISServiceManager

- (void)loadRepositoryInfoForAccount:(NSString*)accountUUID
{
    if(!self.currentAccountUUID)
    {
        self.currentAccountUUID = accountUUID;
        
        [[CMISServiceManager sharedManager] addQueueListener:self];
        
        if (![[CMISServiceManager sharedManager] isActive])
        {
            [[CMISServiceManager sharedManager] loadServiceDocumentForAccountUuid:accountUUID isForRestrictedFiles:YES]; // loadAllServiceDocuments];
        }
    }
}

#pragma mark - CMISServiceManagerService

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    
    SessionKeychainManager *keychainManager = [SessionKeychainManager sharedManager];
    AccountInfo * accountInfo = [[AccountManager sharedManager] accountInfoForUUID:self.currentAccountUUID];
    BOOL auth = ([[accountInfo password] length] != 0) || ([keychainManager passwordForAccountUUID:self.currentAccountUUID] != 0);
    
    if (self.serviceDelegate && [self.serviceDelegate respondsToSelector:@selector(mdmServiceManagerRequestFinishedForAccount:withSuccess:)])
    {
        [self.serviceDelegate mdmServiceManagerRequestFinishedForAccount:self.currentAccountUUID withSuccess:auth];
    }
    
    self.currentAccountUUID = nil;
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    self.currentAccountUUID = nil;
}

#pragma mark - Singleton methods

+ (AlfrescoMDMLite *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (id)init
{
    if (self = [super init])
    {
        _repoItemsForAccounts = [[NSMutableDictionary alloc] init];
        _mdmEnabledStateForAccounts = [[NSMutableDictionary alloc] init];
        self.mdmTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(trackRestrictedDocuments) userInfo:nil repeats:YES];
    }
    return self;
}

@end
