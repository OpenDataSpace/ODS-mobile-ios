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
//  AddAccountUrlHandler.m
//

#import "AddAccountUrlHandler.h"
#import "AccountInfo.h"
#import "AccountManager.h"
#import "Utility.h"
#import "NSURL+HTTPURLUtils.h"
#import "NSUserDefaults+DefaultPreferences.h"

@implementation AddAccountUrlHandler

- (NSString *)hostHandle
{
    return @"add-account";
}

- (void)handleUrl:(NSURL *)url annotation:(id)annotation
{
    NSLog(@"Adding account from details on URL...");
    
    // get parameter values from URL
    NSDictionary *queryPairs = [url queryPairs];
    
    // get mandatory values
    NSString *username = defaultString((NSString *)[queryPairs objectForKey:@"username"], nil);
    NSString *password = defaultString((NSString *)[queryPairs objectForKey:@"password"], nil);
    NSString *host = defaultString((NSString *)[queryPairs objectForKey:@"host"], nil);
    NSString *port = defaultString((NSString *)[queryPairs objectForKey:@"port"], nil);
    
    // get optional values, with defaults where appropriate
    NSString *description = defaultString((NSString *)[queryPairs objectForKey:@"description"], nil);
    NSString *protocol = defaultString((NSString *)[queryPairs objectForKey:@"protocol"], @"http");
    NSString *webapp = defaultString((NSString *)[queryPairs objectForKey:@"webapp"], @"/alfresco/service/cmis");
    NSString *multitenant = defaultString((NSString *)[queryPairs objectForKey:@"multitenant"], @"NO");
    NSString *vendor = defaultString((NSString *)[queryPairs objectForKey:@"vendor"], kFDAlfresco_RepositoryVendorName);
    
    // if there's enough info provided, create the account
    if (username != nil && password != nil && host != nil && port != nil)
    {
        AccountInfo *incomingAccountInfo = [[AccountInfo alloc] init];
        [incomingAccountInfo setUsername:username];
        [incomingAccountInfo setPassword:password];
        [incomingAccountInfo setHostname:host];
        [incomingAccountInfo setPort:port];
        [incomingAccountInfo setProtocol:protocol];
        [incomingAccountInfo setServiceDocumentRequestPath:webapp];
        [incomingAccountInfo setVendor:vendor];
        
        if (description != nil)
        {
            [incomingAccountInfo setDescription:description];
        }
        else
        {
            [incomingAccountInfo setDescription:[NSString stringWithFormat:@"%@@%@", username, host]];
        }
        
        if ([multitenant isEqualToString:@"True"] || [multitenant isEqualToString:@"YES"])
        {
            [incomingAccountInfo setMultitenant:[NSNumber numberWithBool:YES]];
        }
        
        [[AccountManager sharedManager] saveAccountInfo:incomingAccountInfo];
        [incomingAccountInfo release];
    }
    else 
    {
        NSLog(@"URL did not contain enough information to create account; host, port, username and password are required!");
    }
}

@end
