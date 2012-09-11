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
//  SitesManagerService.m
//

#import "SitesManagerService.h"
#import "SiteListHTTPRequest.h"
#import "FavoritesSitesHttpRequest.h"
#import "RepositoryServices.h"
#import "RepositoryItem.h"
#import "Utility.h"

NSInteger const kTagRequestSiteFavorites = 0;
NSInteger const kTagAddSiteToFavorites = 1;
NSInteger const kTagRemoveSiteFromFavorites = 1;

@interface SitesManagerService () // Private
@property (atomic, readonly) NSMutableSet *listeners;
@property (nonatomic, assign, readwrite) BOOL hasResults;
@property (nonatomic, assign, readwrite) BOOL isExecuting;
@property (nonatomic, retain) RepositoryItem *requestingSite;
@end

@implementation SitesManagerService
@synthesize listeners = _listeners;
@synthesize allSites = _allSites;
@synthesize mySites = _mySites;
@synthesize favoriteSites = _favoriteSites;
@synthesize favoriteSiteNames = _favoriteSiteNames;
@synthesize allSitesRequest = _allSitesRequest;
@synthesize mySitesRequest = _mySitesRequest;
@synthesize favoriteSitesRequest = _favoriteSitesRequest;
@synthesize hasResults = _hasResults;
@synthesize isExecuting = _isExecuting;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;
@synthesize requestingSite = _requestingSite;

static NSMutableDictionary *sharedInstances;

