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
//  PasswordPromptQueue.m
//

#import "PasswordPromptQueue.h"
#import "AccountInfo.h"
#import "AlfrescoAppDelegate.h"
#import "AccountManager.h"
#import "SessionKeychainManager.h"

@interface PasswordPromptQueue ()
@property (nonatomic, retain) NSMutableArray *promptQueue;

@end

@implementation PasswordPromptQueue
@synthesize promptQueue = _promptQueue;

- (void)dealloc
{
    [_promptQueue release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [self setPromptQueue:[NSMutableArray array]];
    }
    return self;
}

- (void)addPromptForRequest:(BaseHTTPRequest *)request
{
    [self.promptQueue addObject:request];
    [self processQueue];
}

- (void)processQueue
{
    if ([self.promptQueue count] > 0 && !promptActive)
    {
        BaseHTTPRequest *nextRequest = [self peekRequest];
        NSString *requestPassword = nextRequest.password;
        NSString *sessionPassword = [[SessionKeychainManager sharedManager] passwordForAccountUUID:nextRequest.accountUUID];
        BOOL sessionPasswordIsBlank = sessionPassword == nil || [sessionPassword isEqualToString:@""];
        
        // Let's check whether we now have a new sessionPassword to prevent multiple sequential prompts
        if (sessionPasswordIsBlank || (nextRequest.responseStatusCode == 401 && [sessionPassword isEqualToString:requestPassword]))
        {
            if (nextRequest.promptPasswordDelegate && nextRequest.willPromptPasswordSelector && [nextRequest.promptPasswordDelegate respondsToSelector:nextRequest.willPromptPasswordSelector])
            {
                [nextRequest.promptPasswordDelegate performSelector:nextRequest.willPromptPasswordSelector withObject:nextRequest];
            }
            
            AccountInfo *nextAccount = [[AccountManager sharedManager] accountInfoForUUID:[nextRequest accountUUID]];
            PasswordPromptViewController *promptController = [[[PasswordPromptViewController alloc] initWithAccountInfo:nextAccount] autorelease];
            [promptController setDelegate:self];
            [promptController setIsRequestForExpiredFiles:nextRequest.isRequestForExpiredFiles];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:promptController];
            [nav setModalPresentationStyle:UIModalPresentationFormSheet];
            [nav setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
            
            if (nextRequest.passwordPromptPresenter != nil)
            {
                [nextRequest.passwordPromptPresenter presentViewController:nav animated:YES completion:NULL];
            }
            else
            {
                AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate presentModalViewController:nav animated:YES];
            }
            [nav release];
            
            promptActive = YES;
        }
        else
        {
            [self dequeueRequest];
            [nextRequest setUsername:nextRequest.accountInfo.username];
            [nextRequest setPassword:sessionPassword];
            [nextRequest retryUsingSuppliedCredentials];
        }
    }
}

#pragma mark - PasswordPromptDelegate methods
- (void)passwordPrompt:(PasswordPromptViewController *)passwordPrompt savedWithPassword:(NSString *)newPassword
{
    BaseHTTPRequest *nextRequest = [self dequeueRequest];
    [[SessionKeychainManager sharedManager] savePassword:newPassword forAccountUUID:nextRequest.accountUUID];
 
    // If this account had a non-zero length password stored, then we should update it here
    if (nextRequest.accountInfo.password != nil && ![nextRequest.accountInfo.password isEqualToString:@""])
    {
        [nextRequest.accountInfo setPassword:newPassword];
        [[AccountManager sharedManager] saveAccountInfo:nextRequest.accountInfo withNotification:NO];
    }
    
    [passwordPrompt dismissViewControllerAnimated:YES completion:^{
        if (nextRequest.promptPasswordDelegate && nextRequest.finishedPromptPasswordSelector && [nextRequest.promptPasswordDelegate respondsToSelector:nextRequest.finishedPromptPasswordSelector])
        {
            [nextRequest.promptPasswordDelegate performSelector:nextRequest.finishedPromptPasswordSelector withObject:nextRequest];
        }
        
        [nextRequest setUsername:nextRequest.accountInfo.username];
        [nextRequest setPassword:newPassword];
        [nextRequest retryUsingSuppliedCredentials];
        
        // Loop through any pending requests that are for this same account
        // We can then avoid multiple prompts for the same account.
        NSMutableArray *removeArray = [NSMutableArray array];
        for (BaseHTTPRequest *pendingRequest in self.promptQueue)
        {
            if ([pendingRequest.accountUUID isEqualToString:nextRequest.accountUUID])
            {
                AlfrescoLogDebug(@"PasswordPromptQueue: Found matching accountUUID");
                [pendingRequest setUsername:nextRequest.accountInfo.username];
                [pendingRequest setPassword:newPassword];
                [pendingRequest retryUsingSuppliedCredentials];
                [removeArray addObject:pendingRequest];
            }
        }
        AlfrescoLogDebug(@"PasswordPromptQueue: Removing %d requests", removeArray.count);
        [self.promptQueue removeObjectsInArray:removeArray];

        promptActive = NO;
        [self processQueue];
    }];
    
}

- (void)passwordPromptWasCancelled:(PasswordPromptViewController *)passwordPrompt
{
    BaseHTTPRequest *nextRequest = [self dequeueRequest];
    if (nextRequest.promptPasswordDelegate && nextRequest.cancelledPromptPasswordSelector && [nextRequest.promptPasswordDelegate respondsToSelector:nextRequest.cancelledPromptPasswordSelector])
    {
        [nextRequest.promptPasswordDelegate performSelector:nextRequest.cancelledPromptPasswordSelector withObject:nextRequest];
    }

    //When a request did retry and failed for the second time and the user cancels
    //for some possible bug in the ASIHTTPRequest the network indicator is never turned off
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [passwordPrompt dismissViewControllerAnimated:YES completion:^{
        [nextRequest cancelAuthentication];
        // Loop through any pending requests that are for this same account
        // The user is likely to want to cancel all requests for this account
        NSMutableArray *removeArray = [NSMutableArray array];
        for (BaseHTTPRequest *pendingRequest in self.promptQueue)
        {
            if ([pendingRequest.accountUUID isEqualToString:nextRequest.accountUUID])
            {
                [pendingRequest cancelAuthentication];
                [removeArray addObject:pendingRequest];
            }
        }
        [self.promptQueue removeObjectsInArray:removeArray];

        promptActive = NO;
        [self processQueue];
    }];
}


#pragma mark - queue Helpers

- (BaseHTTPRequest *)dequeueRequest
{
    BaseHTTPRequest *headObject = [self.promptQueue objectAtIndex:0];
    if (headObject != nil)
    {
        [[headObject retain] autorelease]; // so it isn't dealloc'ed on remove
        [self.promptQueue removeObjectAtIndex:0];
    }
    return headObject;
}

- (BaseHTTPRequest *)peekRequest
{
    BaseHTTPRequest *headObject = [self.promptQueue objectAtIndex:0];
    return headObject;
}

- (void)clearRequestQueue
{
    [self.promptQueue removeAllObjects];
}

#pragma mark - Singleton

+ (PasswordPromptQueue *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

@end
