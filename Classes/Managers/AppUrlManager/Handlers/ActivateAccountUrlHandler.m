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

@implementation ActivateAccountUrlHandler

- (NSString *)handledUrlPrefix:(NSString *)defaultAppScheme
{
    return [defaultAppScheme stringByAppendingString:@"activate-cloud-account"];
}

- (void)handleUrl:(NSURL *)url annotation:(id)annotation
{
    NSDictionary *queryPairs = [url queryPairs];
    BOOL awaiting = [[queryPairs objectForKey:@"awaiting"] boolValue];
    NSArray *pathComponents = [url pathComponents];
    
    if([pathComponents count] == 2)
    {
        //The first path component is "/"
        NSString *registrationId = [pathComponents objectAtIndex:1];
        NSArray *accounts = [[AccountManager sharedManager] allAccounts];
        NSPredicate *cloudIdPredicate = [NSPredicate predicateWithFormat:@"cloudId == %@", registrationId];
        
        NSArray *filteredAccounts = [accounts filteredArrayUsingPredicate:cloudIdPredicate];
        for(AccountInfo *accountInfo in filteredAccounts)
        {
            if(awaiting)
            {
                [accountInfo setAccountStatus:FDAccountStatusAwaitingVerification];
            }
            else
            {
                [accountInfo setAccountStatus:FDAccountStatusActive];
            }
            
            [[AccountManager sharedManager] saveAccountInfo:accountInfo];
        }
        
        if(![registrationId isNotEmpty])
        {
            AlfrescoLogDebug(@"No registration-id in the incoming url %@", url);
        } 
        else if([registrationId isNotEmpty] && [filteredAccounts count] == 0)
        {
            AlfrescoLogDebug(@"No account found with the registration-id %@", registrationId);
        }
    }
    else
    {
        AlfrescoLogDebug(@"Incorrect number of path components. Sample: alfresco://activate-cloud-account/activiti$1106914");
    }
}

@end
