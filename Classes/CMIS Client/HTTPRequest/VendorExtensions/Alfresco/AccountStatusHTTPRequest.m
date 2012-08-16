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
//  AccountStatusHTTPRequest.m
//

#import "AccountStatusHTTPRequest.h"
#import "AccountManager.h"
#import "SBJSON.h"
#import "AccountStatusService.h"

@implementation AccountStatusHTTPRequest
@synthesize accountInfo = _accountInfo;
@synthesize accountStatus = _accountStatus;

- (void)requestFinishedWithSuccessResponse
{
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:[self.accountInfo uuid]];
    
    //We add a check before trying to make any changes
    //There's a possibility that the user deleted the account WHILE this request was running
    //in that case we ignore the request's response
    if(accountInfo)
    {
        // Means the account was validated
        if(self.responseStatusCode == 404)
        {
            [accountInfo setAccountStatus:FDAccountStatusActive];
        }
        else
        {
            // If we get a response it means the account is still awaiting for verification
            // Still, we will take the "isActivated" field into account to set the status of the account
            SBJSON *jsonObj = [SBJSON new];
            NSMutableDictionary *responseJson = [jsonObj objectWithString:[self responseString]];
            [jsonObj release];
            
            BOOL isActivated = [[responseJson objectForKey:@"isActivated"] boolValue];
            if(isActivated)
            {
                [accountInfo setAccountStatus:FDAccountStatusActive];
            }
            else
            {
                [accountInfo setAccountStatus:FDAccountStatusAwaitingVerification];
            }
        }
        
        [self setAccountStatus:[accountInfo accountStatus]];
        [self setAccountInfo:accountInfo];
        //We just need to synchronize the account status objects in the data store
        [[AccountStatusService sharedService] synchronize];
    }
}

/*
 We have to rewrite the method because the BaseHTTPRequest will catch all 404 requests 
 And since 404 means that the account is activated we need to catch that response.
 */
- (void)requestFinished
{
    if(self.responseStatusCode != 404)
    {
        [super requestFinished];
    }
    else
    {
        NSLog(@"%d: %@", self.responseStatusCode, self.responseString);
        [self setSuppressAllErrors:YES];
        [self requestFinishedWithSuccessResponse];
        [super requestFinished];
    }
}

+ (AccountStatusHTTPRequest *)accountStatusWithAccount:(AccountInfo *)accountInfo
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[accountInfo cloudId], @"ACCOUNTID", [accountInfo cloudKey], @"ACCOUNTKEY", nil];
    AccountStatusHTTPRequest *request = [AccountStatusHTTPRequest requestForServerAPI:kServerAPICloudAccountStatus accountUUID:[accountInfo uuid] tenantID:nil infoDictionary:infoDictionary useAuthentication:NO];
    [request setAccountInfo:accountInfo];
    //TODO: Use the API url and fill the parameters with the account information
    return request;
}

@end
