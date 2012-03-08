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
#import "MetadataMigrationCommand.h"
#import "UserDefaultsMigrationCommand.h"
#import "ProgressAlertView.h"

NSString * const kMigrationLatestVersionKey = @"MigrationLatestVersion";

@implementation MigrationManager
@synthesize progressAlertView = _progressAlertView;

- (void)dealloc
{
    [_migrationCommands release];
    [_progressAlertView release];
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

- (void)runMigrationWithVersions:(NSArray *)previousVersions;
{
    ProgressAlertView *progressView = [[ProgressAlertView alloc] initWithMessage:NSLocalizedString(@"migration.migrateApp.message", @"Migrating the App settings")];
    [self setProgressAlertView:progressView];
    [progressView setMinTime:1.0f];
    [progressView show];
    
    for(id<MigrationCommand> migrationCommand in _migrationCommands)
    {
        if(![migrationCommand isMigrated:previousVersions] & [migrationCommand runMigration])
        {
            // It sets true the flag that the migration ocurred.
            // This for the case that a app version was skipped by the user and we avoid a version that will always run
            // We exclude that behaviour for the current version.
            NSString *versionMigrated = [migrationCommand migrationVersion];
            NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
            
            if(![bundleVersion isEqualToString:versionMigrated])
            {
                NSString *appFirstStartOfVersionKey = [NSString stringWithFormat:@"first_launch_%@", versionMigrated];
                [[FDKeychainUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:appFirstStartOfVersionKey];
            }
        }
    }
    [progressView hide];
    [progressView release];

}

#pragma mark - Shared Instance

static MigrationManager *sharedMigrationMananger = nil;

+ (MigrationManager *)sharedManager
{
    if (sharedMigrationMananger == nil) {
        AccountMigrationCommand *accountMigration = [[AccountMigrationCommand alloc] init];
        MetadataMigrationCommand *metadataMigration = [[MetadataMigrationCommand alloc] init];
        UserDefaultsMigrationCommand *defaultsMigration = [[UserDefaultsMigrationCommand alloc] init]; 
        sharedMigrationMananger = [[MigrationManager alloc] initWithMigrationCommands:[NSArray arrayWithObjects:accountMigration, metadataMigration, defaultsMigration, nil]];
        [accountMigration release];
        [metadataMigration release];
        [defaultsMigration release];
    }
    return sharedMigrationMananger;
}

@end
