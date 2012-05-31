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
#import "AppProperties.h"

NSString * const kMigrationLatestVersionKey = @"MigrationLatestVersion";

@implementation MigrationManager
@synthesize progressAlertView = _progressAlertView;

- (void)dealloc
{
    [_migrationCommands release];
    [_progressAlertView release];
    [super dealloc];
}

- (id)initWithMigrationCommands:(NSDictionary *)migrationCommands
{
    self = [super init];
    if(self)
    {
        _migrationCommands = [migrationCommands retain];
    }
    return self;
}

- (void)runMigrationWithCurrentVersion:(NSString *)currentVersion
{
    ProgressAlertView *progressView = [[ProgressAlertView alloc] initWithMessage:NSLocalizedString(@"migration.migrateApp.message", @"Migrating the App settings")];
    [self setProgressAlertView:progressView];
    [progressView setMinTime:1.0f];
    [progressView show];
    NSArray *allVersions = [AppProperties propertyForKey:kDevelopmentAllVersions];
    NSArray *versionsToRun = nil;
    BOOL versionFound = NO;
    
    if(currentVersion)
    {
        NSMutableIndexSet *versionIndexes = [NSMutableIndexSet indexSet];
        for(NSInteger index = 0; index < [allVersions count]; index++)
        {
            NSString *version = [allVersions objectAtIndex:index];
            if(versionFound)
            {
                [versionIndexes addIndex:index];
            }
            
            if(!versionFound && [version isEqualToString:currentVersion])
            {
                //Version is found but we don't want to add the version to the versionsToRun
                //since it already ran, we want to add the versions after it
                versionFound = YES;
            }
        }
        
        if([versionIndexes count] > 0)
        {
            versionsToRun = [allVersions objectsAtIndexes:versionIndexes];
        }
    }
    
    if([versionsToRun count] == 0 && !versionFound)
    {
        versionsToRun = allVersions;
    }
    
    for(NSString *version in versionsToRun)
    {
        NSArray *commandsForVersion = [_migrationCommands objectForKey:version];
        for(id<MigrationCommand> migrationCommand in commandsForVersion)
        {
            [migrationCommand runMigration];
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
        NSArray *version13Commands = [NSArray arrayWithObjects:accountMigration, metadataMigration, defaultsMigration, nil];
        NSDictionary *allCommands = [NSDictionary dictionaryWithObject:version13Commands forKey:[AppProperties propertyForKey:kDevelopmentVersion13]];
        
        sharedMigrationMananger = [[MigrationManager alloc] initWithMigrationCommands:allCommands];
        [accountMigration release];
        [metadataMigration release];
        [defaultsMigration release];
    }
    return sharedMigrationMananger;
}

@end
