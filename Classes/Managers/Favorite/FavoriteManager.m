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
//  FavoriteManager.m
//

#import "FavoriteManager.h"
#import "AccountManager.h"
#import "FavoriteNodeInfo.h"
#import "RepositoryServices.h"
#import "Utility.h"
#import "CMISFavoriteDocsHTTPRequest.h"
#import "RepositoryItem.h"
#import "FavoriteDownloadManager.h"
#import "FavoriteFileDownloadManager.h"
#import "ConnectivityManager.h"
#import "FavoriteTableCellWrapper.h"
#import "UploadInfo.h"
#import "FavoritesUploadManager.h"
#import "AlfrescoAppDelegate.h"

NSString * const kFavoriteManagerErrorDomain = @"FavoriteManagerErrorDomain";
NSString * const kDidAskToSync = @"didAskToSync";

/*
 * Sync Obstacle keys
 */
NSString * const kDocumentsUnfavoritedOnServerWithLocalChanges = @"unFavsOnServerWithLocalChanges";
NSString * const kDocumentsDeletedOnServerWithLocalChanges = @"deletedOnServerWithLocalChanges";
NSString * const kDocumentsToBeDeletedLocallyAfterUpload = @"toBeDeletedLocallyAfterUpload";


@interface FavoriteManager () // Private
@property (atomic, retain) NSMutableArray *favorites;
@property (atomic, readonly) NSMutableArray *failedFavoriteRequestAccounts;
@property (atomic, readonly) NSMutableDictionary *favoriteNodeRefsForAccounts;

@end

@implementation FavoriteManager

@synthesize favorites = _favorites; // Private
@synthesize favoriteNodeRefsForAccounts = _favoriteNodeRefsForAccounts;
@synthesize failedFavoriteRequestAccounts = _failedFavoriteRequestAccounts;
@synthesize syncObstacles = _syncObstacles;

@synthesize syncTimer = _syncTimer;
@synthesize lastSuccessfulSyncDate = _lastSuccessfulSyncDate;

@synthesize favoritesQueue = _favoritesQueue;
@synthesize error = _error;
@synthesize delegate = _delegate;
@synthesize listType = _listType;
@synthesize syncType = _syncType;

@synthesize favoriteUnfavoriteDelegate = _favoriteUnfavoriteDelegate;
@synthesize favoriteUnfavoriteAccountUUID = _favoriteUnfavoriteAccountUUID;
@synthesize favoriteUnfavoriteTenantID = _favoriteUnfavoriteTenantID;
@synthesize favoriteUnfavoriteNode = _favoriteUnfavoriteNode;
@synthesize favoriteManagerAction = _favoriteManagerAction;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _favoriteUnfavoriteDelegate = nil;
    [_favorites release];
    [_favoriteNodeRefsForAccounts release];
    [_failedFavoriteRequestAccounts release];
    [_syncObstacles release];
    [_favoritesQueue cancelAllOperations];
    [_favoritesQueue release];
    [_error release];
    [_syncTimer release];
    [_favoriteUnfavoriteAccountUUID release];
    [_favoriteUnfavoriteTenantID release];
    [_favoriteUnfavoriteNode release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
    {
        _favorites = [[NSMutableArray array] retain];
        _favoriteNodeRefsForAccounts = [[NSMutableDictionary alloc] init];
        _failedFavoriteRequestAccounts = [[NSMutableArray array] retain];
        _syncObstacles = [[NSMutableDictionary alloc] init];
        
        [_syncObstacles setObject:[NSMutableArray array] forKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
        [_syncObstacles setObject:[NSMutableArray array] forKey:kDocumentsDeletedOnServerWithLocalChanges];
        [_syncObstacles setObject:[NSMutableArray array] forKey:kDocumentsToBeDeletedLocallyAfterUpload];
        
        requestCount = 0;
        requestsFailed = 0;
        requestsFinished = 0;
        
        _listType = FavoriteListTypeLocal;
        _syncType = SyncTypeAutomatic;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kNotificationFavoriteUploadFinished object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:kSyncPreferenceChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountsListChanged:) name:kNotificationAccountListUpdated object:nil];
        
        self.syncType = SyncTypeAutomatic;
    }
    return self;
}

- (void)startFavoritesRequest:(SyncType)requestedSyncType
{
    self.syncType = requestedSyncType;
    
    if ([self.syncTimer isValid])
    {
        [self.syncTimer invalidate];
        self.syncTimer = nil;
    }
    
    RepositoryServices *repoService = [RepositoryServices shared];
    
    NSArray *accounts = nil;
    if (requestedSyncType == SyncTypeManual)
    {
        accounts = [[AccountManager sharedManager] activeAccounts];
    }
    else
    {
        accounts = [[AccountManager sharedManager] activeAccountsWithPassword];
    }
    
    // We have to make sure the repository info are loaded before requesting the favorites
    for (AccountInfo *account in accounts)
    {
        if (![repoService getRepositoryInfoArrayForAccountUUID:account.uuid])
        {
            loadedRepositoryInfos = NO;
            [self loadRepositoryInfo];
            return;
        }
    }
    
    [self loadFavorites:requestedSyncType];
}