-(void)dealloc 
{
    [_listeners release];
    
    [_allSitesRequest clearDelegatesAndCancel];
    [_mySitesRequest clearDelegatesAndCancel];
    [_favoriteSitesRequest clearDelegatesAndCancel];
    
    [_allSites release];
    [_mySites release];
    [_favoriteSites release];
    [_favoriteSiteNames release];
    [_allSitesRequest release];
    [_mySitesRequest release];
    [_favoriteSitesRequest release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [_requestingSite release];
    [super dealloc];
}

-(id)init 
{
    self = [super init];
    if(self) 
    {
        _listeners = [[NSMutableSet set] retain];
    }
    
    return self;
}

#pragma mark - Array thread safe
- (NSArray *)allSites
{
    return [[_allSites copy] autorelease];
}

- (NSArray *)mySites
{
    return [[_mySites copy] autorelease];
}

- (NSArray *)favoriteSites
{
    return [[_favoriteSites copy] autorelease];
}

#pragma mark - private methods
/*
 * Creates the HTTP requests objects needed for the three requests
 */
-(void)createRequests 
{
    self.allSitesRequest = [SiteListHTTPRequest siteRequestForAllSitesWithAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [self.allSitesRequest setDelegate:self];
    [self.allSitesRequest setSuppressAllErrors:YES];
    
    self.mySitesRequest = [SiteListHTTPRequest siteRequestForMySitesWithAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [self.mySitesRequest setDelegate:self];
    [self.mySitesRequest setSuppressAllErrors:YES];
    
    self.favoriteSiteNames = [NSMutableArray array];
    self.favoriteSitesRequest = [FavoritesSitesHttpRequest httpRequestFavoriteSitesWithAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [self.favoriteSitesRequest setTag:kTagRequestSiteFavorites];
    [self.favoriteSitesRequest setDelegate:self];
    [self.favoriteSitesRequest setSuppressAllErrors:YES];
}

-(void)cancelOperations 
{
    [BaseHTTPRequest clearPasswordPromptQueue];
    [self.allSitesRequest clearDelegatesAndCancel];
    [self.mySitesRequest clearDelegatesAndCancel];
    [self.favoriteSitesRequest clearDelegatesAndCancel];
    self.isExecuting = NO;
    self.hasResults = NO;
}

/*
 * Helper to call all the listeners with a given selector (finish or fail)
 */
-(void)callListeners:(SEL)selector 
{
    // Local copy to prevent "Collection mutated while being enumerated" exception
    NSSet *listeners = [NSSet setWithSet:self.listeners];

    for(id listener in listeners) 
    {
        if([listener respondsToSelector:selector]) 
        {
            [listener performSelector:selector withObject:self];
        }
    }
}

/*
 * Checks the progress by comparing the requestRunning integer to 0
 * If it's 0 it means all the requests are finished and proceeds to 
 * search for the site information that matches the favorites sites names and
 * call the listeners with a success.
 */
-(void)checkProgress 
{
    requestsRunning--;
    if (requestsRunning == 0)
    {
        self.isExecuting = NO;
        NSMutableArray *favoriteSitesInfo = [NSMutableArray array];
        NSString *shortName = nil;
        for (RepositoryItem *site in self.allSites)
        {
            shortName = [site.metadata objectForKey:@"shortName"];
            if ([self.favoriteSiteNames containsObject:shortName])
            {
                [favoriteSitesInfo addObject:site];
            }
        }
        
        self.favoriteSites = [NSArray arrayWithArray:favoriteSitesInfo];
        self.hasResults = YES;
        [self callListeners:@selector(siteManagerFinished:)];
    }
}

#pragma mark - ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    if ([request isEqual:self.allSitesRequest])
    {
        [self setAllSites:[self.allSitesRequest results]];
    }
    else if ([request isEqual:self.mySitesRequest])
    {
        [self setMySites:[self.mySitesRequest results]];
    }
    else if ([request isEqual:self.favoriteSitesRequest])
    {
        if (request.tag == kTagRequestSiteFavorites)
        {
            [self setFavoriteSiteNames:(NSMutableArray *)[self.favoriteSitesRequest favoriteSites]];
        }
        else
        {
            NSString *siteName = [self.requestingSite.metadata objectForKey:@"shortName"];
            if (request.tag == kTagAddSiteToFavorites)
            {
                [self.favoriteSiteNames addObject:siteName];
                [self.favoriteSites addObject:self.requestingSite];
                self.requestingSite = nil;
            }
            else if (request.tag == kTagRemoveSiteFromFavorites)
            {
                [self.favoriteSiteNames removeObject:siteName];
                RepositoryItem *site = [self findSiteInArray:self.favoriteSites byGuid:self.requestingSite.guid];
                [self.favoriteSites removeObject:site];
                self.requestingSite = nil;
            }
        }
    }
    
    [self checkProgress];
}

/*
 * When any request fail, we cancel all other operations and call the listeners
 * with a siteManagerFailed: message 
 */
- (void)requestFailed:(BaseHTTPRequest *)request
{
    NSLog(@"Site request failed... cancelling other requests: %@", [request description]);
    if(showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
        showOfflineModeAlert([request.url absoluteString]);
        showOfflineAlert = NO;
    }
    
    [self callListeners:@selector(siteManagerFailed:)];
    [self cancelOperations];
    [self invalidateResults];
}

#pragma mark - public methods

- (void)addListener:(id<SitesManagerListener>)newListener 
{
    [self.listeners addObject:newListener];
}

- (void)removeListener:(id<SitesManagerListener>)newListener 
{
    [self.listeners removeObject:newListener];
}

//Will perform all the needed requests to retrieve the sites
- (void)startOperations
{
    if (!self.isExecuting)
    {
        [self invalidateResults];
        self.hasResults = NO;
        [self createRequests];
        requestsRunning = 3;
        self.isExecuting = YES;
        [self.allSitesRequest startAsynchronous];
        [self.mySitesRequest startAsynchronous];
        [self.favoriteSitesRequest startAsynchronous];
        showOfflineAlert = YES;
    }
}

//Used to signal the siteManager that the current results are no longer valid
- (void)invalidateResults
{
    self.hasResults = NO;
    self.allSitesRequest = nil;
    self.mySitesRequest = nil;
    self.favoriteSitesRequest = nil;
    self.allSites = nil;
    self.mySites = nil;
    self.favoriteSites = nil;
    self.favoriteSiteNames = nil;
    NSLog(@"Invalidating SitesManagerService results");
}

- (BOOL)isFavoriteSite:(RepositoryItem *)site
{
    // Quick check
    if ([self.favoriteSites indexOfObject:site] != NSNotFound)
    {
        return YES;
    }
    
    return [self findSiteInArray:self.favoriteSites byGuid:site.guid] != nil;
}

- (BOOL)isMemberOfSite:(RepositoryItem *)site
{
    // Quick check
    if ([self.mySites indexOfObject:site] != NSNotFound)
    {
        return YES;
    }

    return [self findSiteInArray:self.mySites byGuid:site.guid] != nil;
}

- (RepositoryItem *)findSiteInArray:(NSArray *)array byGuid:(NSString *)guid
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"guid == %@", guid];
    NSArray *filteredArray = [array filteredArrayUsingPredicate:predicate];
    
    return (filteredArray.count == 0) ? nil : [filteredArray objectAtIndex:0];
}

- (void)favoriteSite:(RepositoryItem *)site
{
    // Quick check
    if ([self isFavoriteSite:site])
    {
        // nothing to do
        return;
    }

    self.requestingSite = site;
    
    FavoritesSitesHttpRequest *request = [FavoritesSitesHttpRequest httpAddFavoriteSite:[site.metadata objectForKey:@"shortName"] withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [request setTag:kTagAddSiteToFavorites];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)unfavoriteSite:(RepositoryItem *)site
{
    // Quick check
    if (![self isFavoriteSite:site])
    {
        // nothing to do
        return;
    }

    self.requestingSite = site;

    FavoritesSitesHttpRequest *request = [FavoritesSitesHttpRequest httpRemoveFavoriteSite:[site.metadata objectForKey:@"shortName"] withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [request setTag:kTagRemoveSiteFromFavorites];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)joinSite:(RepositoryItem *)site
{
    // Quick check
    if ([self isMemberOfSite:site])
    {
        // nothing to do
        return;
    }
    
}

- (void)requestToJoinSite:(RepositoryItem *)site
{
    // Quick check
    if ([self isMemberOfSite:site])
    {
        // nothing to do
        return;
    }
}

- (void)cancelJoinRequestForSite:(RepositoryItem *)site
{
    
}

- (void)leaveSite:(RepositoryItem *)site
{
    if (![self isMemberOfSite:site])
    {
        // nothing to do
        return;
    }
    
}

#pragma mark - static methods
/*
 * sharedInstances is a dictionary with the accountUUID as the key for the entries.
 * Each entry is another dictionary with the tenantID as the key and an instance
 * of this class as an entry.
 * Each time a combination of accountID and tenantID is tried to access any dictionary/instances is created
 * If the tenantID is nil, a special constant kDefaultTenantID is used as the key (non-cloud accounts)
 */
+ (SitesManagerService *)sharedInstanceForAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    if (sharedInstances == nil)
    {
        sharedInstances = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary *tenants = [sharedInstances objectForKey:uuid];
    if (tenants == nil)
    {
        tenants = [NSMutableDictionary dictionary];
        [sharedInstances setObject:tenants forKey:uuid];
    }
    
    if (aTenantID == nil)
    {
        aTenantID = kDefaultTenantID;
    }
                           
    SitesManagerService *sharedInstance = [tenants objectForKey:aTenantID];
    if (sharedInstance == nil)
    {
        sharedInstance = [[[SitesManagerService alloc] init] autorelease];
        [sharedInstance setSelectedAccountUUID:uuid];
        [sharedInstance setTenantID:aTenantID];
        [tenants setObject:sharedInstance forKey:aTenantID];
    }
                           
    return sharedInstance;
}
@end
