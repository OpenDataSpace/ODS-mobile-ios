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
//  ActivateAccountUrlHandler.m
//

#import "ActivateAccountUrlHandler.h"
#import "AccountManager.h"
#import "NSURL+HTTPURLUtils.h"
#import "NSString+Utils.h"

@implementation ActivateAccountUrlHandler

- (NSString *)hostHandle
{
    return @"activate-account";
}

- (void)handleUrl:(NSURL *)url annotation:(id)annotation
{
    NSDictionary *queryPairs = [url queryPairs];
    NSString *email = [queryPairs objectForKey:@"email"];
    NSArray *accounts = [[AccountManager sharedManager] awaitingVerificationAccounts];
    NSPredicate *usernamePredicate = [NSPredicate predicateWithFormat:@"username == %@", email];
    
    NSArray *filteredAccounts = [accounts filteredArrayUsingPredicate:usernamePredicate];
    for(AccountInfo *accountInfo in filteredAccounts)
    {
        [accountInfo setAccountStatus:FDAccountStatusActive];
        [[AccountManager sharedManager] saveAccountInfo:accountInfo];
    }
    
    if(![email isNotEmpty])
    {
        NSLog(@"No 'email' parameter was sent in the URL");
    }
    
    if([email isNotEmpty] && [filteredAccounts count] == 0)
    {
        NSLog(@"No account found with the email %@", email);
    }
}

@end
