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
//  MigrationManager.m
//

#import "MigrationManager.h"
#import "MigrationCommand.h"
#import "AccountMigrationCommand.h"

NSString * const kMigrationLatestVersionKey = @"MigrationLatestVersion";

@implementation MigrationManager

- (void)dealloc
{
    [_migrationCommands release];
    [super dealloc];
}

- (id)initWithMigrationCommands:(NSArray *)migrationCommands
{
    self = [super init];
    if(self)
    {
        _migrationCommands = [[NSArray arrayWithArray:migrationCommands] retain];
    }
    return self;
}

- (void)checkAndRunMigration
{
    CGFloat currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] floatValue];
    CGFloat latestVersion = [[NSUserDefaults standardUserDefaults] floatForKey:kMigrationLatestVersionKey];
    
    if(currentVersion > latestVersion)
    {
        for(id<MigrationCommand> migrationCommand in _migrationCommands)
        {
            if(![migrationCommand isMigrated])
            {
                [migrationCommand runMigration];
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setFloat:currentVersion forKey:kMigrationLatestVersionKey];
    }
}

#pragma mark - Shared Instance

static MigrationManager *sharedMigrationMananger = nil;

+ (MigrationManager *)sharedManager
{
    if (sharedMigrationMananger == nil) {
        AccountMigrationCommand *accountMigration = [[AccountMigrationCommand alloc] init];
        sharedMigrationMananger = [[MigrationManager alloc] initWithMigrationCommands:[NSArray arrayWithObject:accountMigration]];
    }
    return sharedMigrationMananger;
}

@end
