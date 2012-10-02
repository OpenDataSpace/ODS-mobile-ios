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
#import "RepositoryInfo.h"
#import "Utility.h"
#import "CMISFavoriteDocsHTTPRequest.h"
#import "RepositoryItem.h"
#import "FavoriteDownloadManager.h"
#import "FavoriteFileDownloadManager.h"
#import "FileUtils.h"
#import "Utility.h"
#import "ConnectivityManager.h"
#import "FavoriteTableCellWrapper.h"
#import "UploadInfo.h"
#import "FavoritesUploadManager.h"
#import "ISO8601DateFormatter.h"
#import "Reachability.h"

NSString * const kFavoriteManagerErrorDomain = @"FavoriteManagerErrorDomain";
NSString * const kSavedFavoritesFile = @"favorites.plist";
NSString * const kDidAskToSync = @"didAskToSync";

/*
 * Sync Obstacle keys
 */
NSString * const kDocumentsUnfavoritedOnServerWithLocalChanges = @"unFavsOnServerWithLocalChanges";
NSString * const kDocumentsDeletedOnServerWithLocalChanges = @"deletedOnServerWithLocalChanges";


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

@synthesize favoritesQueue;
@synthesize error;
@synthesize delegate;
@synthesize listType;
@synthesize syncType;

@synthesize favoriteUnfavoriteDelegate;
@synthesize favoriteUnfavoriteAccountUUID = _favoriteUnfavoriteAccountUUID;
@synthesize favoriteUnfavoriteTenantID = _favoriteUnfavoriteTenantID;
@synthesize favoriteUnfavoriteNode = _favoriteUnfavoriteNode;
@synthesize favoriteUnfavoriteAction = _favoriteUnfavoriteAction;

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_favorites release];
    [_favoriteNodeRefsForAccounts release];
    [_failedFavoriteRequestAccounts release];
    [_syncObstacles release];
    
    [favoritesQueue cancelAllOperations];
    [favoritesQueue release];
    [error release];
    
    self.syncTimer = nil;
    
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
        
        NSMutableArray * syncObstableDeleted = [[NSMutableArray alloc] init];
        NSMutableArray * syncObstacleUnFavorited = [[NSMutableArray alloc] init];
        
        [_syncObstacles setObject:syncObstacleUnFavorited forKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
        [_syncObstacles setObject:syncObstableDeleted forKey:kDocumentsDeletedOnServerWithLocalChanges];
        
        [syncObstableDeleted release];
        [syncObstacleUnFavorited release];
        
        requestCount = 0;
        requestsFailed = 0;
        requestsFinished = 0;
        
        listType = IsLocal;
        syncType = IsBackgroundSync;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kNotificationFavoriteUploadFinished object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:kSyncPreferenceChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountsListChanged:) name:kNotificationAccountListUpdated object:nil];
        
        self.syncType = IsBackgroundSync;
        
    }
    return self;
}

