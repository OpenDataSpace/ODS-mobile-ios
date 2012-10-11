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
#import "SiteInvitationsHTTPRequest.h"
#import "SiteJoinHTTPRequest.h"
#import "SiteLeaveHTTPRequest.h"
#import "SiteRequestToJoinHTTPRequest.h"
#import "SiteCancelJoinRequestHTTPRequest.h"
#import "RepositoryItem.h"
#import "Utility.h"
#import "NSNotificationCenter+CustomNotification.h"

#import <objc/message.h>

NSInteger const kTagAddSiteToFavorites = 0;
NSInteger const kTagRemoveSiteFromFavorites = 1;

@interface SitesManagerService () // Private
@property (atomic, readonly) NSMutableSet *listeners;
@property (nonatomic, assign, readwrite) BOOL hasResults;
@property (nonatomic, assign, readwrite) BOOL isExecuting;
@property (nonatomic, retain) RepositoryItem *requestingSite;
@property (nonatomic, copy) SiteActionsBlock siteActionCompletionBlock;
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
@synthesize siteInvitationsRequest = _siteInvitationsRequest;
@synthesize hasResults = _hasResults;
@synthesize isExecuting = _isExecuting;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;
@synthesize requestingSite = _requestingSite;
@synthesize siteActionCompletionBlock = _siteActionCompletionBlock;
@synthesize invitations = _invitations;

static NSMutableDictionary *sharedInstances;

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_siteActionCompletionBlock release];
    _siteActionCompletionBlock = nil;
    [_listeners release];
    
    [_allSitesRequest clearDelegatesAndCancel];
    [_mySitesRequest clearDelegatesAndCancel];
    [_favoriteSitesRequest clearDelegatesAndCancel];
    [_siteInvitationsRequest clearDelegatesAndCancel];
    
    [_allSites release];
    [_mySites release];
    [_favoriteSites release];
    [_favoriteSiteNames release];
    [_allSitesRequest release];
    [_mySitesRequest release];
    [_favoriteSitesRequest release];
    [_siteInvitationsRequest release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [_requestingSite release];
    [_invitations release];
    [super dealloc];
}

- (id)init 
{
    self = [super init];
    if (self) 
    {
        _listeners = [[NSMutableSet set] retain];
    }
    
    return self;
}

- (void)setSelectedAccountUUID:(NSString *)selectedAccountUUID
{
    [_selectedAccountUUID autorelease];
    _selectedAccountUUID = [selectedAccountUUID retain];
    
    [self invalidateResults];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdatedNotification:) name:kNotificationAccountListUpdated object:nil];
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

- (NSArray *)invitations
{
    return [[_invitations copy] autorelease];
}

#pragma mark - private methods
/*
 * Creates the HTTP requests objects needed for the various requests
 */
