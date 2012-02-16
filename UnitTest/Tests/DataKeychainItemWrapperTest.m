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
#import "DataKeychainItemWrapper.h"

@interface DataKeychainItemWrapperTest : GHTestCase 

@end

@implementation DataKeychainItemWrapperTest

static NSData *passwordData;
static NSData *anotherPasswordData;

- (void)setUp
{
    passwordData = [[@"password" dataUsingEncoding:NSUTF8StringEncoding] retain];
    anotherPasswordData = [[@"anotherPassword" dataUsingEncoding:NSUTF8StringEncoding] retain];
    DataKeychainItemWrapper *wrapper = [[DataKeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    [wrapper setObject:passwordData forKey:(id)kSecValueData];
    [wrapper release];
}

- (void)testReadPassword
{
    DataKeychainItemWrapper *wrapper = [[DataKeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    NSData *dataInKeychain = [wrapper objectForKey:(id)kSecValueData];
    NSString *password = [[[NSString alloc] initWithBytes:[dataInKeychain bytes] length:[dataInKeychain length] 
                                                 encoding:NSUTF8StringEncoding] autorelease];
    GHTestLog(@"Data in keychain: %@", password);
    GHAssertEqualObjects([wrapper objectForKey:(id)kSecValueData], passwordData, @"");
    [wrapper resetKeychainItem];
    [wrapper release];
}

- (void)testUpdatePassword
{
    DataKeychainItemWrapper *wrapper = [[DataKeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    [wrapper setObject:anotherPasswordData forKey:(id)kSecValueData];
    [wrapper release];
    
    wrapper = [[DataKeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    GHAssertEqualObjects([wrapper objectForKey:(id)kSecValueData], anotherPasswordData, @"");
    [wrapper resetKeychainItem];
    [wrapper release];
}

- (void)tearDown
{
    DataKeychainItemWrapper *wrapper = [[DataKeychainItemWrapper alloc] initWithIdentifier:@"KeyChainWrapperTest" accessGroup:nil];
    [wrapper resetKeychainItem];
    [wrapper release];
    
    [passwordData release];
    [anotherPasswordData release];
}
@end
