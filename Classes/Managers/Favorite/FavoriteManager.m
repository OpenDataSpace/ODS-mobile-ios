//
//  FavoriteManager.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
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
#import "FavoriteFileUtils.h"
#import "Utility.h"
#import "FavoriteTableCellWrapper.h"

#import "UploadInfo.h"
#import "UploadsManager.h"
#import "UploadFormTableViewController.h"
#import "IFTemporaryModel.h"

#import "ISO8601DateFormatter.h"

NSString * const kFavoriteManagerErrorDomain = @"FavoriteManagerErrorDomain";

NSString * const kSavedFavoritesFile = @"favorites.plist";

@interface FavoriteManager () // Private
@property (atomic, readonly) NSMutableArray *favorites;
@property (atomic, readonly) NSMutableArray *failedFavoriteRequestAccounts;
@property (atomic, readonly) NSMutableArray *repositoryItems;
@end

@implementation FavoriteManager

@synthesize favorites = _favorites; // Private
@synthesize repositoryItems = _repositoryItems;
@synthesize failedFavoriteRequestAccounts = _failedFavoriteRequestAccounts;

@synthesize favoritesQueue;
@synthesize error;
@synthesize delegate;


- (void)dealloc 
{
    [_favorites release];
    [_repositoryItems release];
    [_failedFavoriteRequestAccounts release];
    
    [favoritesQueue cancelAllOperations];
    [favoritesQueue release];
    [error release];
    
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        _favorites = [[NSMutableArray array] retain];
        _repositoryItems = [[NSMutableArray array] retain];
        _failedFavoriteRequestAccounts = [[NSMutableArray array] retain];
        
        requestCount = 0;
        requestsFailed = 0;
        requestsFinished = 0;
        
    }
    return self;
}

- (void)loadRepositoryInfo
{
    [[CMISServiceManager sharedManager] addQueueListener:self];
    //If the cmisservicemanager is running we need to wait for it to finish, and then load the requests
    //since it may be requesting only the accounts with credentials, we need it to load all accounts
    if(![[CMISServiceManager sharedManager] isActive])
    {
        loadedRepositoryInfos = YES;
        [[CMISServiceManager sharedManager] loadAllServiceDocuments];
    }
}