- (void)loadFavorites:(SyncType)requestedSyncType
{
    static NSString *KeyPath = @"tenantID";
    if (!self.favoritesQueue || [self.favoritesQueue requestsCount] == 0)
    {
        self.syncType = requestedSyncType;
        RepositoryServices *repoService = [RepositoryServices shared];
        
        NSArray *accounts;
        if (requestedSyncType == SyncTypeManual)
        {
            accounts = [[AccountManager sharedManager] activeAccounts];
        }
        else
        {
            accounts = [[AccountManager sharedManager] activeAccountsWithPassword];
        }
        
        [self setFavoritesQueue:[ASINetworkQueue queue]];
        
        for (AccountInfo *account in accounts)
        {
            if ([[account vendor] isEqualToString:kFDAlfresco_RepositoryVendorName] &&
                [repoService getRepositoryInfoArrayForAccountUUID:account.uuid])
            {
                if (![account isMultitenant])
                {
                    FavoritesHttpRequest *request = [FavoritesHttpRequest httpRequestFavoritesWithAccountUUID:[account uuid]
                                                                                                     tenantID:nil];
                    [request setShouldContinueWhenAppEntersBackground:YES];
                    [request setSuppressAllErrors:YES];
                    [request setRequestType:FavoritesHttpRequestTypeSync];
                    [self.favoritesQueue addOperation:request];
                }
                else
                {
                    NSArray *repos = [repoService getRepositoryInfoArrayForAccountUUID:account.uuid];
                    NSArray *tenantIDs = [repos valueForKeyPath:KeyPath];
                    
                    //For cloud accounts, there is one favorites request for each tenant the cloud account contains
                    for (NSString *anID in tenantIDs)
                    {
                        FavoritesHttpRequest *request = [FavoritesHttpRequest httpRequestFavoritesWithAccountUUID:[account uuid]
                                                                                                         tenantID:anID];
                        [request setShouldContinueWhenAppEntersBackground:YES];
                        [request setSuppressAllErrors:YES];
                        [request setRequestType:FavoritesHttpRequestTypeSync];
                        [self.favoritesQueue addOperation:request];
                    }
                }
            }
        }
        
        [self.favorites removeAllObjects];
        if ([self.favoritesQueue requestsCount] > 0)
        {
            [self.failedFavoriteRequestAccounts removeAllObjects];
            
            NSArray *noPasswordAccounts = [[AccountManager sharedManager] noPasswordAccounts];
            NSArray *errorAccounts = [[AccountManager sharedManager] errorAccounts];
            NSArray *inactiveAccounts = [[AccountManager sharedManager] inactiveAccounts];
            
            for (AccountInfo *account in noPasswordAccounts)
            {
                [self addAccountToFailedAccounts:[account uuid]];
            }
            for (AccountInfo *account in errorAccounts)
            {
                [self addAccountToFailedAccounts:[account uuid]];
            }
            for (AccountInfo *account in inactiveAccounts)
            {
                [self addAccountToFailedAccounts:[account uuid]];
            }
            
            requestCount = 0;
            requestsFailed = 0;
            requestsFinished = 0;
            
            //setup of the queue
            [self.favoritesQueue setDelegate:self];
            [self.favoritesQueue setShowAccurateProgress:NO];
            [self.favoritesQueue setShouldCancelAllRequestsOnFailure:NO];
            [self.favoritesQueue setRequestDidFailSelector:@selector(requestFailed:)];
            [self.favoritesQueue setRequestDidFinishSelector:@selector(requestFinished:)];
            [self.favoritesQueue setQueueDidFinishSelector:@selector(queueFinished:)];
            
            showOfflineAlert = NO;
            [self.favoritesQueue go];
        }
        else
        {
            // There is no account/alfresco account configured or there's a cloud account with no tenants
            NSString *description = @"There was no request to process";
            [self setError:[NSError errorWithDomain:kFavoriteManagerErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(favoriteManagerRequestFailed:)])
            {
                [self.delegate favoriteManagerRequestFailed:self];
            }
        }
    }
    
}

- (void)loadRepositoryInfo
{
    [[CMISServiceManager sharedManager] addQueueListener:self];
    //If the cmisservicemanager is running we need to wait for it to finish, and then load the requests
    //since it may be requesting only the accounts with credentials, we need it to load all accounts
    if (![[CMISServiceManager sharedManager] isActive])
    {
        loadedRepositoryInfos = YES;
        [[CMISServiceManager sharedManager] loadAllServiceDocuments];
    }
}


- (void)loadFavoritesInfo:(NSArray*)nodes withRequestType:(CMISFavoriteDocumentRequestType)requestType
{
    if ([nodes count] > 0)
    {
        NSString *pattern = [NSString stringWithFormat:@"(cmis:objectId='%@')", [[nodes valueForKey:@"cmisObjectId"] componentsJoinedByString:@"' OR cmis:objectId='"]];
#if MOBILE_DEBUG
        NSLog(@"pattern: %@", pattern);
#endif

        CMISFavoriteDocsHTTPRequest *down = [[[CMISFavoriteDocsHTTPRequest alloc] initWithSearchPattern:pattern
                                                                                         folderObjectId:nil
                                                                                            accountUUID:[[nodes objectAtIndex:0] accountUUID]
                                                                                               tenantID:[[nodes objectAtIndex:0] tenantID]] autorelease];
        [down setFavoritesRequestType:requestType];
        
        requestCount++;
        [self.favoritesQueue addOperation:down];
    }
}


