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

NSString * const kMigrationLatestVersionKey = @"MigrationLatestVersion";

@interface MigrationManager (private)
- (MBProgressHUD *)createHUD;
@end

@implementation MigrationManager
@synthesize HUD = _HUD;
@synthesize alertView = _alertView;

- (void)dealloc
{
    [_migrationCommands release];
    [_HUD release];
    [_alertView release];
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

- (void)runMigration
{
    [self setHUD:[self createHUD]];
    [self.HUD show:YES];
    
    for(id<MigrationCommand> migrationCommand in _migrationCommands)
    {
        if(![migrationCommand isMigrated])
        {
            [migrationCommand runMigration];
        }
    }
    
    //[[NSUserDefaults standardUserDefaults] setFloat:currentVersion forKey:kMigrationLatestVersionKey];
    [NSTimer scheduledTimerWithTimeInterval:kHUDMinShowTime target:self selector:@selector(hideHUD) userInfo:nil repeats:NO];

}
         
- (void)hideHUD
{
    [self.HUD hide:YES];
}

#pragma mark - MBProgressHUDDelegate Method
- (void)hudWasHidden
{
    // Remove HUD from screen when the HUD was hidded
    [self.HUD setTaskInProgress:NO];
    [self.HUD removeFromSuperview];
    [self.HUD setDelegate:nil];
    [self setHUD:nil];
    [self.alertView dismissWithClickedButtonIndex:0 animated:YES];
}

#pragma mark - Utility Methods

- (MBProgressHUD *)createHUD
{
    [self setAlertView:[[[UIAlertView alloc] initWithTitle:nil message:@"Migrating the App settings\n\n" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil]  autorelease]];
    MBProgressHUD *tmpHud = [[[MBProgressHUD alloc] initWithView:self.alertView] autorelease];
    [self.alertView addSubview:tmpHud];
    
    [tmpHud setRemoveFromSuperViewOnHide:YES];
    [tmpHud setDelegate:self];
    [tmpHud setTaskInProgress:YES];
    [tmpHud setMinShowTime:kHUDMinShowTime];
    [tmpHud setGraceTime:KHUDGraceTime];
    [self.alertView show];
    
    return tmpHud;
}

#pragma mark - Shared Instance

static MigrationManager *sharedMigrationMananger = nil;

+ (MigrationManager *)sharedManager
{
    if (sharedMigrationMananger == nil) {
        AccountMigrationCommand *accountMigration = [[AccountMigrationCommand alloc] init];
        MetadataMigrationCommand *metadataMigration = [[MetadataMigrationCommand alloc] init];
        sharedMigrationMananger = [[MigrationManager alloc] initWithMigrationCommands:[NSArray arrayWithObjects:accountMigration, metadataMigration, nil]];
        [accountMigration release];
        [metadataMigration release];
    }
    return sharedMigrationMananger;
}

@end
