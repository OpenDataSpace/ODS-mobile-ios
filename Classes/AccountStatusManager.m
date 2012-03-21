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
//  AccountStatusManager.m
//

#import "AccountStatusManager.h"
#import "ASINetworkQueue.h"
#import "AccountManager.h"
#import "AccountStatusHTTPRequest.h"

@interface AccountStatusManager()
@property (nonatomic, retain) ASINetworkQueue *statusRequestQueue;
@end

@implementation AccountStatusManager
@synthesize statusRequestQueue = _statusRequestQueue;

- (id)init
{
    self = [super init];
    if(self) 
    {
        _statusRequestQueue = [[ASINetworkQueue alloc] init];
        [_statusRequestQueue setDelegate:self];
        [_statusRequestQueue setShowAccurateProgress:NO];
        [_statusRequestQueue setShouldCancelAllRequestsOnFailure:NO];
        [_statusRequestQueue setRequestDidFailSelector:@selector(requestFailed:)];
        [_statusRequestQueue setRequestDidFinishSelector:@selector(requestFinished:)];
        [_statusRequestQueue setQueueDidFinishSelector:@selector(queueFinished:)];
    }
    return self;
}

- (BOOL)queueIsRunning 
{
    return [self statusRequestQueue] && ![[self statusRequestQueue] isSuspended];
}

- (void)requestAllAccountStatus
{
    if(![self queueIsRunning])
    {
        NSArray *accounts = [[AccountManager sharedManager] awaitingVerificationAccounts];
        [[self statusRequestQueue] cancelAllOperations];
        
        for (AccountInfo *accountInfo in accounts) 
        {
            AccountStatusHTTPRequest *request = [AccountStatusHTTPRequest accountStatusWithAccount:accountInfo];
            [request setSuppressAllErrors:YES];
            [[self statusRequestQueue] addOperation:request];
        }
        
        [[self statusRequestQueue] go];
    }
}

#pragma mark - Queue Delegate Methods
- (void)requestFinished:(ASIHTTPRequest *)request 
{
    AccountStatusHTTPRequest *statusRequest = (AccountStatusHTTPRequest *)request;
    NSString *accountUUID = [statusRequest.accountInfo uuid];
    AccountInfo *originalAccount = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
    NSLog(@"AccountStatus request for account %@ completed", [originalAccount description]);
    
    // We want to save the new status only if it's different from the one saved
    if([originalAccount accountStatus] != [statusRequest accountStatus])
    {
        [originalAccount setAccountStatus:[statusRequest accountStatus]];
        [[AccountManager sharedManager] saveAccountInfo:originalAccount];
        NSLog(@"AccountStatus changed for account %@", [originalAccount description]);
    }
    if([self.statusRequestQueue operationCount] == 0)
    {
        [self.statusRequestQueue setSuspended:YES];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request 
{
    NSLog(@"AccountStatusHTTPRequest Failed: %@", [request error]);
    if([self.statusRequestQueue operationCount] == 0)
    {
        [self.statusRequestQueue setSuspended:YES];
    }
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    NSLog(@"All AccountStatus requests in the queue finished");
    [self.statusRequestQueue setSuspended:YES];
}

#pragma mark - Singleton

static AccountStatusManager *sharedStatusManager = nil;

+ (id)sharedManager
{
    if (sharedStatusManager == nil) {
        sharedStatusManager = [[super allocWithZone:NULL] init];
    }
    return sharedStatusManager;
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