- (void)requestFinished:(ASIHTTPRequest *)request
{
    if ([request isKindOfClass:[CMISFavoriteDocsHTTPRequest class]])
    {
        requestsFinished++;
        
        if ([(CMISFavoriteDocsHTTPRequest *)request favoritesRequestType] == CMISFavoriteDocumentRequestTypeSingle)
        {
            NSArray *searchedDocument = [(CMISQueryHTTPRequest *)request results];
            
            if (searchedDocument.count > 0)
            {
                RepositoryItem *repoItem = [searchedDocument objectAtIndex:0];
                
                if ([self findNodeInFavorites:[repoItem guid]] == nil)
                {
                    FavoriteTableCellWrapper *cellWrapper = [[FavoriteTableCellWrapper alloc] initWithRepositoryItem:repoItem];
                    cellWrapper.accountUUID = [(CMISQueryHTTPRequest *)request accountUUID];
                    cellWrapper.tenantID = [(CMISQueryHTTPRequest *)request tenantID];
                    
                    NSComparator comparator = ^(FavoriteTableCellWrapper *obj1, FavoriteTableCellWrapper *obj2)
                    {
                        return (NSComparisonResult)[obj1.itemTitle caseInsensitiveCompare:obj2.itemTitle];
                    };
                    
                    NSUInteger index = [self.favorites indexOfObject:cellWrapper
                                                       inSortedRange:(NSRange){0, [self.favorites count]}
                                                             options:NSBinarySearchingInsertionIndex
                                                     usingComparator:comparator];
                    
                    [self.favorites insertObject:cellWrapper atIndex:index];
                    
                    [cellWrapper release];
                }
            }
        }
        else
        {
            NSArray *searchedDocuments = [(CMISQueryHTTPRequest *)request results];
            
            for (RepositoryItem *repoItem in searchedDocuments)
            {
                FavoriteTableCellWrapper *cellWrapper = [[[FavoriteTableCellWrapper alloc] initWithRepositoryItem:repoItem] autorelease];
                
                cellWrapper.accountUUID = [(CMISQueryHTTPRequest *)request accountUUID];
                cellWrapper.tenantID = [(CMISQueryHTTPRequest *)request tenantID];
                
                [self.favorites addObject:cellWrapper];
            }
        }
        
        AlfrescoMDMLite * mdmManager = [AlfrescoMDMLite sharedInstance];
        mdmManager.delegate = self;
        [mdmManager loadMDMInfo:[(CMISQueryHTTPRequest *)request results] withAccountUUID:[(CMISQueryHTTPRequest *)request accountUUID] andTenantId:[(CMISQueryHTTPRequest *)request tenantID]];
        
    }
    else if ([request isKindOfClass:[FavoritesHttpRequest class]])
    {
        FavoritesHttpRequest *favoritesRequest = (FavoritesHttpRequest *)request;
        
        if ( favoritesRequest.requestType == FavoritesHttpRequestTypeSync)
        {
            [self.favoriteNodeRefsForAccounts setObject:[favoritesRequest favorites] forKey:favoritesRequest.accountUUID];
            
            NSMutableArray *nodes = [[NSMutableArray alloc] init];
            for (NSString *node in [favoritesRequest favorites])
            {
                if (![node isEqualToString:@""] && node != nil)
                {
                    FavoriteNodeInfo *nodeInfo = [[FavoriteNodeInfo alloc] initWithNode:node accountUUID:favoritesRequest.accountUUID tenantID:favoritesRequest.tenantID];
                    [nodes addObject:nodeInfo];
                    [nodeInfo release];
                }
            }
            
            [self loadFavoritesInfo:[nodes autorelease] withRequestType:CMISFavoriteDocumentRequestTypeMultiple];
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:favoritesRequest.accountUUID, @"accountUUID", nil];
            [[NSNotificationCenter defaultCenter] postDocumentFavoritedOrUnfavoritedNotificationWithUserInfo:userInfo];
        }
        else if (favoritesRequest.requestType == FavoritesHttpRequestTypeModify)
        {
            BOOL exists = NO;
            int existsAtIndex = 0;
            NSMutableArray *newFavoritesList = [[[favoritesRequest favorites] mutableCopy] autorelease];
            
            for (int i=0; i < [[favoritesRequest favorites] count]; i++)
            {
                NSString *node = [[favoritesRequest favorites] objectAtIndex:i];
                
                if ([node isEqualToString:self.favoriteUnfavoriteNode])
                {
                    existsAtIndex = i;
                    exists = YES;
                    break;
                }
            }
            
            if (self.favoriteManagerAction == FavoriteManagerActionFavorite)
            {
                if (exists == NO)
                {
                    [newFavoritesList addObject:self.favoriteUnfavoriteNode];
                }
            }
            else if (self.favoriteManagerAction == FavoriteManagerActionUnfavorite)
            {
                if (exists == YES)
                {
                    [newFavoritesList removeObjectAtIndex:existsAtIndex];
                }
            }
            
            [self.favoriteNodeRefsForAccounts setObject:newFavoritesList forKey:favoritesRequest.accountUUID];
            
            if (self.favoriteManagerAction == FavoriteManagerActionGetNodes)
            {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:favoritesRequest.accountUUID, @"accountUUID", nil];
                [[NSNotificationCenter defaultCenter] postDocumentFavoritedOrUnfavoritedNotificationWithUserInfo:userInfo];
            }
            else
            {
                FavoritesHttpRequest *updateRequest = [FavoritesHttpRequest httpRequestSetFavoritesWithAccountUUID:self.favoriteUnfavoriteAccountUUID
                                                                                                          tenantID:self.favoriteUnfavoriteTenantID
                                                                                                  newFavoritesList:[newFavoritesList componentsJoinedByString:@","]];
                
                [updateRequest setShouldContinueWhenAppEntersBackground:YES];
                [updateRequest setSuppressAllErrors:YES];
                [updateRequest setDelegate:self];
                [updateRequest setRequestType:FavoritesHttpRequestTypeUpdateList];
                
                [updateRequest startAsynchronous];
            }
        }
        else if (favoritesRequest.requestType == FavoritesHttpRequestTypeUpdateList)
        {
            if (self.favoriteUnfavoriteDelegate && [self.favoriteUnfavoriteDelegate respondsToSelector:@selector(favoriteUnfavoriteSuccessfulForObject:)])
            {
                [self.favoriteUnfavoriteDelegate favoriteUnfavoriteSuccessfulForObject:self.favoriteUnfavoriteNode];
            }
            
            FavoriteTableCellWrapper *wrapper = [self findNodeInFavorites:self.favoriteUnfavoriteNode];
            BOOL isFavorite = [self isNodeFavorite:self.favoriteUnfavoriteNode inAccount:self.favoriteUnfavoriteAccountUUID];
            [wrapper setDocumentIsFavorite:isFavorite];
            [wrapper updateFavoriteIndicator];
            
            if (isFavorite && ![self isFirstUse])
            {
                NSMutableArray *node = [[NSMutableArray alloc] initWithCapacity:1];
                FavoriteNodeInfo *nodeInfo = [[FavoriteNodeInfo alloc] initWithNode:self.favoriteUnfavoriteNode accountUUID:favoritesRequest.accountUUID tenantID:favoritesRequest.tenantID];
                [node addObject:nodeInfo];
                [nodeInfo release];
                [self loadFavoritesInfo:[node autorelease] withRequestType:CMISFavoriteDocumentRequestTypeSingle];
            }
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.favoriteUnfavoriteAccountUUID, @"accountUUID", nil];
            [[NSNotificationCenter defaultCenter] postDocumentFavoritedOrUnfavoritedNotificationWithUserInfo:userInfo];
        }
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    if ([request isKindOfClass:[CMISFavoriteDocsHTTPRequest class]] && [(CMISFavoriteDocsHTTPRequest *)request favoritesRequestType] != CMISFavoriteDocumentRequestTypeSingle)
    {
        requestsFailed++;
        
        [self addAccountToFailedAccounts:[(CMISFavoriteDocsHTTPRequest*)request accountUUID]];
    }
    else if ([request isKindOfClass:[FavoritesHttpRequest class]])
    {
        FavoritesHttpRequest *favoritesRequest = (FavoritesHttpRequest *)request;
        
        if ([favoritesRequest requestType] == FavoritesHttpRequestTypeSync)
        {
            [self addAccountToFailedAccounts:[favoritesRequest accountUUID]];
        }
        else if ([favoritesRequest requestType] == FavoritesHttpRequestTypeUpdateList || [favoritesRequest requestType] == FavoritesHttpRequestTypeModify)
        {
            if (self.favoriteUnfavoriteDelegate && [self.favoriteUnfavoriteDelegate respondsToSelector:@selector(favoriteUnfavoriteUnsuccessfulForObject:)])
            {
                [self.favoriteUnfavoriteDelegate favoriteUnfavoriteUnsuccessfulForObject:self.favoriteUnfavoriteNode];
            }
        }
    }
    //NSLog(@"favorites Request Failed: %@", [request error]);
    
    //Just show one alert if there's no internet connection
    
    if (showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
        showOfflineModeAlert([request.url host]);
        showOfflineAlert = NO;
    }
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
    //Checking if all the requests failed
    //NSLog(@"========Fails: %d =========Finished: %d =========== Total Count %d", requestsFailed, requestsFinished, requestCount);
    if (requestsFailed == requestCount)
    {
        NSString *description = @"All requests failed";
        [self setError:[NSError errorWithDomain:kFavoriteManagerErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(favoriteManagerRequestFailed:)])
        {
            self.listType = FavoriteListTypeLocal;
            
            [self.delegate favoriteManagerRequestFailed:self];
        }
    }
    else if ((requestsFailed + requestsFinished) == requestCount)
    {
        [self syncAllDocuments];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(favoriteManager:requestFinished:)])
        {
            self.listType = FavoriteListTypeRemote;
            self.favorites = [NSMutableArray arrayWithArray:[self sortArrayByRepositoryItemTitle:self.favorites]];
            [self.delegate favoriteManager:self requestFinished:[NSArray arrayWithArray:self.favorites]];
        }
        
        if (self.syncType == SyncTypeManual && [self didEncounterObstaclesDuringSync])
        {
            AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.tabBarController setSelectedViewController:appDelegate.favoritesNavController];
        }
    }
}

