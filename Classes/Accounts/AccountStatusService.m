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
//  AccountStatusService.m
//

#import "AccountStatusService.h"
#import "FileUtils.h"
#import "AccountStatus.h"
NSString * const kAccountStatusStoreFilename = @"AccountStatusDataStore.plist";

@implementation AccountStatusService

- (void)dealloc
{
    [_accountStatusCache release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _accountStatusCache = [[NSKeyedUnarchiver unarchiveObjectWithFile:[FileUtils pathToConfigFile:kAccountStatusStoreFilename]] retain];
        if(!_accountStatusCache)
        {
            _accountStatusCache = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (AccountStatus *)accountStatusForUUID:(NSString *)uuid
{
    return [_accountStatusCache objectForKey:uuid];
}

- (void)saveAccountStatus:(AccountStatus *)accountStatus
{
    [_accountStatusCache setObject:accountStatus forKey:[accountStatus uuid]];
    [self synchronize];
}

- (void)synchronize
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_accountStatusCache];
    NSError *error = nil;
    NSString *path= [FileUtils pathToConfigFile:kAccountStatusStoreFilename];
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
}

#pragma mark - Singleton

static AccountStatusService *sharedAccountService = nil;

+ (id)sharedService
{
    if (sharedAccountService == nil) {
        sharedAccountService = [[super allocWithZone:NULL] init];
    }
    return sharedAccountService;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedService] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end
