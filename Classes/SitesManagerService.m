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
//  SitesManagerService.m
//

#import "SitesManagerService.h"
#import "SiteListDownload.h"
#import "FavoritesSitesHttpRequest.h"
#import "RepositoryServices.h"
#import "RepositoryItem.h"

@interface SitesManagerService(private)
-(void)createRequests;
-(void)callListeners:(SEL)selector;
-(void)checkProgress;
@end

@implementation SitesManagerService
@synthesize allSites;
@synthesize mySites;
@synthesize favoriteSites;
@synthesize favoriteSiteNames;
@synthesize allSitesRequest;
@synthesize mySitesRequest;
@synthesize favoriteSitesRequest;
@synthesize hasResults;
@synthesize isExecuting;

static SitesManagerService *sharedInstance;

-(void)dealloc {
    [super dealloc];
    [allSites release];
    [mySites release];
    [favoriteSites release];
    [favoriteSiteNames release];
    [allSitesRequest release];
    [mySitesRequest release];
    [favoriteSitesRequest release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)init {
    self = [super init];
    if(self) {
        listeners = [[NSMutableSet set] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    
    return self;
}

#pragma mark - private methods
-(void)createRequests {
    self.allSitesRequest = [[[SiteListDownload alloc] initWithDelegate:self] autorelease];
    [allSitesRequest setShowHUD:NO];
    
    self.mySitesRequest = [[[SiteListDownload alloc] initWithMySitesURLAndDelegate:self] autorelease];
    [mySitesRequest setShowHUD:NO];
    
    self.favoriteSitesRequest = [FavoritesSitesHttpRequest httpRequestFavoriteSites];
    self.favoriteSiteNames = [NSMutableArray array];
    [favoriteSitesRequest setDelegate:self];
}

-(void)cancelOperations {
    [allSitesRequest cancel];
    [mySitesRequest cancel];
    [favoriteSitesRequest clearDelegatesAndCancel];
    isExecuting = NO;
    hasResults = NO;
}

-(void)callListeners:(SEL)selector {
    for(id listener in listeners) {
        if([listener respondsToSelector:selector]) {
            [listener performSelector:selector withObject:self];
        }
    }
}

-(void)checkProgress {
    if(![allSitesRequest.httpRequest isExecuting] && ![mySitesRequest.httpRequest isExecuting] && ![favoriteSitesRequest isExecuting]) {
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

#pragma mark - AynchronousDownloadDelegate
- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async {
    if ([async isEqual:allSitesRequest]) {
        [self setAllSites:[allSitesRequest results]];
    } else {
        [self setMySites:[mySitesRequest results]];
    }
    [self checkProgress];
}

- (void) asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error {
    NSLog(@"Site request failed... cancelling other requests: %@", [error description]);
    [self cancelOperations];
    [self invalidateResults];
    [self callListeners:@selector(siteManagerFailed:)];
}

#pragma mark - ASIHTTPRequestDelegate
-(void)requestFinished:(ASIHTTPRequest *)request {
    [self setFavoriteSiteNames:[favoriteSitesRequest favoriteSites]];
    [self checkProgress];
}

-(void)requestFailed:(ASIHTTPRequest *)request {
    NSLog(@"Site request failed... cancelling other requests: %@", [request description]);
    [self cancelOperations];
    [self invalidateResults];
    [self callListeners:@selector(siteManagerFailed:)];
}

#pragma mark - public methods
-(void)addListener:(id<SitesManagerListener>)newListener {
    [listeners addObject:newListener];
}
-(void)removeListener:(id<SitesManagerListener>)newListener {
    [listeners removeObject:newListener];
}
//Will perform all the needed requests to retrieve the sites
-(void)startOperations {
    if([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName] &&!isExecuting) {
        [self invalidateResults];
        hasResults = NO;
        [self createRequests];
        [allSitesRequest start];
        [mySitesRequest start];
        [favoriteSitesRequest startAsynchronous];
        isExecuting = YES;
    } else {
        //Throw an exception, we should only retrieve sites in an Alfresco repository
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
+ (SitesManagerService *)sharedInstance {
    if(sharedInstance == nil) {
        sharedInstance = [[SitesManagerService alloc] init];
    }
    
    return sharedInstance;
}

#pragma mark -
#pragma Global notifications
- (void) applicationWillResignActive:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in SiteManagerService");
    
    [self cancelOperations];
}

@end
