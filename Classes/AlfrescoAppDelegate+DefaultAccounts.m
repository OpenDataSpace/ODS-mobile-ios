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
//  AlfrescoAppDelegate+DefaultAccounts.m
//

#import "AlfrescoAppDelegate+DefaultAccounts.h"
#import "AccountManager.h"

@implementation AlfrescoAppDelegate (DefaultAccounts)

static NSString * const kMultiAccountSetup = @"MultiAccountSetup";
static NSString * const Plist = @"plist";
static NSString * const kDefaultAccountList = @"kDefaultAccountList";

- (BOOL)setupDefaultAccounts
{
    if ([self oldAccountSettingExists]) {
        BOOL migrateSuccess = [self migrateExistingAccount];
        // [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"settingsServiceDocumentURI"];
        if (migrateSuccess) return YES;
        
        // TODO if migrate success NO - inform user
        // TODO if migration fails, do we want to just load defaults?
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:kDefaultAccountsPlist_FileName ofType:Plist];
    NSDictionary *defaultAccountsPlist = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
    
    NSMutableArray *accountList = [NSMutableArray array];
    NSArray *defaultAccounts = [defaultAccountsPlist objectForKey:kDefaultAccountList];
    for (NSDictionary *accountDict in defaultAccounts) 
    {
        AccountInfo *account = [[AccountInfo alloc] init];
        
        [account setVendor:[accountDict objectForKey:@"Vendor"]];
        [account setDescription:[accountDict objectForKey:@"Description"]];
        [account setProtocol:[accountDict objectForKey:@"Protocol"]];
        [account setHostname:[accountDict objectForKey:@"Hostname"]];
        [account setPort:[accountDict objectForKey:@"Port"]];
        [account setServiceDocumentRequestPath:[accountDict objectForKey:@"ServiceDocumentRequestPath"]];
        [account setUsername:[accountDict objectForKey:@"Username"]];
        [account setPassword:[accountDict objectForKey:@"Password"]];
        [account setMultitenant:[accountDict objectForKey:@"Multitenant"]];
        [account setIsDefaultAccount:YES];
        
        [accountList addObject:account];
        [account release];
    }

    return [[AccountManager sharedManager] saveAccounts:accountList];
}

- (BOOL)oldAccountSettingExists
{
    BOOL exists = NO;
    NSDictionary *settingsDict = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    NSArray *keys = [[settingsDict allKeys] copy];
    for (NSString *key in keys) {
        if ([key isEqualToString:@"username"] ||
            [key isEqualToString:@"password"] ||
            [key isEqualToString:@"host"] ||
            [key isEqualToString:@"port"] ||
            [key isEqualToString:@"protocol"] ||
            [key isEqualToString:@"settingsServiceDocumentURI"] )
        {
            exists = YES;
            break;
        }
    }
    [keys release];
    
    return ( exists );
}

- (BOOL)migrateExistingAccount
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *array = [NSMutableArray array];
    AccountInfo *account = [[AccountInfo alloc] init];
    
    [account setVendor:kFDAlfresco_RepositoryVendorName];
    [account setDescription:[userDefaults stringForKey:@"host"]];
    [account setProtocol:[userDefaults objectForKey:@"protocol"]];
    [account setHostname:[userDefaults stringForKey:@"host"]];
    [account setPort:[userDefaults stringForKey:@"port"]];
    [account setServiceDocumentRequestPath:[userDefaults stringForKey:@"settingsServiceDocumentURI"]];
    [account setUsername:[userDefaults stringForKey:@"username"]];
    [account setPassword:[userDefaults stringForKey:@"password"]];
    
    [array addObject:account];
    [account release];
    
    
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"host"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"port"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"protocol"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"settingsServiceDocumentURI"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"webapp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    return [[AccountManager sharedManager] saveAccounts:array];
}

@end