- (void)mdmLiteRequestFinished:(AlfrescoMDMLite *)mdmManager forItems:(NSArray*)items
{  
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    for (RepositoryItem *repoItem in items)
    {
        [fileManager updateMDMInfo:[repoItem.metadata objectForKey:@"mdm:offlineExpiresAfter"] forFileName:[fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid]];
    }
}

- (void)addAccountToFailedAccounts:(NSString *)accountUUID
{
    if(![self.failedFavoriteRequestAccounts containsObject:accountUUID])
    {
        [self.failedFavoriteRequestAccounts addObject:accountUUID];
    }
}

- (NSArray *)getFavoritesFromLocalIfAvailable
{
    NSArray *favoriteFiles = nil;
    
    if ([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference])
    {
        NSMutableArray *localFavorites = [NSMutableArray array];
        NSArray *activeAccountUuids = [[[AccountManager sharedManager] activeAccounts] valueForKey:@"uuid"];
        
        if (activeAccountUuids.count > 0)
        {
            NSEnumerator *folderContents = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:[self applicationSyncedDocsDirectory] isDirectory:YES]
                                                                includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                                                   options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                              errorHandler:^BOOL(NSURL *url, NSError *fileError) {
                                                                                  NSLog(@"Error retrieving the favorite folder contents in URL: %@ and error: %@", url, fileError.localizedDescription);
                                                                                  return YES;
                                                                              }];
            
            FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
            for (NSURL *fileURL in folderContents)
            {
                BOOL isDirectory;
                [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
                
                NSDictionary *fileDownloadinfo = [fileManager downloadInfoForFilename:[fileURL lastPathComponent]];
                NSString *accountUUID = [fileDownloadinfo objectForKey:@"accountUUID"];
                
                if ([activeAccountUuids containsObject:accountUUID])
                {
                    RepositoryItem *item = [[RepositoryItem alloc] initWithDictionary:fileDownloadinfo];
                    FavoriteTableCellWrapper *cellWrapper = [[FavoriteTableCellWrapper alloc] initWithRepositoryItem:item];
                    
                    if ([self isDocumentModifiedSinceLastDownload:item])
                    {
                        [cellWrapper setSyncStatus:SyncStatusWaiting];
                        [cellWrapper setActivityType:SyncActivityTypeUpload];
                    }
                    else
                    {
                        [cellWrapper setSyncStatus:SyncStatusOffline];
                    }
                    
                    cellWrapper.accountUUID = accountUUID;
                    cellWrapper.fileSize = [FileUtils sizeOfSavedFile:[fileManager pathComponentToFile:[fileURL lastPathComponent]]];
                    [localFavorites addObject:cellWrapper];
                    
                    [cellWrapper release];
                    [item release];
                }
            }
            
            favoriteFiles = [self sortArrayByRepositoryItemTitle:localFavorites];
        }
    }
    return favoriteFiles;
}

