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
//  AccountMananger.m
//  


#import "AccountManager.h"
#import "AccountKeychainManager.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "AccountStatusService.h"


@interface AccountManager ()
@end


static NSString * const UUIDPredicateFormat = @"uuid == %@";
static NSString * const kActiveStatusPredicateFormat = @"accountStatus == %d";

@implementation AccountManager

#pragma mark - Instance Methods

- (NSArray *)allAccounts
{
    return ( [NSArray arrayWithArray:[[AccountKeychainManager sharedManager] accountList]] );
}

- (NSArray *)activeAccounts
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ OR accountStatusInfo.isError == YES", kActiveStatusPredicateFormat], FDAccountStatusActive];
    NSArray *array = [NSArray arrayWithArray:[self allAccounts]];
    return [array filteredArrayUsingPredicate:uuidPredicate];
}

- (NSArray *)inactiveAccounts
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ OR accountStatusInfo.isError == YES", kActiveStatusPredicateFormat], FDAccountStatusInactive];
    NSArray *array = [NSArray arrayWithArray:[self allAccounts]];
    return [array filteredArrayUsingPredicate:uuidPredicate];
}

- (NSArray *)awaitingVerificationAccounts
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:kActiveStatusPredicateFormat, FDAccountStatusAwaitingVerification];
    NSArray *array = [NSArray arrayWithArray:[self allAccounts]];
    return [array filteredArrayUsingPredicate:uuidPredicate];
}

- (NSArray *)errorAccounts
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:@"accountStatus == %d OR accountStatus == %d", FDAccountStatusConnectionError, FDAccountStatusInvalidCredentials];
    NSArray *array = [NSArray arrayWithArray:[self allAccounts]];
    return [array filteredArrayUsingPredicate:uuidPredicate];
}

- (NSArray *)noPasswordAccounts
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSString *password = [evaluatedObject password];
        return [password length] == 0;
    }];

    NSArray *array = [NSArray arrayWithArray:[self allAccounts]];
    return [array filteredArrayUsingPredicate:uuidPredicate];
}

- (NSArray *)activeAccountsWithPassword
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSString *password = [evaluatedObject password];
        return [password length] != 0;
    }];
    
    NSArray *array = [NSArray arrayWithArray:[self activeAccounts]];
    return [array filteredArrayUsingPredicate:uuidPredicate];
}

- (NSArray *)passwordAccounts
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSString *password = [evaluatedObject password];
        return [password length] != 0;
    }];
    NSArray *array = [NSArray arrayWithArray:[self allAccounts]];
    
    return [array filteredArrayUsingPredicate:uuidPredicate];
}

- (BOOL)saveAccounts:(NSArray *)accountArray
{
    return [self saveAccounts:accountArray withNotification:YES];
}

- (BOOL)saveAccounts:(NSArray *)accountArray withNotification:(BOOL)notification
{
    //
    // TODO Add some type of validation before we save the account list
    //
    BOOL success = [[AccountKeychainManager sharedManager] saveAccountList:[NSMutableArray arrayWithArray:accountArray]];
    if (success && notification)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:kAccountUpdateNotificationAllAccounts forKey:@"type"]; 
        [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:userInfo];
    }
    return success;
}

- (BOOL)saveAccountInfo:(AccountInfo *)accountInfo
{
    return [self saveAccountInfo:accountInfo withNotification:YES];
}

