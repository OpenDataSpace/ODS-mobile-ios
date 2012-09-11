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
//  Person.m
//

#import "Person.h"

NSString * const kPersonCodingKeyUserName = @"personUserName";
NSString * const kPersonCodingKeyFirstName = @"personFirstName";
NSString * const kPersonCodingKeyLastName = @"personLastName";
NSString * const kPersonCodingKeyAvatar = @"personAvatar";
NSString * const kPersonCodingKeyEmail = @"personEmail";

@implementation Person

@synthesize userName = _userName;
@synthesize firstName = _firstName;
@synthesize lastName = _lastName;
@synthesize avatar = _avatar;
@synthesize email = _email;

- (void)dealloc
{
    [_userName release];
    [_firstName release];
    [_lastName release];
    [_avatar release];
    [_email release];
    [super dealloc];
}

- (Person *)initWithJsonDictionary:(NSDictionary *)json
{
    self = [super init];
    
    if(self)
    {
        [self setUserName:[json valueForKey:@"userName"]];
        [self setFirstName:[json valueForKey:@"firstName"]];
        [self setLastName:[json valueForKey:@"lastName"]];
        [self setAvatar:[json valueForKey:@"avatar"]];
        [self setEmail:[json valueForKey:@"email"]];
    }
    
    return self;
}

#pragma mark NSCoding protocol implementation

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _userName = [[decoder decodeObjectForKey:kPersonCodingKeyUserName] retain];
        _firstName = [[decoder decodeObjectForKey:kPersonCodingKeyFirstName] retain];
        _lastName = [[decoder decodeObjectForKey:kPersonCodingKeyLastName] retain];
        _avatar = [[decoder decodeObjectForKey:kPersonCodingKeyAvatar] retain];
        _email = [[decoder decodeObjectForKey:kPersonCodingKeyEmail] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.userName forKey:kPersonCodingKeyUserName];
    [coder encodeObject:self.firstName forKey:kPersonCodingKeyFirstName];
    [coder encodeObject:self.lastName forKey:kPersonCodingKeyLastName];
    [coder encodeObject:self.avatar forKey:kPersonCodingKeyAvatar];
    [coder encodeObject:self.email forKey:kPersonCodingKeyEmail];
}

@end