- (NSArray *)getLiveListIfAvailableElseLocal
{
    if (self.listType == FavoriteListTypeRemote && [[ConnectivityManager sharedManager] hasInternetConnection])
    {
        return self.favorites;
    }
    return [self getFavoritesFromLocalIfAvailable];
}

#pragma mark - CMISServiceManagerService

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    if (loadedRepositoryInfos)
    {
        //The service documents were loaded correctly we proceed to request the activities
        loadedRepositoryInfos = NO;
        // [self loadFavorites];
    }
    else
    {
        //We were just waiting for the current load, we need to fetch the reposiotry info again
        //Calling the startActivitiesRequest to restart trying to load activities, etc.
        // [self startFavoritesRequest];
    }
    [self loadFavorites:self.syncType];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    //if the requests failed for some reason we still want to try and load activities
    // if the activities fail we just ignore all errors
    [self loadFavorites:self.syncType];
    
}

- (NSArray *)sortArrayByRepositoryItemTitle:(NSArray *)original
{
    NSArray *sortedArray = nil;
    sortedArray = [original sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSString *first = [[(FavoriteTableCellWrapper *)a repositoryItem] title];
        NSString *second = [[(FavoriteTableCellWrapper *)b repositoryItem] title];
        return [first caseInsensitiveCompare:second];
    }];
    
    return sortedArray;
}

#pragma mark - Singleton

+ (FavoriteManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (void)syncAllDocuments
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    if ([self isSyncEnabled])
    {
        [[FavoritesUploadManager sharedManager] cancelActiveUploads];
        
        NSMutableArray *tempRepos = [[NSMutableArray alloc] init];
        
        for (int i=0; i < [self.favorites count]; i++)
        {
            NSMutableArray *filesToDownload = [[NSMutableArray alloc] init];
            
            FavoriteTableCellWrapper *cellWrapper = [self.favorites objectAtIndex:i];
            cellWrapper.syncStatus = SyncStatusSuccessful;
            
            RepositoryItem *repoItem = cellWrapper.repositoryItem;
            [tempRepos addObject:repoItem];
            
            // getting last modification date from repository item on server
            NSDate *dateFromRemote = nil;
            NSString *lastModifiedDateForRemote = [repoItem.metadata objectForKey:@"cmis:lastModificationDate"];
            if (lastModifiedDateForRemote != nil && ![lastModifiedDateForRemote isEqualToString:@""])
            {
                dateFromRemote = dateFromIso(lastModifiedDateForRemote);
            }
            
            // getting last modification date for repository item from local directory
            NSDictionary *existingFileInfo = [fileManager downloadInfoForFilename:[fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid]];
            NSDate *dateFromLocal = nil;
            NSString *lastModifiedDateForLocal = [[existingFileInfo objectForKey:@"metadata"] objectForKey:@"cmis:lastModificationDate"];
            if (lastModifiedDateForLocal != nil && ![lastModifiedDateForLocal isEqualToString:@""])
            {
                dateFromLocal = dateFromIso(lastModifiedDateForLocal);
            }
            
            if (repoItem.title != nil && ![repoItem.title isEqualToString:@""])
            {
                if ([self isDocumentModifiedSinceLastDownload:repoItem])
                {
                    [self uploadRepositoryItem:cellWrapper.repositoryItem toAccount:cellWrapper.accountUUID withTenantID:cellWrapper.tenantID];
                    [cellWrapper setSyncStatus:SyncStatusWaiting];
                }
                else
                {
                    if (![[FavoriteDownloadManager sharedManager] isDownloading:cellWrapper.repositoryItem.guid])
                    {
                        if (dateFromLocal != nil && dateFromRemote != nil)
                        {
                            // Check if document is updated on server
                            if ([dateFromLocal compare:dateFromRemote] == NSOrderedAscending)
                            {
                                [cellWrapper setActivityType:SyncActivityTypeDownload];
                                [filesToDownload addObject:repoItem];
                                [cellWrapper setSyncStatus:SyncStatusWaiting];
                            }
                        }
                        else
                        {
                            [cellWrapper setActivityType:SyncActivityTypeDownload];
                            [filesToDownload addObject:repoItem];
                            [cellWrapper setSyncStatus:SyncStatusWaiting];
                        }
                    }
                    else
                    {
                        [cellWrapper setActivityType:SyncActivityTypeDownload];
                        [cellWrapper setSyncStatus:SyncStatusLoading];
                    }
                }
            }
            
            [[FavoriteDownloadManager sharedManager] queueRepositoryItems:filesToDownload withAccountUUID:cellWrapper.accountUUID andTenantId:cellWrapper.tenantID];
            [filesToDownload release];
            
            self.lastSuccessfulSyncDate = [NSDate date];
        }
        
        [self deleteUnFavoritedItems:tempRepos excludingItemsFromAccounts:self.failedFavoriteRequestAccounts];
        [tempRepos release];
    }
    else
    {
        [fileManager removeDownloadInfoForAllFiles];
    }
}

