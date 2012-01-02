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
//  NSStringTokenReplacementTests.m
//


#import <GHUnitIOS/GHUnit.h>
#import "NSString+TokenReplacement.h"


@interface NSStringTokenReplacementTests : GHTestCase
@end

@implementation NSStringTokenReplacementTests

- (void)testBasicReplacement
{
    // Basic test to test implementation
    
    //	ServerAPICMISServiceInfo
    NSString *tokenString = @"$protocol://$hostname:$port/$webapp/$service/cmis";
    
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    [tokens setObject:@"http" forKey:@"protocol"];
    [tokens setObject:@"www.example.com" forKey:@"hostname"];
    [tokens setObject:@"8888" forKey:@"port"];
    [tokens setObject:@"alfresco" forKey:@"webapp"];
    [tokens setObject:@"service" forKey:@"service"];
    [tokens setObject:@"glee" forKey:@"username"];
    
    NSString *result = [tokenString stringBySubstitutingTokensInDict:tokens];
    GHAssertEqualStrings(result, @"http://www.example.com:8888/alfresco/service/cmis", nil, nil);

}

@end