- (BOOL)saveAccountInfo:(AccountInfo *)accountInfo withNotification:(BOOL)notification;
{
    //
    // TODO Add some type of validation before we save the account list
    //
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:UUIDPredicateFormat, [accountInfo uuid]];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self allAccounts]];
    NSArray *accountFiltered = [array filteredArrayUsingPredicate:uuidPredicate];
    
    if([accountFiltered count] > 0)
    {
        // To preserve the position of the account in the array
        AccountInfo *oldAccount = [accountFiltered objectAtIndex:0];
        NSInteger index = [array indexOfObject:oldAccount];
        [array removeObjectsInArray:accountFiltered];
        [array insertObject:accountInfo atIndex:index];
    }
    else
    {
        //New account, persist account status
        [[AccountStatusService sharedService] saveAccountStatus:[accountInfo accountStatusInfo]];
        [array addObject:accountInfo];
    }
        
    BOOL success = [self saveAccounts:array withNotification:notification];
    
    // Posting a kNotificationAccountListUpdated notification
    if(success && notification)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[accountInfo uuid], @"uuid", nil]; 
        
        // IF the account filtered by the uuid is empty means that we are adding a new account
        if([accountFiltered count] == 0) 
        {
            //New account
            [userInfo setObject:kAccountUpdateNotificationAdd forKey:@"type"];
        } 
        // Otherwise it means we are updating the account
        else 
        {
            //Edit account
            [userInfo setObject:kAccountUpdateNotificationEdit forKey:@"type"];
        }
        [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:userInfo];
    }
    
    return success;
}

- (BOOL)removeAccountInfo:(AccountInfo *)accountInfo
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:UUIDPredicateFormat, [accountInfo uuid]];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self allAccounts]];
    [array removeObjectsInArray:[array filteredArrayUsingPredicate:uuidPredicate]];
    
    BOOL success = [self saveAccounts:array];
    // Posting a kNotificationAccountListUpdated notification
    if(success)
    {
        [[AccountStatusService sharedService] removeAccountStatusForUUID:[accountInfo uuid]];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[accountInfo uuid], @"uuid", kAccountUpdateNotificationDelete, @"type", nil];
        [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:userInfo];
    }
    
    return success;
}

- (AccountInfo *)accountInfoForUUID:(NSString *)uuid
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:UUIDPredicateFormat, uuid];
    NSArray *array = [NSArray arrayWithArray:[self allAccounts]];
    NSArray *filteredArray = [array filteredArrayUsingPredicate:uuidPredicate];
    
    return (([filteredArray count] == 1) ? [filteredArray lastObject] : nil);
}

- (BOOL)isAlfrescoAccountForAccountUUID:(NSString *)uuid
{
    return [[[self accountInfoForUUID:uuid] vendor] isEqualToString:kFDAlfresco_RepositoryVendorName];
}

- (AccountInfo *)accountInfoForHostname:(NSString *)hostname
{
    return [self accountInfoForHostname:hostname includeInactiveAccounts:NO];
}

- (AccountInfo *)accountInfoForHostname:(NSString *)hostname includeInactiveAccounts:(BOOL)includeInactive
{
    NSArray *accounts = (includeInactive ? self.allAccounts : self.activeAccounts);
    
    for (AccountInfo *account in accounts)
    {
        if ([account.hostname caseInsensitiveCompare:hostname] == NSOrderedSame)
        {
            return account;
        }
    }
    
    return nil;
}

- (AccountInfo *)accountInfoForHostname:(NSString *)hostname username:(NSString *)username includeInactiveAccounts:(BOOL)includeInactive
{
    NSArray *accounts = (includeInactive ? self.allAccounts : self.activeAccounts);
    
    for (AccountInfo *account in accounts)
    {
        if ([account.hostname caseInsensitiveCompare:hostname] == NSOrderedSame &&
            [account.username caseInsensitiveCompare:username] == NSOrderedSame)
        {
            return account;
        }
    }
    
    return nil;
}

- (BOOL)isAccountActive:(NSString *)uuid
{
    AccountInfo *accountInfo = [self accountInfoForUUID:uuid];
    return (accountInfo.accountStatus == FDAccountStatusActive);
}

#pragma mark - Singleton

static AccountManager *sharedAccountMananger = nil;

+ (id)sharedManager
{
    if (sharedAccountMananger == nil) {
        sharedAccountMananger = [[super allocWithZone:NULL] init];
    }
    return sharedAccountMananger;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
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