- (BOOL)isDocumentModifiedSinceLastDownload:(RepositoryItem *)repoItem
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSDictionary *existingFileInfo = [fileManager downloadInfoForFilename:[fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid]];
    
    // getting last downloaded date for repository item from local directory
    NSDate *downloadedDate = [existingFileInfo objectForKey:@"lastDownloadedDate"];
    
    // getting downloaded file locally updated Date
    NSError *dateError = nil;
    NSString *pathToSyncedFile = [fileManager pathToFileDirectory:[fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid]];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathToSyncedFile error:&dateError];
    NSDate *localModificationDate = [fileAttributes objectForKey:NSFileModificationDate];
    
    return ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
}

- (void)deleteUnFavoritedItems:(NSArray *)favorites excludingItemsFromAccounts:(NSArray *)failedAccounts
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    NSDictionary *favoritesMetaData = [fileManager readMetadata];
    NSMutableArray *favoritesKeys = [[NSMutableArray alloc] init];
    NSArray *temp = [favoritesMetaData allKeys];
    
    for (int i =0; i < [temp count]; i++)
    {
        NSString *accountUuidForDoc = [[favoritesMetaData objectForKey:[temp objectAtIndex:i]] objectForKey:@"accountUUID"];
        
        if (![failedAccounts containsObject:accountUuidForDoc])
        {
            [favoritesKeys addObject:[temp objectAtIndex:i]];
        }
    }
    
    NSMutableArray *itemsToBeDeleted = [favoritesKeys mutableCopy];
    
    for (NSString *item in favoritesKeys)
    {
        for (RepositoryItem *repos in favorites)
        {
            if([repos.guid lastPathComponent] != nil && [item hasPrefix:[repos.guid lastPathComponent]])
            {
                [itemsToBeDeleted removeObject:item];
            }
        }
    }
    
    for (NSString *item in itemsToBeDeleted)
    {
        BOOL encounteredObstacle = [self checkForObstaclesInRemovingDownloadInfoForFile:item];
        if(encounteredObstacle == NO)
        {
            [fileManager removeDownloadInfoForFilename:item];
        }
    }
    
    [itemsToBeDeleted release];
    
    [favoritesKeys release];
}

- (BOOL)checkForObstaclesInRemovingDownloadInfoForFile:(NSString *)filename
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSDictionary *fileDownloadInfo = [fileManager downloadInfoForFilename:filename];
    
    BOOL isDeletedOnServer = [self isNodeFavorite:[fileDownloadInfo objectForKey:@"objectId"] inAccount:[fileDownloadInfo objectForKey:@"accountUUID"]];
    
    // getting last downloaded date for repository item from local directory
    NSDate *downloadedDate = [fileDownloadInfo objectForKey:@"lastDownloadedDate"];
    
    // getting downloaded file locally updated Date
    NSError *dateError = nil;
    NSString *pathToSyncedFile = [fileManager pathToFileDirectory:filename];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathToSyncedFile error:&dateError];
    NSDate *localModificationDate = [fileAttributes objectForKey:NSFileModificationDate];
    
    BOOL isModifiedLocally = NO;
    if ([downloadedDate compare:localModificationDate] == NSOrderedAscending)
    {
        isModifiedLocally = YES;
    }
    
    BOOL encounteredObstacle = NO;
    // Note: Deliberate property getter bypass
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleUnFavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if(isDeletedOnServer && isModifiedLocally)
    {
        if(![syncObstableDeleted containsObject:filename])
        {
            [syncObstableDeleted addObject:filename];
        }
        encounteredObstacle = YES;
    }
    else if (!isDeletedOnServer && isModifiedLocally)
    {
        if(![syncObstacleUnFavorited containsObject:filename])
        {
            [syncObstacleUnFavorited addObject:filename];
        }
        encounteredObstacle = YES;
    }
    
    return encounteredObstacle;
}

- (BOOL)didEncounterObstaclesDuringSync
{
    BOOL obstacles = NO;
    
    // Note: Deliberate property getter bypass
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleUnFavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if([syncObstableDeleted count] > 0 || [syncObstacleUnFavorited count] > 0)
    {
        obstacles = YES;
    }
    
    return obstacles;
}

- (void)saveDeletedFavoriteFileBeforeRemovingFromSync:(NSString *)fileName
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSDictionary *fileDownloadInfo = [fileManager downloadInfoForFilename:fileName];
    
    [FileUtils saveFileToDownloads:[fileManager pathToFileDirectory:fileName] withName:[fileDownloadInfo objectForKey:@"filename"]];
    
    // Note: Deliberate property getter bypass
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    [syncObstableDeleted removeObject:fileName];
    
    [fileManager removeDownloadInfoForFilename:fileName];
}

