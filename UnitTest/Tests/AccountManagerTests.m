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
//  AccountManagerTests.m
//  


#import <GHUnitIOS/GHUnit.h>

#import "AccountManager.h"
#import "AccountInfo+Utils.h"
#import "NSUserDefaults+Accounts.h"

@interface AccountManagerTests : GHTestCase 
{
@private
    NSUserDefaults *isolatedDefaults;
} 
@end


@implementation AccountManagerTests

#pragma mark - Setup

- (void)setUp
{
     isolatedDefaults = [[NSUserDefaults alloc] init];
    
    AccountInfo *detailA = [[[AccountInfo alloc] init] autorelease];
    [detailA setVendor:@"Alfresco"];
    [detailA setDescription:@"Description A"];
    [detailA setProtocol:@"http"];
    [detailA setHostname:@"www.ziaconsulting.com"];
    [detailA setPort:@"80"];
    [detailA setServiceDocumentRequestPath:@"/alfresco/service/cmis"];
    [detailA setUsername:@"test"];
    [detailA setPassword:@"password"];
    [detailA setInfoDictionary:[NSDictionary dictionaryWithObject:@"isMultiTenantYes" forKey:@"isMultiTenant"]];
    
    AccountInfo *detailB = [[[AccountInfo alloc] init] autorelease];
    [detailB setVendor:@"Alfresco"];
    [detailB setDescription:@"Description B"];
    [detailB setProtocol:@"https"];
    [detailB setHostname:@"www2.ziaconsulting.com"];
    [detailB setPort:@"443"];
    [detailB setServiceDocumentRequestPath:@"/alfresco/service/cmis"];
    [detailB setUsername:@"username2"];
    [detailB setPassword:@"password2"];
    
    NSMutableArray *accountList = [NSMutableArray arrayWithObjects:detailA, detailB, nil];
    [isolatedDefaults saveAccountList:accountList];
}

- (void)tearDown
{
    [isolatedDefaults release];
}


#pragma mark - Tests

- (void)testAllAccounts
{
    NSMutableArray *result = [[AccountManager sharedManager] allAccounts];
    GHAssertTrue(2 == [result count], @"", nil);
}

- (void)testSaveAccounts
{
    NSMutableArray *result = [[AccountManager sharedManager] allAccounts];
    [result addObject:[[[AccountInfo alloc] init] autorelease]];
    AccountInfo *info = [result objectAtIndex:0];
    [info setUsername:@"TEST_USER"];
    [info setPassword:@"TEST_PASSWORD"];
    [info setDescription:@"TEST_ACCOUNT"];
    
    GHAssertTrue(3 == [result count], @"", nil);
    [[AccountManager sharedManager] saveAccounts:result];
    result = nil;
    info = nil;
    
    result = [[AccountManager sharedManager] allAccounts];
    GHAssertTrue(3 == [result count], @"", nil);
    
    info = [result objectAtIndex:0];
    GHAssertEqualStrings(@"TEST_USER", [info username], @"", nil);
    GHAssertEqualStrings(@"TEST_PASSWORD", [info password], @"", nil);
    GHAssertEqualStrings(@"TEST_ACCOUNT", [info description], @"", nil);
}

- (void)testAddAccountInfo
{
    AccountInfo *account = [[[AccountInfo alloc] init] autorelease];
    [account setVendor:@"Alfresco"];
    [account setDescription:@"NEW ACCOUNT"];
    [account setProtocol:@"HTTPS"];
    [account setHostname:@"www.ziaconsulting.com"];
    [account setPort:@"443"];
    [account setServiceDocumentRequestPath:@"/alfresco/service/cmis"];
    [account setUsername:@"A_USER"];
    [account setPassword:@"A_PASS"];
    
    GHAssertTrue([[AccountManager sharedManager] saveAccountInfo:account], nil,nil);
    
    NSMutableArray *result = [[AccountManager sharedManager] allAccounts];
    GHAssertTrue((3 == [result count]), @"", nil);
    
    AccountInfo *addedAccount = [result lastObject];
    GHAssertNotEqualObjects(account, addedAccount, nil, nil);
    GHAssertTrue([account equals:addedAccount], @"", nil);
    
    GHAssertTrue([[AccountManager sharedManager] saveAccountInfo:account], nil,nil);
    GHAssertTrue([[AccountManager sharedManager] saveAccountInfo:account], nil,nil);
    GHAssertTrue([[AccountManager sharedManager] saveAccountInfo:account], nil,nil);
    
    addedAccount = [result lastObject];
    GHAssertNotEqualObjects(account, addedAccount, nil, nil);
    GHAssertTrue([account equals:addedAccount], @"", nil);
}

- (void)testAccountInfoForUUID
{
    AccountInfo *bogusObject = [[AccountManager sharedManager] accountInfoForUUID:@"BOGUS_123"];
    GHAssertNil(bogusObject, nil, nil);
    
    NSMutableArray *result = [[AccountManager sharedManager] allAccounts];
    for (AccountInfo *account in result) 
    {
        AccountInfo *resultAccount = [[AccountManager sharedManager] accountInfoForUUID:[account uuid]];
        GHAssertNotEqualObjects(account, resultAccount, nil, nil);
        GHAssertTrue([account equals:resultAccount], nil, nil);
    }
}

@end