- (void)startFavoritesRequest:(SyncType)requestedSyncType
{
    if ([self.syncTimer isValid])
    {
        [self.syncTimer invalidate];
        self.syncTimer = nil;
    }
    
    RepositoryServices *repoService = [RepositoryServices shared];
    
    NSArray *accounts;
    if (requestedSyncType == IsManualSync)
    {
        accounts = [[AccountManager sharedManager] activeAccounts];
    }
    else
    {
        accounts = [[AccountManager sharedManager] activeAccountsWithPassword];
    }
    
    //We have to make sure the repository info are loaded before requesting the favorites
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
    if (!favoritesQueue || [favoritesQueue requestsCount] == 0) 
    {
        RepositoryServices *repoService = [RepositoryServices shared];
        
        NSArray *accounts;
        if (requestedSyncType == IsManualSync)
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
                    [request setRequestType:SyncRequest];
                    [favoritesQueue addOperation:request];
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
                        [request setRequestType:SyncRequest];
                        [favoritesQueue addOperation:request];
                    }
                }
            }
        }
        
        if ([favoritesQueue requestsCount] > 0)
        {
            [self.favorites removeAllObjects];
            [self.failedFavoriteRequestAccounts removeAllObjects];
            
            NSArray * noPasswordAccounts = [[AccountManager sharedManager] noPasswordAccounts];
            NSArray * errorAccounts = [[AccountManager sharedManager] errorAccounts];
            NSArray * inActiveAccounts = [[AccountManager sharedManager] inActiveAccounts];
            
            for(AccountInfo * account in noPasswordAccounts)
            {
                [self addAccountToFailedAccounts:[account uuid]];
            }
            for(AccountInfo * account in errorAccounts)
            {
                [self addAccountToFailedAccounts:[account uuid]];
            }
            for(AccountInfo * account in inActiveAccounts)
            {
                [self addAccountToFailedAccounts:[account uuid]];
            }
            
            requestCount = 0;
            requestsFailed = 0;
            requestsFinished = 0;
            
            //setup of the queue
            [favoritesQueue setDelegate:self];
            [favoritesQueue setShowAccurateProgress:NO];
            [favoritesQueue setShouldCancelAllRequestsOnFailure:NO];
            [favoritesQueue setRequestDidFailSelector:@selector(requestFailed:)];
            [favoritesQueue setRequestDidFinishSelector:@selector(requestFinished:)];
            [favoritesQueue setQueueDidFinishSelector:@selector(queueFinished:)];
            
            showOfflineAlert = NO;
            [favoritesQueue go];
        }
        else
        {
            // There is no account/alfresco account configured or there's a cloud account with no tenants
            NSString *description = @"There was no request to process";
            [self setError:[NSError errorWithDomain:kFavoriteManagerErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
            
            if (delegate && [delegate respondsToSelector:@selector(favoriteManagerRequestFailed:)])
            {
                [delegate favoriteManagerRequestFailed:self];
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


- (void)loadFavoritesInfo:(NSArray*)nodes withSyncType:(FavoriteRequestType)requestType
{
    requestCount++;
    
    NSString *pattern = @"(";
    
    for (int i=0; i < [nodes count]; i++)
    {
        if (i+1 == [nodes count])
        {
            pattern = [NSString stringWithFormat:@"%@ cmis:objectId = '%@'", pattern, [[nodes objectAtIndex:i] objectNode]];
        }
        else 
        {
            pattern = [NSString stringWithFormat:@"%@ cmis:objectId = '%@' OR ", pattern, [[nodes objectAtIndex:i] objectNode]];
        }
    }
    
    pattern = [NSString stringWithFormat:@"%@)", pattern];
#if MOBILE_DEBUG
    NSLog(@"pattern: %@", pattern);
#endif
    
    if ([nodes count] > 0)
    {
        BaseHTTPRequest *down = [[[CMISFavoriteDocsHTTPRequest alloc] initWithSearchPattern:pattern
                                                                             folderObjectId:nil
                                                                                accountUUID:[[nodes objectAtIndex:0] accountUUID]
                                                                                   tenantID:[[nodes objectAtIndex:0] tenantID]] autorelease];
        
        [(CMISFavoriteDocsHTTPRequest *)down setFavoritesRequestType:requestType];
        
        [favoritesQueue addOperation:down];
    }
    else 
    {
        requestsFinished++;
    }
}


- (void)requestFinished:(ASIHTTPRequest *)request 
{
    if ([request isKindOfClass:[CMISFavoriteDocsHTTPRequest class]])
    {
        requestsFinished++;
        if ([(CMISFavoriteDocsHTTPRequest *)request favoritesRequestType] == kIsSingleRequest)
        {
            NSArray *searchedDocument = [(CMISQueryHTTPRequest *)request results];
            
            if (searchedDocument != nil)
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
    }
    else if ([request isKindOfClass:[FavoritesHttpRequest class]])
    {
        FavoritesHttpRequest *favoritesRequest = (FavoritesHttpRequest *)request;
        
        if ( favoritesRequest.requestType == SyncRequest)
        {
            [_favoriteNodeRefsForAccounts setObject:[favoritesRequest favorites] forKey:favoritesRequest.accountUUID];
            
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
            
            [self loadFavoritesInfo:[nodes autorelease] withSyncType:kIsMultipleRequest];
            
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:favoritesRequest.accountUUID, @"accountUUID", nil];
            [[NSNotificationCenter defaultCenter] postDocumentFavoritedOrUnfavoritedNotificationWithUserInfo:userInfo];
        }
        else if (favoritesRequest.requestType == FavoriteUnfavoriteRequest)
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
            
            if (self.favoriteUnfavoriteAction == ShouldFavorite) 
            {
                if (exists == NO)
                {
                    [newFavoritesList addObject:self.favoriteUnfavoriteNode];
                }
            }
            else 
            {
                if (exists == YES)
                {
                    [newFavoritesList removeObjectAtIndex:existsAtIndex];
                }
            }
            
            [_favoriteNodeRefsForAccounts setObject:newFavoritesList forKey:favoritesRequest.accountUUID];
            
            if(self.favoriteUnfavoriteAction == GetCurrentFavoriteNodesOnly)
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
                updateRequest.delegate = self;
                [updateRequest setRequestType:UpdateFavoritesList];
                
                [updateRequest startAsynchronous];
            }
        }
        else if (favoritesRequest.requestType == UpdateFavoritesList)
        {
            [favoriteUnfavoriteDelegate favoriteUnfavoriteSuccessfull];
            
            FavoriteTableCellWrapper * wrapper = [self findNodeInFavorites:self.favoriteUnfavoriteNode];
            BOOL isFavorite = [self isNodeFavorite:self.favoriteUnfavoriteNode inAccount:self.favoriteUnfavoriteAccountUUID];
            [wrapper setDocument:(isFavorite ? IsFavorite : IsNotFavorite)];
            [wrapper favoriteOrUnfavoriteDocument];
            
            if (isFavorite && ![self isFirstUse])
            {
                NSMutableArray *node = [[NSMutableArray alloc] initWithCapacity:1];
                FavoriteNodeInfo *nodeInfo = [[FavoriteNodeInfo alloc] initWithNode:self.favoriteUnfavoriteNode accountUUID:favoritesRequest.accountUUID tenantID:favoritesRequest.tenantID];
                [node addObject:nodeInfo];
                [nodeInfo release];
                [self loadFavoritesInfo:[node autorelease] withSyncType:kIsSingleRequest];
            }
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.favoriteUnfavoriteAccountUUID, @"accountUUID", nil];
            [[NSNotificationCenter defaultCenter] postDocumentFavoritedOrUnfavoritedNotificationWithUserInfo:userInfo];
        }
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request 
{
    if ([request isKindOfClass:[CMISFavoriteDocsHTTPRequest class]] && [(CMISFavoriteDocsHTTPRequest *)request favoritesRequestType] != kIsSingleRequest)
    {
        requestsFailed++;
        
        [self addAccountToFailedAccounts:[(CMISFavoriteDocsHTTPRequest*)request accountUUID]];
    }
    else if ([request isKindOfClass:[FavoritesHttpRequest class]])
    {
        FavoritesHttpRequest *favoritesRequest = (FavoritesHttpRequest *)request;
        
        if ([favoritesRequest requestType] == SyncRequest)
        {
            [self addAccountToFailedAccounts:[favoritesRequest accountUUID]];
        }
        else if ([favoritesRequest requestType] == UpdateFavoritesList || [favoritesRequest requestType] == FavoriteUnfavoriteRequest)
        { 
            if (favoriteUnfavoriteDelegate && [favoriteUnfavoriteDelegate respondsToSelector:@selector(favoriteUnfavoriteUnsuccessfull)])
            {
                [favoriteUnfavoriteDelegate favoriteUnfavoriteUnsuccessfull];
            }
        }
    }
    //NSLog(@"favorites Request Failed: %@", [request error]);
    
    //Just show one alert if there's no internet connection
    
    if (showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
        showOfflineModeAlert([request.url absoluteString]);
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
        
        if (delegate && [delegate respondsToSelector:@selector(favoriteManagerRequestFailed:)])
        {
            listType = IsLocal;
            
            [delegate favoriteManagerRequestFailed:self];
        }
    }
    else if ((requestsFailed + requestsFinished) == requestCount)
    {
        [self syncAllDocuments];
        
        if(delegate && [delegate respondsToSelector:@selector(favoriteManager:requestFinished:)])
        {
            listType = IsLive;
            
            NSMutableArray * temp = [[self sortArray:self.favorites] mutableCopy];
            self.favorites = temp;
            [temp release];
            [delegate favoriteManager:self requestFinished:[NSArray arrayWithArray:self.favorites]];
            
        }
    }
}

-(void) addAccountToFailedAccounts:(NSString *) accountUUID
{
    if(![self.failedFavoriteRequestAccounts containsObject:accountUUID])
    {
        [self.failedFavoriteRequestAccounts addObject:accountUUID];
    }
}

-(NSArray *) getFavoritesFromLocalIfAvailable
{
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    if ([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference])
    {
        NSMutableArray * localFavorites = [[NSMutableArray alloc] init];
        
        NSEnumerator *folderContents = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:[self applicationSyncedDocsDirectory] isDirectory:YES]
                                                            includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                                               options:NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                          errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                                              NSLog(@"Error retrieving the favorite folder contents in URL: %@ and error: %@", url, @"");
                                                                              return YES;
                                                                          }];
        
        for (NSURL *fileURL in folderContents)
        {
            BOOL isDirectory;
            [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirectory];
            
            NSDictionary * fileDownloadinfo = [fileManager downloadInfoForFilename:[fileURL lastPathComponent]];
            RepositoryItem * item = [[RepositoryItem alloc] initWithDictionary:fileDownloadinfo];
            
            FavoriteTableCellWrapper * cellWrapper = [[FavoriteTableCellWrapper alloc]  initWithRepositoryItem:item];
            
            if([self isDocumentModifiedSinceLastDownload:item])
            {
                [cellWrapper setSyncStatus:SyncWaiting];
                [cellWrapper setActivityType:Upload];
            }
            else 
            {
                [cellWrapper setSyncStatus:SyncOffline];
            }
            
            cellWrapper.accountUUID = [fileDownloadinfo objectForKey:@"accountUUID"];
            
            cellWrapper.fileSize = [FileUtils sizeOfSavedFile:[fileManager pathComponentToFile:[fileURL lastPathComponent]]];
            [localFavorites addObject:cellWrapper];
            
            [cellWrapper release];
            [item release];
        }
        
        NSArray * temp = [[self sortArray:localFavorites] retain];
        [localFavorites release];
        
        return [temp autorelease];
    }
    return nil;
}

