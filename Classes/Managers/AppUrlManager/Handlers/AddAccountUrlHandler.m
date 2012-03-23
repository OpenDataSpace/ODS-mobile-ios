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
    NSDictionary *queryPairs = [url queryPairs];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *username = defaultString((NSString *)[queryPairs objectForKey:@"username"], @"");
    NSString *password = defaultString((NSString *)[queryPairs objectForKey:@"password"], @"");
    NSString *host = defaultString((NSString *)[queryPairs objectForKey:@"host"], (NSString*)[userDefaults defaultPreferenceForKey:@"host"]);
    NSString *port = defaultString((NSString *)[queryPairs objectForKey:@"port"], (NSString*)[userDefaults defaultPreferenceForKey:@"port"]);
    NSString *protocol = defaultString((NSString *)[queryPairs objectForKey:@"protocol"], (NSString *)[userDefaults defaultPreferenceForKey:@"protocol"]);
    NSString *webapp = defaultString((NSString *)[queryPairs objectForKey:@"webapp"], (NSString *)[userDefaults defaultPreferenceForKey:@"webapp"]);
    NSString *vendor = defaultString((NSString *)[queryPairs objectForKey:@"vendor"], kFDAlfresco_RepositoryVendorName);
    
    AccountInfo *incomingAccountInfo = [[AccountInfo alloc] init];
    [incomingAccountInfo setUsername:username];
    [incomingAccountInfo setPassword:password];
    [incomingAccountInfo setHostname:host];
    [incomingAccountInfo setPort:port];
    [incomingAccountInfo setProtocol:protocol];
    [incomingAccountInfo setServiceDocumentRequestPath:webapp];
    [incomingAccountInfo setVendor:vendor];
    [incomingAccountInfo setDescription:[NSString stringWithFormat:@"%@@%@", username, host]];
    
    [[AccountManager sharedManager] saveAccountInfo:incomingAccountInfo];
}

@end
