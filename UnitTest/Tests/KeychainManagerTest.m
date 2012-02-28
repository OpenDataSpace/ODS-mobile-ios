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
//  KeychainManagerTest.m
//

#import <GHUnitIOS/GHUnit.h>
#import "AccountInfo.h"
#import "AccountKeychainManager.h"
#import "DataKeychainItemWrapper.h"

@interface KeychainManagerTest : GHTestCase 
{
    AccountKeychainManager *keychainManager;
}

@end

@implementation KeychainManagerTest

#pragma mark - Setup

- (void)setUp
{
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
    DataKeychainItemWrapper *keychain = [[DataKeychainItemWrapper alloc] initWithIdentifier:@"KeychainManagerTest" accessGroup:nil];
    keychainManager = [[AccountKeychainManager alloc] initWithKeychain:keychain];
    [keychainManager saveAccountList:accountList];
    [keychain release];
}

#pragma mark - Tests

- (void)testAllAccounts
{
    NSMutableArray *result = [keychainManager accountList];
    GHAssertTrue(2 == [result count], @"", nil);
}

- (void)testSaveAccounts
{
    NSMutableArray *result = [keychainManager accountList];
    [result addObject:[[[AccountInfo alloc] init] autorelease]];
    AccountInfo *info = [result objectAtIndex:0];
    [info setUsername:@"TEST_USER"];
    [info setPassword:@"TEST_PASSWORD"];
    [info setDescription:@"TEST_ACCOUNT"];
    
    GHAssertTrue(3 == [result count], @"", nil);
    [keychainManager saveAccountList:result];
    result = nil;
    info = nil;
    
    result = [keychainManager accountList];
    GHAssertTrue(3 == [result count], @"", nil);
    
    info = [result objectAtIndex:0];
    GHAssertEqualStrings(@"TEST_USER", [info username], @"", nil);
    GHAssertEqualStrings(@"TEST_PASSWORD", [info password], @"", nil);
    GHAssertEqualStrings(@"TEST_ACCOUNT", [info description], @"", nil);
}

- (void)tearDown
{
    [keychainManager.keychain resetKeychainItem];
    [keychainManager release];
}

@end