- (void)loadFavorites
{
    static NSString *KeyPath = @"tenantID";
    if(!favoritesQueue || [favoritesQueue requestsCount] == 0) 
    {
        RepositoryServices *repoService = [RepositoryServices shared];
        NSArray *accounts = [[AccountManager sharedManager] activeAccounts];
        [self setFavoritesQueue:[ASINetworkQueue queue]];
        
        for(AccountInfo *account in accounts) 
        {
            if([[account vendor] isEqualToString:kFDAlfresco_RepositoryVendorName] && 
               [repoService getRepositoryInfoArrayForAccountUUID:account.uuid]) 
            {
                if (![account isMultitenant]) {
                    FavoritesHttpRequest *request = [FavoritesHttpRequest httpRequestFavoritesWithAccountUUID:[account uuid] 
                                                                                                     tenantID:nil];
                    [request setShouldContinueWhenAppEntersBackground:YES];
                    [request setSuppressAllErrors:YES];
                    [favoritesQueue addOperation:request];
                } 
                else {
                    NSArray *repos = [repoService getRepositoryInfoArrayForAccountUUID:account.uuid];
                    NSArray *tenantIDs = [repos valueForKeyPath:KeyPath];
                    
                    //For cloud accounts, there is one favorites request for each tenant the cloud account contains
                    for (NSString *anID in tenantIDs) 
                    {
                        FavoritesHttpRequest *request = [FavoritesHttpRequest httpRequestFavoritesWithAccountUUID:[account uuid] 
                                                                                                         tenantID:anID];
                        [request setShouldContinueWhenAppEntersBackground:YES];
                        [request setSuppressAllErrors:YES];
                        [favoritesQueue addOperation:request];
                    }
                }
            }
        }
        
        if([favoritesQueue requestsCount] > 0) {
            
            [self.favorites removeAllObjects];
            [self.repositoryItems removeAllObjects];
            [self.failedFavoriteRequestAccounts removeAllObjects];
            
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
        } else { 
            // There is no account/alfresco account configured or there's a cloud account with no tenants
            NSString *description = @"There was no request to process";
            [self setError:[NSError errorWithDomain:kFavoriteManagerErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
            
            if(delegate && [delegate respondsToSelector:@selector(favoriteManagerRequestFailed:)]) {
                [delegate favoriteManagerRequestFailed:self];
                delegate = nil;
            }
        }
    }
    
}

-(void) loadFavoritesInfo:(NSArray*)nodes
{
    [nodes retain];
    
    requestCount++;
    
    NSString *pattern = @"(";
    
    for(int i=0; i < [nodes count]; i++)
    {
        if(i+1 == [nodes count])
        {
            pattern = [NSString stringWithFormat:@"%@ cmis:objectId = '%@'",pattern, [[nodes objectAtIndex:i] objectNode]];
        }
        else 
        {
            pattern = [NSString stringWithFormat:@"%@ cmis:objectId = '%@' OR ",pattern, [[nodes objectAtIndex:i] objectNode]];
        }
    }
    
    pattern = [NSString stringWithFormat:@"%@)",pattern];
    NSLog(@"pattern: %@", pattern);
    if([nodes count] > 0)
    {
        BaseHTTPRequest *down = [[CMISFavoriteDocsHTTPRequest alloc] initWithSearchPattern:pattern folderObjectId:nil 
                                                                               accountUUID:[[nodes objectAtIndex:0] accountUUID] tenantID:[[nodes objectAtIndex:0] tenantID]];
        
        [favoritesQueue addOperation:down];
    }
    
    [nodes release];
}

- (void)startFavoritesRequest 
{
    RepositoryServices *repoService = [RepositoryServices shared];
    NSArray *accounts = [[AccountManager sharedManager] activeAccounts];
    //We have to make sure the repository info are loaded before requesting the favorites
    for(AccountInfo *account in accounts) 
    {
        if(![repoService getRepositoryInfoArrayForAccountUUID:account.uuid])
        {
            loadedRepositoryInfos = NO;
            [self loadRepositoryInfo];
            return;
        }
    }
    
    [self loadFavorites];
}

- (void)requestFinished:(ASIHTTPRequest *)request 
{
    
    if([request isKindOfClass:[CMISFavoriteDocsHTTPRequest class]])
    {
        requestsFinished++;
        NSArray *searchedDocuments = [(CMISQueryHTTPRequest *)request results];
        
        for(RepositoryItem *repoItem in searchedDocuments)
        {
            FavoriteTableCellWrapper *cellWrapper = [[FavoriteTableCellWrapper alloc] initWithRepositoryItem:repoItem];
            
            cellWrapper.accountUUID = [(CMISQueryHTTPRequest *)request accountUUID];
            cellWrapper.tenantID = [(CMISQueryHTTPRequest *)request tenantID];
            
            [self.favorites addObject:cellWrapper];
        }
    }
    else 
    {
        FavoritesHttpRequest *favoritesRequest = (FavoritesHttpRequest *)request;
        
        NSMutableArray *nodes = [[NSMutableArray alloc] init];
        for(NSString *node in [favoritesRequest favorites])
        {
            FavoriteNodeInfo *nodeInfo = [[FavoriteNodeInfo alloc] initWithNode:node accountUUID:favoritesRequest.accountUUID tenantID:favoritesRequest.tenantID];
            [nodes addObject:nodeInfo];
            [nodeInfo release];
        }
        
        [self loadFavoritesInfo:[nodes autorelease]];
        
    }
    
}

- (void)requestFailed:(ASIHTTPRequest *)request 
{
    
    if([request isKindOfClass:[CMISFavoriteDocsHTTPRequest class]])
    {
        requestsFailed++;
        
        //self.failedFavoriteRequests addObject:request.
    }
    else {
        FavoritesHttpRequest *favoritesRequest = (FavoritesHttpRequest *)request;
        
        [self.failedFavoriteRequestAccounts addObject:[favoritesRequest accountUUID]];
    }
    NSLog(@"favorites Request Failed: %@", [request error]);
    //requestsFailed++;
    
    //Just show one alert if there's no internet connection
    if(showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
        showOfflineModeAlert([request.url absoluteString]);
        showOfflineAlert = NO;
    }
    
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    //Checking if all the requests failed
    NSLog(@"========Faiels: %d =========Finished: %d =========== Total Count %d", requestsFailed, requestsFinished, requestCount);
    if(requestsFailed == requestCount) {
        NSString *description = @"All requests failed";
        [self setError:[NSError errorWithDomain:kFavoriteManagerErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
        
        if(delegate && [delegate respondsToSelector:@selector(favoriteManagerRequestFailed:)]) {
            [delegate favoriteManagerRequestFailed:self];
            //delegate = nil;
        }
    } else if((requestsFailed + requestsFinished) == requestCount) {
        if(delegate && [delegate respondsToSelector:@selector(favoriteManager:requestFinished:)]) {
            
            //[self saveFavoritesToPlist];
            [delegate favoriteManager:self requestFinished:[NSArray arrayWithArray:self.favorites]];
            //delegate = nil;
            
            [self syncAllDocuments];
            
        }
    }
}

#pragma mark -
#pragma mark CMISServiceManagerService
- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    NSLog(@"------- request finished");
    
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    if(loadedRepositoryInfos)
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
    [self loadFavorites];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    NSLog(@"$$------- request failed");
    
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    //if the requests failed for some reason we still want to try and load activities
    // if the activities fail we just ignore all errors
    [self loadFavorites];
    
}

#pragma mark -
#pragma mark Singleton

static FavoriteManager *sharedFavoriteManager = nil;

+ (FavoriteManager *)sharedManager
{
    if (sharedFavoriteManager == nil) {
        sharedFavoriteManager = [[super allocWithZone:NULL] init];
    }
    return sharedFavoriteManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

-(void) syncAllDocuments
{
    if([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference] == YES)
        
    {
        NSMutableArray *tempRepos = [[NSMutableArray alloc] init];
        
        for (int i=0; i < [self.favorites count]; i++) {
            
            NSMutableArray * filesToDownload = [[NSMutableArray alloc] init];
            
            FavoriteTableCellWrapper *cellWrapper = [self.favorites objectAtIndex:i];
            cellWrapper.syncStatus = SyncSuccessful;
            
            RepositoryItem * repoItem = cellWrapper.repositoryItem;
            [tempRepos addObject:repoItem];
            
            NSLog(@"Total Favorited files : %d", [self.favorites count]);
            NSDate * dateFromRemote = nil;
            NSString * lastModifiedDateForRemote = [repoItem.metadata objectForKey:@"cmis:lastModificationDate"];
            if (lastModifiedDateForRemote != nil && ![lastModifiedDateForRemote isEqualToString:@""])
                dateFromRemote = dateFromIso(lastModifiedDateForRemote);
            
            NSDictionary * existingFileInfo = [[FavoriteFileDownloadManager sharedInstance] downloadInfoForFilename:repoItem.title]; 
            
            NSDate * dateFromLocal = nil;
            
            NSString * lastModifiedDateForLocal =  [[existingFileInfo objectForKey:@"metadata"] objectForKey:@"cmis:lastModificationDate"];
            if (lastModifiedDateForLocal != nil && ![lastModifiedDateForLocal isEqualToString:@""])
                dateFromLocal = dateFromIso(lastModifiedDateForLocal);
            
            NSLog(@"RemoteMD: %@ ------- LocalMD : %@", dateFromRemote, dateFromLocal );
            
            if(repoItem.title != nil && ![repoItem.title isEqualToString:@""])
            {
                if(dateFromLocal != nil && dateFromRemote != nil)
                {
                    // Check if document is updated on server
                    if([dateFromLocal compare:dateFromRemote] == NSOrderedAscending)
                    {
                        [filesToDownload addObject:repoItem];
                        [cellWrapper setSyncStatus:SyncFailed];
                    }
                }
                else {
                    [filesToDownload addObject:repoItem];
                    [cellWrapper setSyncStatus:SyncFailed];
                }
            }
            
            
            NSLog(@"Number of files to be downloaded: %d", [filesToDownload count]);
            [[FavoriteDownloadManager sharedManager] queueRepositoryItems:filesToDownload withAccountUUID:cellWrapper.accountUUID andTenantId:cellWrapper.tenantID];
            
            [filesToDownload release];
            
        }
        
        [[FavoriteFileDownloadManager sharedInstance] deleteUnFavoritedItems:tempRepos excludingItemsFromAccounts:self.failedFavoriteRequestAccounts];
        
        [tempRepos release];
    }
    else {
        
        [[FavoriteFileDownloadManager sharedInstance] removeDownloadInfoForAllFiles];
    }
}

@end