- (void)syncUnfavoriteFileBeforeRemovingFromSync:(NSString *)fileName syncToServer:(BOOL)sync
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSDictionary *fileDownloadInfo = [fileManager downloadInfoForFilename:fileName];
    NSMutableArray *syncObstablesUnfavorited = [self.syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if (sync)
    {
        RepositoryItem *item = [[RepositoryItem alloc] initWithDictionary:fileDownloadInfo];
        
        NSArray *linkRelations = [fileDownloadInfo objectForKey:@"linkRelations"];
        for (NSDictionary *link in linkRelations)
        {
            if ([[link objectForKey:@"rel"] isEqualToString:@"self"])
            {
                item.selfURL = [link objectForKey:@"href"];
                break;
            }
        }
        
        [[self.syncObstacles objectForKey:kDocumentsToBeDeletedLocallyAfterUpload] addObject:fileName];
        [self uploadRepositoryItem:item toAccount:[fileDownloadInfo objectForKey:@"accountUUID"] withTenantID:nil];
        [item release];
    }
    else
    {
        [FileUtils saveFileToDownloads:[fileManager pathToFileDirectory:fileName] withName:[fileDownloadInfo objectForKey:@"filename"]];
        [fileManager removeDownloadInfoForFilename:fileName];
    }
    [syncObstablesUnfavorited removeObject:fileName];
}

- (NSDictionary *)syncObstacles
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSMutableArray *syncObstacleUnFavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    NSArray *temp = [syncObstacleUnFavorited copy];
    
    for (NSString *item in temp)
    {
        NSDictionary *fileDownloadInfo = [fileManager downloadInfoForFilename:item];
        
        if([self findNodeInFavorites:[fileDownloadInfo objectForKey:@""]] != nil)
        {
            [syncObstacleUnFavorited removeObject:item];
        }
    }
    
    [temp release];
    
    return _syncObstacles;
}

- (void)retrySyncForItem:(FavoriteTableCellWrapper *)cellWrapper
{
    if(cellWrapper.activityType == SyncActivityTypeUpload)
    {
        BOOL success = [[FavoritesUploadManager sharedManager] retryUpload:cellWrapper.uploadInfo.uuid];
        if(success == NO)
        {
            [self uploadRepositoryItem:cellWrapper.repositoryItem toAccount:cellWrapper.accountUUID withTenantID:cellWrapper.tenantID];
        }
    }
    else
    {
        DownloadInfo *downloadInfo = [[[DownloadInfo alloc] initWithRepositoryItem:cellWrapper.repositoryItem] autorelease];;
        BOOL success = [[FavoriteDownloadManager sharedManager] retryDownload:downloadInfo.cmisObjectId];
        
        if(success == NO)
        {
            [[FavoriteDownloadManager sharedManager] queueRepositoryItem:cellWrapper.repositoryItem withAccountUUID:cellWrapper.accountUUID andTenantId:cellWrapper.tenantID];
        }
    }
}

# pragma mark - Upload Functionality

- (void)uploadRepositoryItem:(RepositoryItem *)repositoryItem toAccount:(NSString *)accountUUID withTenantID:(NSString *)tenantID
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    NSString *pathToSyncedFile = [fileManager pathToFileDirectory:[fileManager generatedNameForFile:repositoryItem.title withObjectID:repositoryItem.guid]];
    NSURL *documentURL = [NSURL fileURLWithPath:pathToSyncedFile];
    
    UploadInfo *uploadInfo = [self uploadInfoFromURL:documentURL];
    [uploadInfo setFilename:[repositoryItem.title stringByDeletingPathExtension]];
    [uploadInfo setUpLinkRelation:repositoryItem.selfURL];
    [uploadInfo setSelectedAccountUUID:accountUUID];
    [uploadInfo setTenantID:tenantID];
    [uploadInfo setRepositoryItem:repositoryItem];
    
    FavoriteTableCellWrapper *wrapper = [self findNodeInFavorites:repositoryItem.guid];
    [wrapper setUploadInfo:uploadInfo];
    [wrapper setActivityType:SyncActivityTypeUpload];
    
    if (![[FavoritesUploadManager sharedManager] isManagedUpload:uploadInfo.uuid])
    {
        [[FavoritesUploadManager sharedManager] queueUpdateUpload:uploadInfo];
    }
}

- (UploadInfo *)uploadInfoFromURL:(NSURL *)fileURL
{
    UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
    [uploadInfo setUploadFileURL:fileURL];
    [uploadInfo setUploadType:UploadFormTypeDocument];
    
    return uploadInfo;
}

#pragma mark - Upload Notification Center Methods

- (void)uploadFinished:(NSNotification *)notification
{
    UploadInfo *uploadInfo = [[notification userInfo] objectForKey:@"uploadInfo"];
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSString *fileName = [fileManager generatedNameForFile:uploadInfo.repositoryItem.title withObjectID:uploadInfo.repositoryItem.guid];
    
    // If this upload was a "sync unfavorited file" operation then the local file needs deleting now
    NSMutableArray *documentsToBeDeleted = [self.syncObstacles objectForKey:kDocumentsToBeDeletedLocallyAfterUpload];
    if ([documentsToBeDeleted containsObject:fileName])
    {
        [documentsToBeDeleted removeObject:fileName];
        [fileManager removeDownloadInfoForFilename:fileName];
    }
    else if ([fileManager downloadInfoForFilename:fileName] != nil)
    {
        [fileManager updateMetadata:uploadInfo.repositoryItem forFilename:fileName accountUUID:uploadInfo.selectedAccountUUID tenantID:uploadInfo.tenantID];
    }
}

- (void)uploadFailed:(NSNotification *)notification
{
    UploadInfo *notifUpload = [[notification userInfo] objectForKey:@"uploadInfo"];
    notifUpload.repositoryItem = notifUpload.repositoryItem;
}

# pragma mark - Favorite / Unfavorite Request

