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
//  ActivityManager.m
//

#import "ActivityManager.h"
#import "AccountManager.h"
#import "AccountInfo.h"
#import "RepositoryServices.h"
#import "RepositoryInfo.h"
#import "CMISServiceManager.h"
#import "Utility.h"

NSString * const kActivityManagerErrorDomain = @"ActivityManagerErrorDomain";

@implementation ActivityManager
@synthesize activitiesQueue;
@synthesize activities;
@synthesize error;
@synthesize delegate;

- (void)dealloc {
    [activitiesQueue cancelAllOperations];
    [activitiesQueue release];
    [activities release];
    [error release];
    
    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        activities = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)postActivityType:(NSString *)activityType forSite:(NSString *)site title:(NSString *)activityTitle 
{
    // Do Something?
}

- (void)startActivitiesRequest 
{
    static NSString *KeyPath = @"tenantID";
    
    if(!activitiesQueue || [activitiesQueue requestsCount] == 0) 
    {
        NSArray *accounts = [[AccountManager sharedManager] allAccounts];
        
        [self setActivitiesQueue:[ASINetworkQueue queue]];
        RepositoryServices *repoService = [RepositoryServices shared];
        
        for(AccountInfo *account in accounts) 
        {
            if([[account vendor] isEqualToString:kFDAlfresco_RepositoryVendorName]) 
            {
                if (![account isMultitenant]) {
                    ActivitiesHttpRequest *request = [ActivitiesHttpRequest httpRequestActivitiesForAccountUUID:[account uuid] 
                                                                                                       tenantID:nil];
                    [request setShouldContinueWhenAppEntersBackground:YES];
                    [request setSuppressAllErrors:YES];
                    [activitiesQueue addOperation:request];
                } 
                else {
                    NSArray *repos = [repoService getRepositoryInfoArrayForAccountUUID:account.uuid];
                    NSArray *tenantIDs = [repos valueForKeyPath:KeyPath];
                    
                    //For cloud accounts, there is one activities request for each tenant the cloud account contains
                    for (NSString *anID in tenantIDs) 
                    {
                        ActivitiesHttpRequest *request = [ActivitiesHttpRequest httpRequestActivitiesForAccountUUID:[account uuid] 
                                                                                                           tenantID:anID];
                        [request setShouldContinueWhenAppEntersBackground:YES];
                        [request setSuppressAllErrors:YES];
                        [activitiesQueue addOperation:request];
                    }
                }
            }
        }
        
        if([activitiesQueue requestsCount] > 0) {
            requestCount = [activitiesQueue requestsCount];
            requestsFailed = 0;
            requestsFinished = 0;

            [[self activities] removeAllObjects];
            
            //setup of the queue
            [activitiesQueue setDelegate:self];
            [activitiesQueue setShowAccurateProgress:NO];
            [activitiesQueue setShouldCancelAllRequestsOnFailure:NO];
            [activitiesQueue setRequestDidFailSelector:@selector(requestFailed:)];
            [activitiesQueue setRequestDidFinishSelector:@selector(requestFinished:)];
            [activitiesQueue setQueueDidFinishSelector:@selector(queueFinished:)];
            
            showOfflineAlert = YES;
            [activitiesQueue go];
        } else { 
            // There is no account/alfresco account configured or there's a cloud account with no tenants
            NSString *description = @"There was no request to process";
            [self setError:[NSError errorWithDomain:kActivityManagerErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
            
            if(delegate && [delegate respondsToSelector:@selector(activityManagerRequestFailed:)]) {
                [delegate activityManagerRequestFailed:self];
                delegate = nil;
            }
        }
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    requestsFinished++;
    ActivitiesHttpRequest *activitiesRequest = (ActivitiesHttpRequest *)request;
    [activities addObjectsFromArray:[activitiesRequest activities]];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    NSLog(@"Activities Request Failed: %@", [request error]);
    requestsFailed++;
    
    //Just show one alert if there's no internet connection
    if(showOfflineAlert && ([request.error code] == ASIConnectionFailureErrorType || [request.error code] == ASIRequestTimedOutErrorType))
    {
        showOfflineModeAlert([request.url absoluteString]);
        showOfflineAlert = NO;
    }
}

- (void)queueFinished:(ASINetworkQueue *)queue {
    //Checking if all the requests failed
    if(requestsFailed == requestCount) {
        NSString *description = @"All requests failed";
        [self setError:[NSError errorWithDomain:kActivityManagerErrorDomain code:1 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]]];
        
        if(delegate && [delegate respondsToSelector:@selector(activityManagerRequestFailed:)]) {
            [delegate activityManagerRequestFailed:self];
            delegate = nil;
        }
    } else {
        if(delegate && [delegate respondsToSelector:@selector(activityManager:requestFinished:)]) {
            [delegate activityManager:self requestFinished:[NSArray arrayWithArray:activities]];
            delegate = nil;
        }
    }
}

#pragma mark -
#pragma mark Singleton

static ActivityManager *sharedActivityManager = nil;

+ (ActivityManager *)sharedManager
{
    if (sharedActivityManager == nil) {
        sharedActivityManager = [[super allocWithZone:NULL] init];
    }
    return sharedActivityManager;
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


@end
