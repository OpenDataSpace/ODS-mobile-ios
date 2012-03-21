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

@implementation AccountStatusHTTPRequest
@synthesize accountInfo = _accountInfo;
@synthesize accountStatus = _accountStatus;

/*
 STUB METHOD
 Remove when the actual http request is implemented
 */
- (void)startAsynchronous
{
    [self setAccountStatus:FDAccountStatusAwaitingVerification];
    if(self.delegate && [self.delegate respondsToSelector:self.didFinishSelector])
    {
        [self.delegate performSelector:self.didFinishSelector withObject:self];
    }
    else if(self.queue && [self.queue respondsToSelector:self.didFinishSelector])
    {
        [self.queue performSelector:self.didFinishSelector withObject:self];
    }
}

- (void)start
{
    [self startAsynchronous];
}

+ (AccountStatusHTTPRequest *)accountStatusWithAccount:(AccountInfo *)accountInfo
{
    AccountStatusHTTPRequest *request = [AccountStatusHTTPRequest requestWithURL:nil];
    [request setAccountInfo:accountInfo];
    //TODO: Use the API url and fill the parameters with the account information
    return request;
}

@end