-(NSArray *) getLiveListIfAvailableElseLocal
{
    if (listType == IsLive && [[ConnectivityManager sharedManager] hasInternetConnection]) 
    {
        return self.favorites;
    }
    return [self getFavoritesFromLocalIfAvailable];
}

#pragma mark -
#pragma mark CMISServiceManagerService
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
    [self loadFavorites:IsBackgroundSync];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    //if the requests failed for some reason we still want to try and load activities
    // if the activities fail we just ignore all errors
    [self loadFavorites:IsBackgroundSync];
    
}

-(NSArray *) sortArray:(NSArray *) original
{
    NSArray *sortedArray;
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

-(void)syncAllDocuments
{
    FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    if ([self isSyncEnabled] == YES)
    {
        [[FavoritesUploadManager sharedManager] cancelActiveUploads];
        
        NSMutableArray *tempRepos = [[NSMutableArray alloc] init];
        
        for (int i=0; i < [self.favorites count]; i++)
        {
            NSMutableArray * filesToDownload = [[NSMutableArray alloc] init];
            
            FavoriteTableCellWrapper *cellWrapper = [self.favorites objectAtIndex:i];
            cellWrapper.syncStatus = SyncSuccessful;
            
            RepositoryItem * repoItem = cellWrapper.repositoryItem;
            [tempRepos addObject:repoItem];
            
            // getting last modification date from repository item on server
            NSDate * dateFromRemote = nil;
            NSString * lastModifiedDateForRemote = [repoItem.metadata objectForKey:@"cmis:lastModificationDate"];
            if (lastModifiedDateForRemote != nil && ![lastModifiedDateForRemote isEqualToString:@""])
                dateFromRemote = dateFromIso(lastModifiedDateForRemote);
            
            // getting last modification date for repository item from local directory
            NSDictionary * existingFileInfo = [fileManager downloadInfoForFilename:[fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid]]; 
            NSDate * dateFromLocal = nil;
            NSString * lastModifiedDateForLocal =  [[existingFileInfo objectForKey:@"metadata"] objectForKey:@"cmis:lastModificationDate"];
            if (lastModifiedDateForLocal != nil && ![lastModifiedDateForLocal isEqualToString:@""])
                dateFromLocal = dateFromIso(lastModifiedDateForLocal);
            
            if (repoItem.title != nil && ![repoItem.title isEqualToString:@""])
            {
                if ([self isDocumentModifiedSinceLastDownload:repoItem])
                {
                    [self uploadRepositoryItem:cellWrapper.repositoryItem toAccount:cellWrapper.accountUUID withTenantID:cellWrapper.tenantID];
                    [cellWrapper setSyncStatus:SyncWaiting];
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
                                [cellWrapper setActivityType:Download];
                                [filesToDownload addObject:repoItem];
                                [cellWrapper setSyncStatus:SyncWaiting];
                            }
                        }
                        else
                        {
                            [cellWrapper setActivityType:Download];
                            [filesToDownload addObject:repoItem];
                            [cellWrapper setSyncStatus:SyncWaiting];
                        }
                    }
                    else
                    {
                        [cellWrapper setActivityType:Download];
                        [cellWrapper setSyncStatus:SyncLoading];
                    }
                }
            }
            
            [[FavoriteDownloadManager sharedManager] queueRepositoryItems:filesToDownload withAccountUUID:cellWrapper.accountUUID andTenantId:cellWrapper.tenantID];
            [filesToDownload release];
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
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSDictionary * existingFileInfo = [fileManager downloadInfoForFilename:[fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid]]; 
    
    // getting last downloaded date for repository item from local directory
    NSDate * downloadedDate = [existingFileInfo objectForKey:@"lastDownloadedDate"];
    
    // getting downloaded file locally updated Date
    NSError *dateerror;
    
    NSString * pathToSyncedFile = [fileManager pathToFileDirectory:[fileManager generatedNameForFile:repoItem.title withObjectID:repoItem.guid]];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathToSyncedFile error:&dateerror];
    NSDate * localModificationDate = [fileAttributes objectForKey:NSFileModificationDate];
    
    if ([downloadedDate compare:localModificationDate] == NSOrderedAscending)
    {
        return YES;
    }
    return NO;
}

