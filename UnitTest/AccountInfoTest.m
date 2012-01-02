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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */

//
//  AccountInfoTest.m
//

#import <GHUnitIOS/GHUnit.h>
#import "AccountInfo.h"
#import "NSUserDefaults+Accounts.h"
#import "AccountInfo+Utils.h"

@interface AccountInfoTest : GHTestCase { }
- (BOOL)keyPathValueAreEqualForKeyPath:(NSString *)keypath objectA:(NSObject *)a objectB:(NSObject *)b;
@end


@implementation AccountInfoTest

#pragma mark Tests

- (void)testAccountInfoSerialization
{
    NSUserDefaults *isolatedDefaults = [[NSUserDefaults alloc] init];

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
    
    //
    // Serialize Array of objects
    //
    NSMutableArray *kServerList = [NSMutableArray arrayWithObjects:detailA, detailB, nil];
    [isolatedDefaults saveAccountList:kServerList];
    
    //
    // Unserialize and test
    //
    NSMutableArray *savedServerList = [isolatedDefaults accountList];
    GHAssertNotNil(savedServerList, @"", nil);
    
    AccountInfo *savedDetailA = [savedServerList objectAtIndex:0];
    GHAssertNotNil(savedDetailA, @"", nil);
    GHAssertNotEqualObjects(detailA, savedDetailA, nil, nil);
    GHAssertTrue([detailA equals:savedDetailA], nil, nil);
    GHAssertTrue([self keyPathValueAreEqualForKeyPath:@"infoDictionary.isMultiTenant" objectA:detailA objectB:savedDetailA], nil, nil);
                 
    AccountInfo *savedDetailB = [savedServerList objectAtIndex:1];
    GHAssertNotNil(savedDetailB, @"", nil);
    GHAssertNotEqualObjects(detailB, savedDetailB, nil, nil);
    GHAssertTrue([detailB equals:savedDetailB], nil, nil);
    
    
    //
    // Change Values and retest
    //
    [savedDetailB setUsername:@"changedUserName"];
    [savedDetailB setPassword:@"changedPassword"];
    
    [isolatedDefaults saveAccountList:savedServerList];
    
    //
    // Unserialize and test again
    //
    savedServerList = [isolatedDefaults accountList];
    GHAssertNotNil(savedServerList, nil, nil);
    
    AccountInfo *savedDetailA2 = [savedServerList objectAtIndex:0];
    GHAssertNotNil(savedDetailA2, @"", nil);
    GHAssertNotEqualObjects(savedDetailA, savedDetailA2, nil, nil);
    GHAssertTrue([savedDetailA equals:savedDetailA2], nil, nil);
    GHAssertTrue([self keyPathValueAreEqualForKeyPath:@"infoDictionary.isMultiTenant" objectA:savedDetailA objectB:savedDetailA2], nil, nil);
    
    AccountInfo *savedDetailB2 = [savedServerList objectAtIndex:1];
    GHAssertNotNil(savedDetailB2, @"", nil);
    GHAssertNotEqualObjects(savedDetailB, savedDetailB2, nil, nil);
    GHAssertTrue([savedDetailB equals:savedDetailB2], nil, nil);

    
    [isolatedDefaults release];
}


#pragma mark -
#pragma mark Utils
- (BOOL)keyPathValueAreEqualForKeyPath:(NSString *)keypath objectA:(NSObject *)a objectB:(NSObject *)b
{
    return [[a valueForKeyPath:keypath] isEqualToString:[b valueForKeyPath:keypath]];
}

@end
