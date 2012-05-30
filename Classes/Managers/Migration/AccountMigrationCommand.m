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
//  AccountMigrationCommand.m
//

#import "AccountMigrationCommand.h"
#import "NSUserDefaults+Accounts.h"
#import "AccountKeychainManager.h"
#import "AppProperties.h"

NSString * const kAccountMigrationIsMigrated = @"migration.accountMigration.isMigrated";

@implementation AccountMigrationCommand

- (BOOL)runMigration
{
    NSArray *userDefaultAccounts = [[NSUserDefaults standardUserDefaults] accountList];
    NSMutableArray *allAccounts = [NSMutableArray arrayWithArray:userDefaultAccounts];
    
    if(userDefaultAccounts && [userDefaultAccounts count] > 0)
    {
        //Just in case there are accounts already in the keychain
        NSArray *keychainAccounts = [[AccountKeychainManager sharedManager] accountList];
        
        if(keychainAccounts && [keychainAccounts count])
        {
            [allAccounts addObjectsFromArray:keychainAccounts];
        }
        
        [[AccountKeychainManager sharedManager] saveAccountList:allAccounts];
        [[NSUserDefaults standardUserDefaults] removeAccounts];
    }
    
    return YES;
}

- (BOOL)isMigrated:(NSArray *)versionRan
{
    return [versionRan containsObject:[self migrationVersion]];
}

- (NSString *)migrationVersion
{
    return [AppProperties propertyForKey:kDevelopmentVersion13];
}

@end
