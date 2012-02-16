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
//  KeychainItemWrapperTest.m
//

#import <GHUnitIOS/GHUnit.h>
#import "KeychainItemWrapper.h"

@interface KeychainItemWrapperTest : GHTestCase 

@end

@implementation KeychainItemWrapperTest

- (void)setUp
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    [wrapper setObject:@"password" forKey:(id)kSecValueData];
    [wrapper release];
}

- (void)testReadPassword
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    GHAssertEqualStrings([wrapper objectForKey:(id)kSecValueData], @"password", @"");
    [wrapper resetKeychainItem];
    [wrapper release];
}

- (void)testUpdatePassword
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    [wrapper setObject:@"anotherPassword" forKey:(id)kSecValueData];
    [wrapper release];
    
    wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    GHAssertEqualStrings([wrapper objectForKey:(id)kSecValueData], @"anotherPassword", @"");
    [wrapper resetKeychainItem];
    [wrapper release];
}

- (void)tearDown
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    [wrapper resetKeychainItem];
    [wrapper release];
}
@end
