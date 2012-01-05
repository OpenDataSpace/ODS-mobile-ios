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
//  AccountInfo+Utils.m
//


#import "AccountInfo+Utils.h"

@implementation AccountInfo (Utils)

- (BOOL)keyPathValueAreEqualForKeyPath:(NSString *)keypath objectA:(NSObject *)a objectB:(NSObject *)b
{
    return [[a valueForKeyPath:keypath] isEqualToString:[b valueForKeyPath:keypath]];
}

- (BOOL)equals:(AccountInfo *)other
{  
    // Test using properties
    return ( [self.uuid isEqualToString:other.uuid]
            && [self.vendor isEqualToString:other.vendor]
            && [self.description isEqualToString:other.description]
            && [self.protocol isEqualToString:other.protocol]
            && [self.hostname isEqualToString:other.hostname]
            && [self.port isEqualToString:other.port]
            && [self.serviceDocumentRequestPath isEqualToString:other.serviceDocumentRequestPath]
            && [self.username isEqualToString:other.username]
            && [self.password isEqualToString:other.password]
            
            && [self keyPathValueAreEqualForKeyPath:@"uuid" objectA:self objectB:other]
            && [self keyPathValueAreEqualForKeyPath:@"vendor" objectA:self objectB:other]
            && [self keyPathValueAreEqualForKeyPath:@"description" objectA:self objectB:other]
            && [self keyPathValueAreEqualForKeyPath:@"protocol" objectA:self objectB:other]
            && [self keyPathValueAreEqualForKeyPath:@"hostname" objectA:self objectB:other]
            && [self keyPathValueAreEqualForKeyPath:@"port" objectA:self objectB:other]
            && [self keyPathValueAreEqualForKeyPath:@"serviceDocumentRequestPath" objectA:self objectB:other]
            && [self keyPathValueAreEqualForKeyPath:@"username" objectA:self objectB:other]
            && [self keyPathValueAreEqualForKeyPath:@"password" objectA:self objectB:other] 
            );
}

@end