- (void)favoriteUnfavoriteNode:(NSString *)node withAccountUUID:(NSString *)accountUUID andTenantID:(NSString *)tenantID favoriteAction:(FavoriteManagerAction)action
{
    if ([[AccountManager sharedManager] isAccountActive:accountUUID])
    {
        self.favoriteUnfavoriteNode = node;
        self.favoriteUnfavoriteAccountUUID = accountUUID;
        self.favoriteUnfavoriteTenantID = tenantID;
        self.favoriteManagerAction = action;
        
        FavoritesHttpRequest *request = [FavoritesHttpRequest httpRequestFavoritesWithAccountUUID:accountUUID tenantID:tenantID];
        [request setShouldContinueWhenAppEntersBackground:YES];
        [request setSuppressAllErrors:YES];
        [request setRequestType:FavoritesHttpRequestTypeModify];
        request.delegate = self;
        
        [request startAsynchronous];
    }
}

# pragma mark - Utility Methods

- (BOOL)isNodeFavorite:(NSString *)nodeRef inAccount:(NSString *)accountUUID
{
    NSArray *favoriteNodeRefs = [self.favoriteNodeRefsForAccounts objectForKey:accountUUID];
    
    @synchronized(favoriteNodeRefs)
    {
        if([favoriteNodeRefs containsObject:nodeRef])
        {
            return YES;
        }
        return NO;
    }
}

- (BOOL)isFirstUse
{
    if ([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kDidAskToSync] == YES)
    {
        return NO;
    }
    return YES;
}

- (BOOL)isSyncEnabled
{
    if ([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference])
    {
        Reachability *reach = [Reachability reachabilityForInternetConnection];
        NetworkStatus status = [reach currentReachabilityStatus];
        // if the device is on cellular and "sync on cellular" is set OR the device is on wifi, return YES
        if ((status == ReachableViaWWAN && [[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncOnCellular]) || status == ReachableViaWiFi)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isSyncPreferenceEnabled
{
    return [[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference];
}

- (void)enableSync:(BOOL)enable
{
    [[FDKeychainUserDefaults standardUserDefaults] setBool:enable forKey:kSyncPreference];
}

- (BOOL)forceSyncForFileURL:(NSURL *)url objectId:(NSString *)objectId accountUUID:(NSString *)accountUUID
{
    NSString *fileName = [url lastPathComponent];
    
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSString *newName = [fileManager generatedNameForFile:fileName withObjectID:objectId];
    
    if ([fileManager downloadInfoForFilename:newName] != nil)
    {
        [self startFavoritesRequest:SyncTypeManual];
        return YES;
    }
    
    return NO;
}

- (NSDictionary *)downloadInfoForDocumentWithID:(NSString *) objectID
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    return [fileManager downloadInfoForDocumentWithID:objectID];
}

- (void)showSyncPreferenceAlert
{
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sync.enable.title", @"Sync Documents")
                                 message:[NSString stringWithFormat:NSLocalizedString(@"sync.enable.message", @"Would you like to automatically keep your favorite documents in sync with this %@?"), [[UIDevice currentDevice] model]]
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"No", @"No")
                       otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease] show];
}

- (FavoriteTableCellWrapper *)findNodeInFavorites:(NSString*)node
{
    FavoriteTableCellWrapper *temp = nil;
    for (FavoriteTableCellWrapper *wrapper in self.favorites)
    {
        if ([wrapper.repositoryItem.guid isEqualToString:node])
        {
            temp = wrapper;
        }
    }
    
    return temp;
}

#pragma mark - UIAlertView Delegates

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        [self enableSync:NO];
    }
    else
    {
        [self enableSync:YES];
    }
    
    [[FDKeychainUserDefaults standardUserDefaults] setBool:YES forKey:kDidAskToSync];
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postSyncPreferenceChangedNotification:self];
    
    [self startFavoritesRequest:SyncTypeManual];
}

#pragma mark - File system support

- (NSString *)applicationSyncedDocsDirectory
{
	NSString *favDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"SyncedDocs"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
	// [paths release];
    if (![fileManager fileExistsAtPath:favDir isDirectory:&isDirectory] || !isDirectory)
    {
        NSError *fileError = nil;
        [fileManager createDirectoryAtPath:favDir withIntermediateDirectories:YES attributes:nil error:&fileError];
        
        if (fileError)
        {
            NSLog(@"Error creating the %@ folder: %@", @"Documents", [fileError description]);
            return  nil;
        }
    }
    
	return favDir;
}


#pragma mark - Notification Methods

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:kSyncAfterDelay target:self selector:@selector(startFavoritesRequest:) userInfo:nil repeats:NO];
}

/**
 * Listening to the reachability changes to update lists and sync
 */
- (void)reachabilityChanged:(NSNotification *)notification
{
    [self startFavoritesRequest:SyncTypeAutomatic];
}

/**
 * user changed sync preference in settings
 */
- (void)settingsChanged:(NSNotification *)notification
{
    id sender = notification.object;
    if (sender && ![sender isEqual:self])
    {
        [self startFavoritesRequest:SyncTypeAutomatic];
    }  
}

/**
 * Accounts list changed Notification
 */
- (void)accountsListChanged:(NSNotification *)notification
{
    NSString *accountID = [notification.userInfo objectForKey:@"uuid"];
    NSString *changeType = [notification.userInfo objectForKey:@"type"];
    
    if (accountID != nil && ![accountID isEqualToString:@""] && changeType != kAccountUpdateNotificationDelete)
    {
        [self favoriteUnfavoriteNode:@"" withAccountUUID:accountID andTenantID:nil favoriteAction:FavoriteManagerActionGetNodes];
    }
}

@end
