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
#import "AccountManager+FileProtection.h"
#import "ProgressAlertView.h"

FileProtectionManager *sharedInstance;
static const BOOL isDevelopment = NO;
static BOOL isDataProtectionEnabled = NO;

static NSInteger const kFileProtectionAvailableTag = 0;
static NSInteger const kProtectDownloadsTag = 1;

@implementation FileProtectionManager
@synthesize progressAlertView = _progressAlertView;

+ (void)initialize
{
    if(isDevelopment)
    {
        [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"dataProtectionPrompted"];
    }
    
    isDataProtectionEnabled = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"dataProtectionEnabled"];
    //Creating the shared instance to initialize the notification observers
    [self sharedInstance];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_progressAlertView release];
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkDataProtection) name:kKeychainUserDefaultsDidChangeNotification object:nil];
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
    BOOL hasQualifyingAccount = [[AccountManager sharedManager] hasQualifyingAccount];
    NSString *dataProtectionEnabled = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:@"dataProtectionEnabled"];
    return [dataProtectionEnabled boolValue] && hasQualifyingAccount;
}

- (void)enterpriseAccountDetected
{
    // We show the alert only if the dataProtectionEnabled user preference is not set
    BOOL dataProtectionPrompted = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"dataProtectionPrompted"];
    if(!dataProtectionPrompted && !_dataProtectionDialog)
    {
        _dataProtectionDialog = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"dataProtection.available.title", @"Data Protection") message:NSLocalizedString(@"dataProtection.available.message", @"Data protection is available. Do you want to enable it?") delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        [_dataProtectionDialog setTag:kFileProtectionAvailableTag];
        
        [_dataProtectionDialog show];
    }
}

#pragma mark -
#pragma mark Alert View Delegate
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if([alertView tag] == kFileProtectionAvailableTag)
    {
        BOOL dataProtectionEnabled = NO;
        if(buttonIndex == 1)
        {
            dataProtectionEnabled = YES;
        }
        [[FDKeychainUserDefaults standardUserDefaults] setBool:dataProtectionEnabled forKey:@"dataProtectionEnabled"];
        [[FDKeychainUserDefaults standardUserDefaults] setBool:YES forKey:@"dataProtectionPrompted"];
        [[FDKeychainUserDefaults standardUserDefaults] synchronize];
        [_dataProtectionDialog release];
        _dataProtectionDialog = nil;
    } 
    else if([alertView tag] == kProtectDownloadsTag)
    {
        if(buttonIndex == 1)
        {
            ProgressAlertView *alertView = [[ProgressAlertView alloc] initWithMessage:@"Testinmg"];
            [self setProgressAlertView:alertView];
            [alertView setMinTime:1.0f];
            [alertView show];
            
            [alertView performSelector:@selector(hide) withObject:nil afterDelay:1.0f];
            
            [alertView release];
        }
    }
}

#pragma mark -
#pragma mark Notification methods
- (void)checkDataProtection
{
    BOOL currentDataProtection = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"dataProtectionEnabled"];
    //Comparing the current data protection value with the previous data protection value
    // If the new value is YES then we prompt the user if the app should protect all the existing downloads
    if(currentDataProtection && !isDataProtectionEnabled)
    {
        UIAlertView *dialog = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"dataProtection.protectDownloads.title", @"Data Protection") message:NSLocalizedString(@"dataProtection.protectDownloads.message", @"Should we protect the existing downloads now? The new downloads will always be protected") delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil] autorelease];
        [dialog setTag:kProtectDownloadsTag];
        
        [dialog show];
    }
    isDataProtectionEnabled = currentDataProtection;
}
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
