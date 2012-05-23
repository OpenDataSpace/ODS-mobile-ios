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
//  UserDefaultsMigrationCommand.m
//

#import "UserDefaultsMigrationCommand.h"

@implementation UserDefaultsMigrationCommand

- (NSArray *) userPreferences {
    NSString *rootPlist = [[NSBundle mainBundle] pathForResource:@"Root" ofType:@"plist"];
    if(!rootPlist) {
        NSLog(@"Could not find Settings.bundle");
        return [NSArray array];
    }
	
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:rootPlist];
    return [settings objectForKey:@"PreferenceSpecifiers"];
}

- (void)migrateKey:(NSString *)key
{
    id currentValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if(currentValue)
    {
        [[FDKeychainUserDefaults standardUserDefaults] setObject:currentValue forKey:key];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

- (BOOL)runMigration
{
    NSArray *allPreferences = [self userPreferences];

    // We migrate all settings with the keys in the user preferences
    for(NSDictionary *preference in allPreferences)
    {
        NSString *key = [preference objectForKey:@"Key"];
        if(key)
        {
            [self migrateKey:key];
        }
    }
    
    //Special keys we should save
    NSDictionary *allDefaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];

    for (NSString* key in allDefaults) 
    {
        //All of the user default keys used
        if ([key hasPrefix:@"first_launch_"] || [key hasPrefix:@"migration."]) 
        {
            [self migrateKey:key];
        }
    }
    [self migrateKey:@"dataProtectionPrompted"];
    [self migrateKey:@"isFirstLaunch"];
    [self migrateKey:@"MultiAccountSetup"];
    [self migrateKey:@"searchSelectedUUID"];
    [self migrateKey:@"searchSelectedTenantID"];
    [self migrateKey:@"showActivitiesTab"];
    
    //Deleting all the other user preference to get rid of old user defaults
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"FirstRun"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES; 
}

- (BOOL)isMigrated:(NSArray *)versionRan
{
    return [versionRan containsObject:[self migrationVersion]];
}

- (NSString *)migrationVersion
{
    return @"32";
}

@end
