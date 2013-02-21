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
    if (self) 
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
    return [self.statusRequestQueue operationCount] > 0;
}

- (void)requestAllAccountStatus
{
    if (![self queueIsRunning])
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
    AlfrescoLogDebug(@"AccountStatus request for account %@ completed", [originalAccount description]);
}

- (void)requestFailed:(ASIHTTPRequest *)request 
{
    AlfrescoLogDebug(@"AccountStatusHTTPRequest Failed: %@", [request error]);
}

- (void)queueFinished:(ASINetworkQueue *)queue 
{
    AlfrescoLogDebug(@"All AccountStatus requests in the queue finished");
    [self.statusRequestQueue setSuspended:YES];
}

#pragma mark - Singleton

+ (id)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end
