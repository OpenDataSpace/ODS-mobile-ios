//
//  Person.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 27/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "Person.h"

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

@end
