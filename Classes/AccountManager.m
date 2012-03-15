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
#import "NSUserDefaults+Accounts.h"
#import "NSNotificationCenter+CustomNotification.h"


@interface AccountManager ()
@end


static NSString * const UUIDPredicateFormat = @"uuid == %@";

@implementation AccountManager

#pragma mark - Instance Methods

- (NSMutableArray *)allAccounts
{
    return ( [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] accountList]] );
}

- (BOOL)saveAccounts:(NSMutableArray *)accountArray
{
    //
    // TODO Add some type of validation before we save the account list
    //
    return ( [[NSUserDefaults standardUserDefaults] saveAccountList:[NSMutableArray arrayWithArray:accountArray]] );
}

- (BOOL)saveAccountInfo:(AccountInfo *)accountInfo
{
    //
    // TODO Add some type of validation before we save the account list
    //
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:UUIDPredicateFormat, [accountInfo uuid]];
    NSMutableArray *array = [self allAccounts];
    NSArray *accountFiltered = [array filteredArrayUsingPredicate:uuidPredicate];
    [array removeObjectsInArray:accountFiltered];
    
    [array addObject:accountInfo];
    BOOL success = [self saveAccounts:array];
    
    // Posting a kNotificationAccountListUpdated notification
    if(success)
    {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[accountInfo uuid], @"uuid", nil]; 
        
        // IF the account filtered by the uuid is empty means that we are adding a new account
        if([accountFiltered count] == 0) 
        {
            //New account
            [userInfo setObject:kAccountUpdateNotificationAdd forKey:@"type"];
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationAccountListUpdated object:nil];
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
    NSMutableArray *array = [self allAccounts];
    [array removeObjectsInArray:[array filteredArrayUsingPredicate:uuidPredicate]];
    
    BOOL success = [self saveAccounts:array];
    // Posting a kNotificationAccountListUpdated notification
    if(success)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[accountInfo uuid], @"uuid", kAccountUpdateNotificationDelete, @"type", nil];
        [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:userInfo];
    }
    
    return success;
}

- (AccountInfo *)accountInfoForUUID:(NSString *)aUUID
{
    NSPredicate *uuidPredicate = [NSPredicate predicateWithFormat:UUIDPredicateFormat, aUUID];
    NSMutableArray *array = [self allAccounts];
    [array filterUsingPredicate:uuidPredicate];
    
    return (([array count] == 1) ? [array lastObject] : nil);
}

- (BOOL)isAlfrescoAccountForAccountUUID:(NSString *)uuid
{
    return [[[self accountInfoForUUID:uuid] vendor] isEqualToString:kFDAlfresco_RepositoryVendorName];
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