-(void) deleteUnFavoritedItems:(NSArray*)favorites excludingItemsFromAccounts:(NSArray*) failedAccounts
{   
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    NSDictionary * favoritesMetaData = [fileManager readMetadata];
    NSMutableArray *favoritesKeys = [[NSMutableArray alloc] init];
    NSArray *temp = [favoritesMetaData allKeys];
    
    for (int  i =0; i < [temp count]; i++)
    {
        NSString * accountUDIDForDoc = [[favoritesMetaData objectForKey:[temp objectAtIndex:i]] objectForKey:@"accountUUID"];
        
        if([self string:accountUDIDForDoc existsIn:failedAccounts] == NO)
        {
            [favoritesKeys addObject:[temp objectAtIndex:i]];
        }
        
    }
    
    NSMutableArray *itemsToBeDeleted = [favoritesKeys mutableCopy];
    
    for(NSString * item in favoritesKeys)
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

-(BOOL) string:(NSString*)string existsIn:(NSArray*)array
{
    for(id item in array)
    {
        if ([item isEqualToString:string])
        {
            return YES;
        }
    }
    
    return NO;
}

-(BOOL) checkForObstaclesInRemovingDownloadInfoForFile:(NSString *) filename
{
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    NSDictionary * fileDownloadInfo = [fileManager downloadInfoForFilename:filename];
    
    BOOL isDeletedOnServer = [self isNodeFavorite:[fileDownloadInfo objectForKey:@"objectId"] inAccount:[fileDownloadInfo objectForKey:@"accountUUID"]];
    
    
    // getting last downloaded date for repository item from local directory
    NSDate * downloadedDate = [fileDownloadInfo objectForKey:@"lastDownloadedDate"];
    
    // getting downloaded file locally updated Date
    NSError *dateerror;
    NSString * pathToSyncedFile = [fileManager pathToFileDirectory:filename];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathToSyncedFile error:&dateerror];
    NSDate * localModificationDate = [fileAttributes objectForKey:NSFileModificationDate];
    
    
    BOOL isModifiedLocally = NO;
    if ([downloadedDate compare:localModificationDate] == NSOrderedAscending)
    {
        isModifiedLocally = YES;
    }
    
    BOOL encounteredObstacle = NO;
    NSMutableArray * syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray * syncObstacleUnFavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
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

-(BOOL) didEncounterObstaclesDuringSync
{
    BOOL obstacles = NO;
    
    NSMutableArray * syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray * syncObstacleUnFavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if([syncObstableDeleted count] > 0 || [syncObstacleUnFavorited count] > 0)
    {
        obstacles = YES;
    }
    
    return obstacles;
}

-(void) saveDeletedFavoriteFileBeforeRemovingFromSync:(NSString *) fileName
{
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSDictionary * fileDownloadInfo = [fileManager downloadInfoForFilename:fileName];
    
    [FileUtils saveFileToDownloads:[fileManager pathToFileDirectory:fileName] withName:[fileDownloadInfo objectForKey:@"filename"]]; 
    
    NSMutableArray * syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    [syncObstableDeleted removeObject:fileName];
    
    [fileManager removeDownloadInfoForFilename:fileName];
}

-(void) syncUnfavoriteFileBeforeRemovingFromSync:(NSString *) fileName syncToServer:(BOOL) sync
{
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSDictionary * fileDownloadInfo = [fileManager downloadInfoForFilename:fileName];
    
    if(sync)
    {
        RepositoryItem * item = [[RepositoryItem alloc] initWithDictionary:fileDownloadInfo];
        
        NSArray *linkRelations = [fileDownloadInfo objectForKey:@"linkRelations"];
        for(NSDictionary * link in linkRelations)
        {
            if([[link objectForKey:@"rel"] isEqualToString:@"self"])
            {
                item.selfURL = [link objectForKey:@"href"];
            }
        }
        
        [self uploadRepositoryItem:item toAccount:[fileDownloadInfo objectForKey:@"accountUUID"] withTenantID:nil];
        [item release];
    }
    else 
    {
        [FileUtils saveFileToDownloads:[fileManager pathToFileDirectory:fileName] withName:[fileDownloadInfo objectForKey:@"filename"]];
    }
    
    NSMutableArray * syncObstableUnfavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    [syncObstableUnfavorited removeObject:fileName];
    
    [fileManager removeDownloadInfoForFilename:fileName];
}

-(NSDictionary *) syncObstacles
{
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    NSMutableArray * syncObstacleUnFavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    NSArray * temp = [syncObstacleUnFavorited copy];
    
    for(NSString * item in temp)
    {
        
        NSDictionary * fileDownloadInfo = [fileManager downloadInfoForFilename:item];
        
        if([self findNodeInFavorites:[fileDownloadInfo objectForKey:@""]] != nil)
        {
            [syncObstacleUnFavorited removeObject:item];
        }
    }
    
    [temp release];
    
    return _syncObstacles;
}

-(void) retrySyncForItem:(FavoriteTableCellWrapper *) cellWrapper
{
    if(cellWrapper.activityType == Upload)
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

-(void) uploadRepositoryItem: (RepositoryItem*) repositoryItem toAccount:(NSString *) accountUUID withTenantID:(NSString *) tenantID
{
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    
    NSString * pathToSyncedFile = [fileManager pathToFileDirectory:[fileManager generatedNameForFile:repositoryItem.title withObjectID:repositoryItem.guid]];
    NSURL *documentURL = [NSURL fileURLWithPath:pathToSyncedFile]; 
    
    UploadInfo *uploadInfo = [self uploadInfoFromURL:documentURL];
    
    [uploadInfo setFilename:[repositoryItem.title stringByDeletingPathExtension]];
    [uploadInfo setUpLinkRelation:repositoryItem.selfURL];
    [uploadInfo setSelectedAccountUUID:accountUUID];
    [uploadInfo setRepositoryItem:repositoryItem];
    
    [uploadInfo setTenantID:tenantID];
    
    FavoriteTableCellWrapper *wrapper = [self findNodeInFavorites:repositoryItem.guid];
    [wrapper setUploadInfo:uploadInfo];
    [wrapper setActivityType:Upload];
    
    if(![[FavoritesUploadManager sharedManager] isManagedUpload:uploadInfo.uuid])
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

    if ([fileManager downloadInfoForFilename:fileName] != nil)
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

- (void)favoriteUnfavoriteNode:(NSString *)node withAccountUUID:(NSString *)accountUUID andTenantID:(NSString *)tenantID favoriteAction:(FavoriteUnfavoriteAction)action
{
    if ([[AccountManager sharedManager] isAccountActive:accountUUID])
    {
        self.favoriteUnfavoriteNode = node;
        self.favoriteUnfavoriteAccountUUID = accountUUID;
        self.favoriteUnfavoriteTenantID = tenantID;
        self.favoriteUnfavoriteAction = action;
        
        FavoritesHttpRequest *request = [FavoritesHttpRequest httpRequestFavoritesWithAccountUUID:accountUUID tenantID:tenantID];
        [request setShouldContinueWhenAppEntersBackground:YES];
        [request setSuppressAllErrors:YES];
        [request setRequestType:FavoriteUnfavoriteRequest];
        request.delegate = self;
        
        [request startAsynchronous];
    }
}

# pragma mark - Utility Methods

- (BOOL)isNodeFavorite:(NSString *)nodeRef inAccount:(NSString *)accountUUID
{
    NSArray * favoriteNodeRefs = [_favoriteNodeRefsForAccounts objectForKey:accountUUID];
    
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
        [self startFavoritesRequest:IsManualSync];
        return YES;
    }
    
    return NO;
}

- (NSDictionary *)downloadInfoForDocumentWithID:(NSString *) objectID
{
    FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
    
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
    FavoriteTableCellWrapper * temp = nil;
    for (FavoriteTableCellWrapper * wrapper in self.favorites)
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
    
    [self startFavoritesRequest:IsManualSync];
}

#pragma mark - File system support

- (NSString *)applicationSyncedDocsDirectory
{
	NSString * favDir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"SyncedDocs"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory; 
	// [paths release];
    if (![fileManager fileExistsAtPath:favDir isDirectory:&isDirectory] || !isDirectory)
    {
        NSError *fileError = nil;
        [fileManager createDirectoryAtPath:favDir withIntermediateDirectories:YES attributes:nil error:&fileError];
        
        if (fileError)
        {
            NSLog(@"Error creating the %@ folder: %@", @"Documents", [error description]);
            return  nil;
        }
    }
    
	return favDir; 
}


#pragma mark - Notification Methods

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
    [FavoriteManager sharedManager];
    
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:kSyncAfterDelay target:self selector:@selector(startFavoritesRequest:) userInfo:nil repeats:NO];
}

/**
 * Listening to the reachability changes to update lists and sync
 */
- (void)reachabilityChanged:(NSNotification *)notification
{
    [self startFavoritesRequest:IsBackgroundSync];
}

/**
 * user changed sync preference in settings
 */
- (void)settingsChanged:(NSNotification *)notification
{
    [self startFavoritesRequest:IsBackgroundSync];
}

/**
 * Accounts list changed Notification
 */
- (void)accountsListChanged:(NSNotification *)notification
{    
    NSString *accountID = [notification.userInfo objectForKey:@"uuid"];
    
    if (accountID != nil && ![accountID isEqualToString:@""])
    {
        [self favoriteUnfavoriteNode:@"" withAccountUUID:accountID andTenantID:nil favoriteAction:GetCurrentFavoriteNodesOnly];
    }
}


@end
