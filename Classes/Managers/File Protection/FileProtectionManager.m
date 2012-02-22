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
//  FileProtectionManager.m
//

#import "FileProtectionManager.h"
#import "FileProtectionStrategyProtocol.h"
#import "FileProtectionDefaultStrategy.h"
#import "NoFileProtectionStrategy.h"
#import "ASIDownloadCache.h"

FileProtectionManager *sharedInstance;
static UIAlertView *_dataProtectionDialog;

@implementation FileProtectionManager

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_strategy release];
    [_dataProtectionDialog release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearDownloadCache) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

/*
 * It chooses a given protection strategy depending if the file protection is enabled or not.
 */
- (id<FileProtectionStrategyProtocol>)selectStrategy
{
    if([self isFileProtectionEnabled])
    {
        return [[[FileProtectionDefaultStrategy alloc] init] autorelease];
    } 
    else 
    {
        return [[[NoFileProtectionStrategy alloc] init] autorelease];
    }

}

- (BOOL)completeProtectionForFileAtPath:(NSString *)path
{
    return [[self selectStrategy] completeProtectionForFileAtPath:path];
}

- (BOOL)completeUnlessOpenProtectionForFileAtPath:(NSString *)path
{
    return [[self selectStrategy] completeUnlessOpenProtectionForFileAtPath:path];
}

- (BOOL)isFileProtectionEnabled
{
    NSMutableSet *enterpriseAccounts = [[NSUserDefaults standardUserDefaults] objectForKey:@"enterpriseAccounts"];
    NSString *dataProtectionEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"dataProtectionEnabled"];
    return [dataProtectionEnabled boolValue] && enterpriseAccounts && [enterpriseAccounts count] > 0;
}

- (void)enterpriseAccountDetected
{
    // We show the alert only if the dataProtectionEnabled user preference is not set
    BOOL dataProtectionPrompted = [[NSUserDefaults standardUserDefaults] boolForKey:@"dataProtectionPrompted"];
    if(!dataProtectionPrompted && !_dataProtectionDialog)
    {
        _dataProtectionDialog = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"dataProtection.available.title", @"Data Protection") message:NSLocalizedString(@"dataProtection.available.message", @"Data protection is available. Do you want to enable it?") delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        
        [_dataProtectionDialog show];
    }
}

#pragma mark -
#pragma mark Alert View Delegate
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    BOOL dataProtectionEnabled = NO;
    if(buttonIndex == 1)
    {
        dataProtectionEnabled = YES;
    }
    [[NSUserDefaults standardUserDefaults] setBool:dataProtectionEnabled forKey:@"dataProtectionEnabled"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"dataProtectionPrompted"];
    [_dataProtectionDialog release];
    _dataProtectionDialog = nil;
}

#pragma mark -
#pragma mark Notification methods
/*
 This manager is responsable of clearing the cache because we want to keep the File Protection
 related funcionality in this class.
 */
- (void)clearDownloadCache
{
    if([self isFileProtectionEnabled])
    {
        [[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
    }
}

+ (FileProtectionManager *)sharedInstance
{
    if(!sharedInstance)
    {
        sharedInstance = [[FileProtectionManager alloc] init];
    }
    
    return sharedInstance;
}

@end
