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

@interface SitesManagerService () // Private
@property (atomic, readonly) NSMutableSet *listeners;

-(void)createRequests;
-(void)callListeners:(SEL)selector;
-(void)checkProgress;
@end

@implementation SitesManagerService
@synthesize listeners = _listeners;
@synthesize allSites = _allSites;
@synthesize mySites = _mySites;
@synthesize favoriteSites = _favoriteSites;
@synthesize favoriteSiteNames = _favoriteSiteNames;
@synthesize allSitesRequest;
@synthesize mySitesRequest;
@synthesize favoriteSitesRequest;
@synthesize hasResults;
@synthesize isExecuting;
@synthesize selectedAccountUUID;
@synthesize tenantID;

static NSMutableDictionary *sharedInstances;

-(void)dealloc 
{
    [_listeners release];
    
    [allSitesRequest clearDelegatesAndCancel];
    [mySitesRequest clearDelegatesAndCancel];
    [favoriteSitesRequest clearDelegatesAndCancel];
    
    [_allSites release];
    [_mySites release];
    [_favoriteSites release];
    [_favoriteSiteNames release];
    [allSitesRequest release];
    [mySitesRequest release];
    [favoriteSitesRequest release];
    [selectedAccountUUID release];
    [tenantID release];
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
    self.allSitesRequest = [SiteListHTTPRequest siteRequestForAllSitesWithAccountUUID:selectedAccountUUID tenantID:self.tenantID];
    [self.allSitesRequest setDelegate:self];
    [self.allSitesRequest setSuppressAllErrors:YES];
    
    self.mySitesRequest = [SiteListHTTPRequest siteRequestForMySitesWithAccountUUID:selectedAccountUUID tenantID:self.tenantID];
    [self.mySitesRequest setDelegate:self];
    [self.mySitesRequest setSuppressAllErrors:YES];
    
    self.favoriteSiteNames = [NSMutableArray array];
    self.favoriteSitesRequest = [FavoritesSitesHttpRequest httpRequestFavoriteSitesWithAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [self.favoriteSitesRequest setDelegate:self];
    [self.favoriteSitesRequest setSuppressAllErrors:YES];
}

-(void)cancelOperations 
{
    [allSitesRequest clearDelegatesAndCancel];
    [mySitesRequest clearDelegatesAndCancel];
    [favoriteSitesRequest clearDelegatesAndCancel];
    isExecuting = NO;
    hasResults = NO;
}

/*
 * Helper to call all the listeners with a given selector (finish or fail)
 */
-(void)callListeners:(SEL)selector 
{
    for(id listener in self.listeners) 
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
    if(requestsRunning == 0) {
        isExecuting = NO;
        NSMutableArray *favoriteSitesInfo = [NSMutableArray array];
        NSString *shortName = nil;
        for(RepositoryItem *site in self.allSites) {
            shortName = [site.metadata objectForKey:@"shortName"];
            if([self.favoriteSiteNames containsObject:shortName]) {
                [favoriteSitesInfo addObject:site];
            }
        }
        
        self.favoriteSites = [NSArray arrayWithArray:favoriteSitesInfo];
        hasResults = YES;
        [self callListeners:@selector(siteManagerFinished:)];
    }
}

#pragma mark - ASIHTTPRequestDelegate
-(void)requestFinished:(ASIHTTPRequest *)request {
    if ([request isEqual:allSitesRequest]) {
        [self setAllSites:[allSitesRequest results]];
    } else if([request isEqual:mySitesRequest]){
        [self setMySites:[mySitesRequest results]];
    } else if([request isEqual:favoriteSitesRequest]){
        [self setFavoriteSiteNames:[favoriteSitesRequest favoriteSites]];
    }
    
    [self checkProgress];
}

/*
 * When any request fail, we cancel all other operations and call the listeners
 * with a siteManagerFailed: message 
 */
-(void)requestFailed:(BaseHTTPRequest *)request {
    NSLog(@"Site request failed... cancelling other requests: %@", [request description]);
    if(showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
        showOfflineModeAlert([request.url absoluteString]);
        showOfflineAlert = NO;
    }
    
    if ([request.error code] == ASIAuthenticationErrorType)
    {
        NSString *authenticationFailureMessageForAccount = [NSString stringWithFormat:NSLocalizedString(@"authenticationFailureMessageForAccount", @"Please check your username and password"),
                                                            request.accountInfo.description];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"authenticationFailureTitle", @"Authentication Failure Title Text 'Authentication Failure'")
                                                        message:authenticationFailureMessageForAccount
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK button text")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    [self cancelOperations];
    [self invalidateResults];
    [self callListeners:@selector(siteManagerFailed:)];
}

#pragma mark - public methods

-(void)addListener:(id<SitesManagerListener>)newListener 
{
    [self.listeners addObject:newListener];
}

-(void)removeListener:(id<SitesManagerListener>)newListener 
{
    [self.listeners removeObject:newListener];
}

//Will perform all the needed requests to retrieve the sites
-(void)startOperations {
    if (!isExecuting) {
        [self invalidateResults];
        hasResults = NO;
        [self createRequests];
        [allSitesRequest startAsynchronous];
        [mySitesRequest startAsynchronous];
        [favoriteSitesRequest startAsynchronous];
        requestsRunning = 3;
        isExecuting = YES;
        showOfflineAlert = YES;
    } else {
        //Requests executing
    }
}

//Used to signal the siteManager that the current results are no longer valid
-(void)invalidateResults {
    hasResults = NO;
    self.allSitesRequest = nil;
    self.mySitesRequest = nil;
    self.favoriteSitesRequest = nil;
    self.allSites = nil;
    self.mySites = nil;
    self.favoriteSites = nil;
    self.favoriteSiteNames = nil;
    NSLog(@"Invalidating SitesManagerService results");
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
    if(sharedInstances == nil) {
        sharedInstances = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary *tenants = [sharedInstances objectForKey:uuid];
    if(tenants == nil){
        tenants = [NSMutableDictionary dictionary];
        [sharedInstances setObject:tenants forKey:uuid];
    }
    
    if(aTenantID == nil) {
        aTenantID = kDefaultTenantID;
    }
                           
    SitesManagerService *sharedInstance = [tenants objectForKey:aTenantID];
    if(sharedInstance == nil) {
        sharedInstance = [[[SitesManagerService alloc] init] autorelease];
        [sharedInstance setSelectedAccountUUID:uuid];
        [sharedInstance setTenantID:aTenantID];
        [tenants setObject:sharedInstance forKey:aTenantID];
    }
                           
    return sharedInstance;
}
@end