-(NSInteger)createRequests
{
    NSInteger numberOfRequests = 0;

    self.allSitesRequest = [SiteListHTTPRequest siteRequestForAllSitesWithAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [self.allSitesRequest setDelegate:self];
    [self.allSitesRequest setSuppressAllErrors:YES];
    numberOfRequests++;
    
    self.mySitesRequest = [SiteListHTTPRequest siteRequestForMySitesWithAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [self.mySitesRequest setDelegate:self];
    [self.mySitesRequest setSuppressAllErrors:YES];
    numberOfRequests++;
    
    self.favoriteSiteNames = [NSMutableArray array];
    self.favoriteSitesRequest = [FavoritesSitesHttpRequest httpRequestFavoriteSitesWithAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [self.favoriteSitesRequest setDelegate:self];
    [self.favoriteSitesRequest setSuppressAllErrors:YES];
    numberOfRequests++;
    
    self.siteInvitationsRequest = [SiteInvitationsHTTPRequest httpRequestSiteInvitationsWithAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [self.siteInvitationsRequest setDelegate:self];
    [self.siteInvitationsRequest setSuppressAllErrors:YES];
    numberOfRequests++;
    
    return numberOfRequests;
}

-(void)cancelOperations 
{
    [BaseHTTPRequest clearPasswordPromptQueue];
    [self.allSitesRequest clearDelegatesAndCancel];
    [self.mySitesRequest clearDelegatesAndCancel];
    [self.favoriteSitesRequest clearDelegatesAndCancel];
    [self.siteInvitationsRequest clearDelegatesAndCancel];
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
        
        self.favoriteSites = [NSMutableArray arrayWithArray:favoriteSitesInfo];
        
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
        [self setFavoriteSiteNames:[NSMutableArray arrayWithArray:[self.favoriteSitesRequest favoriteSites]]];
    }
    else if ([request isEqual:self.siteInvitationsRequest])
    {
        [self setInvitations:[NSMutableDictionary dictionaryWithDictionary:[self.siteInvitationsRequest invitations]]];
    }
    else
    {
        /**
         * A site action has completed
         */
        NSString *siteName = [self.requestingSite.metadata objectForKey:@"shortName"];
        
        if ([request isKindOfClass:[FavoritesSitesHttpRequest class]])
        {
            if (request.tag == kTagAddSiteToFavorites)
            {
                [self.favoriteSiteNames addObject:siteName];
                // Deliberately bypass getter
                [_favoriteSites addObject:self.requestingSite];
                [_favoriteSites sortUsingSelector:@selector(compareTitles:)];
            }
            else if (request.tag == kTagRemoveSiteFromFavorites)
            {
                [self.favoriteSiteNames removeObject:siteName];
                RepositoryItem *site = [self findSiteInArray:self.favoriteSites byGuid:self.requestingSite.guid];
                // Deliberately bypass getter
                [_favoriteSites removeObject:site];
            }
        }
        else if ([request isKindOfClass:[SiteJoinHTTPRequest class]])
        {
            // Deliberately bypass getter
            [_mySites addObject:self.requestingSite];
            [_mySites sortUsingSelector:@selector(compareTitles:)];
        }
        else if ([request isKindOfClass:[SiteLeaveHTTPRequest class]])
        {
            RepositoryItem *site = [self findSiteInArray:self.mySites byGuid:self.requestingSite.guid];
            // Deliberately bypass getter
            [_mySites removeObject:site];
        }
        else if ([request isKindOfClass:[SiteRequestToJoinHTTPRequest class]])
        {
            NSString *taskID = [(SiteRequestToJoinHTTPRequest *)request taskID];
            // Deliberately bypass getter
            [_invitations setObject:taskID forKey:siteName];
        }
        else if ([request isKindOfClass:[SiteCancelJoinRequestHTTPRequest class]])
        {
            // Deliberately bypass getter
            [_invitations removeObjectForKey:siteName];
        }

        if (self.siteActionCompletionBlock)
        {
            self.siteActionCompletionBlock(nil);
        }
        self.requestingSite = nil;
    }
    
    [self checkProgress];
}

/*
 * When any request fail, we cancel all other operations and call the listeners
 * with a siteManagerFailed: message 
 */
- (void)requestFailed:(BaseHTTPRequest *)request
{
    if (([request isKindOfClass:[FavoritesSitesHttpRequest class]] && ![request isEqual:self.favoriteSitesRequest]) ||
        ([request isKindOfClass:[SiteLeaveHTTPRequest class]]))
    {
        if (self.siteActionCompletionBlock)
        {
            self.siteActionCompletionBlock(request.error);
        }
    }
    else
    {
        NSLog(@"Site request failed... cancelling other requests: %@", [request description]);
        if(showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
        {
            showOfflineModeAlert([request.url host]);
            showOfflineAlert = NO;
        }
        
        [self callListeners:@selector(siteManagerFailed:)];
        [self cancelOperations];
        [self invalidateResults];
    }
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
        requestsRunning = [self createRequests];
        self.isExecuting = YES;
        [self.allSitesRequest startAsynchronous];
        [self.mySitesRequest startAsynchronous];
        [self.favoriteSitesRequest startAsynchronous];
        [self.siteInvitationsRequest startAsynchronous];
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
    self.siteInvitationsRequest = nil;
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

- (BOOL)isPendingMemberOfSite:(RepositoryItem *)site
{
    NSString *siteName = [site.metadata objectForKey:@"shortName"];
    return ([self.invitations objectForKey:siteName] != nil);
}

- (RepositoryItem *)findSiteInArray:(NSArray *)array byGuid:(NSString *)guid
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"guid == %@", guid];
    NSArray *filteredArray = [array filteredArrayUsingPredicate:predicate];
    
    return (filteredArray.count == 0) ? nil : [filteredArray objectAtIndex:0];
}

- (void)performAction:(NSString *)actionName onSite:(RepositoryItem *)site completionBlock:(void(^)(NSError *error))completion
{
    [self setSiteActionCompletionBlock:completion];
    // Can't use capitalizedString here as it lowercases the remaining characters
    NSString *capitalizedActionName = [[[actionName substringToIndex:1] uppercaseString] stringByAppendingString:[actionName substringFromIndex:1]];
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"performSiteAction%@:", capitalizedActionName]);
    if ([self respondsToSelector:selector])
    {
        BOOL (*PerformActionSender)(id, SEL, id) = (BOOL (*)(id, SEL, id)) objc_msgSend;
        if (!PerformActionSender(self, selector, site) && completion)
        {
            // action function isn't going to generate an http request, so call the completion block directly now
            completion(nil);
        }
    }
}

- (BOOL)performSiteActionFavorite:(RepositoryItem *)site
{
    // Quick check
    if ([self isFavoriteSite:site])
    {
        // nothing to do
        return NO;
    }

    self.requestingSite = site;
    
    FavoritesSitesHttpRequest *request = [FavoritesSitesHttpRequest httpAddFavoriteSite:[site.metadata objectForKey:@"shortName"] withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [request setTag:kTagAddSiteToFavorites];
    [request setDelegate:self];
    [request startAsynchronous];
    return YES;
}

- (BOOL)performSiteActionUnfavorite:(RepositoryItem *)site
{
    // Quick check
    if (![self isFavoriteSite:site])
    {
        // nothing to do
        return NO;
    }

    self.requestingSite = site;

    FavoritesSitesHttpRequest *request = [FavoritesSitesHttpRequest httpRemoveFavoriteSite:[site.metadata objectForKey:@"shortName"] withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [request setTag:kTagRemoveSiteFromFavorites];
    [request setDelegate:self];
    [request startAsynchronous];
    return YES;
}

- (BOOL)performSiteActionJoin:(RepositoryItem *)site
{
    // Quick check
    if ([self isMemberOfSite:site])
    {
        // nothing to do
        return NO;
    }
    
    self.requestingSite = site;
    
    SiteJoinHTTPRequest *request = [SiteJoinHTTPRequest httpRequestToJoinSite:[site.metadata objectForKey:@"shortName"] withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [request setDelegate:self];
    [request startAsynchronous];
    return YES;
}

- (BOOL)performSiteActionRequestToJoin:(RepositoryItem *)site
{
    // Quick check
    if ([self isMemberOfSite:site] || [self isPendingMemberOfSite:site])
    {
        // nothing to do
        return NO;
    }

    self.requestingSite = site;
    
    SiteRequestToJoinHTTPRequest *request = [SiteRequestToJoinHTTPRequest httpRequestToJoinSite:[site.metadata objectForKey:@"shortName"] withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [request setDelegate:self];
    [request startAsynchronous];
    return YES;
}

- (BOOL)performSiteActionCancelRequest:(RepositoryItem *)site
{
    // Quick check
    if (![self isPendingMemberOfSite:site])
    {
        // nothing to do
        return NO;
    }

    self.requestingSite = site;
    
    NSString *siteName = [site.metadata objectForKey:@"shortName"];
    NSString *taskID = [self.invitations objectForKey:siteName];
    
    if (taskID)
    {
        SiteCancelJoinRequestHTTPRequest *request = [SiteCancelJoinRequestHTTPRequest httpCancelJoinRequest:taskID forSite:siteName withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
        [request setDelegate:self];
        [request startAsynchronous];
        return YES;
    }
    return NO;
}

- (BOOL)performSiteActionLeave:(RepositoryItem *)site
{
    if (![self isMemberOfSite:site])
    {
        // nothing to do
        return NO;
    }
    
    self.requestingSite = site;

    SiteLeaveHTTPRequest *request = [SiteLeaveHTTPRequest httpRequestToLeaveSite:[site.metadata objectForKey:@"shortName"] withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [request setDelegate:self];
    [request startAsynchronous];
    
    return YES;
}

#pragma mark - NSNotification handlers

- (void)handleAccountListUpdatedNotification:(NSNotification *)notification
{
    NSString *accountUUID = [notification.userInfo objectForKey:@"uuid"];
    if ([accountUUID isEqualToString:self.selectedAccountUUID])
    {
        [self invalidateResults];
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
