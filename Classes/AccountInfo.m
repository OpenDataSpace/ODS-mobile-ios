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
//  AccountInfo.m
//

#import "AccountInfo.h"

NSString * const kServerAccountId = @"kServerAccountId";
NSString * const kServerVendor = @"kServerVendor";
NSString * const kServerDescription = @"kServerDescription";
NSString * const kServerProtocol = @"kServerProtocol";
NSString * const kServerHostName = @"kServerHostName";
NSString * const kServerPort = @"kServerPort";
NSString * const kServerServiceDocumentRequestPath = @"kServerServiceDocumentRequestPath";
NSString * const kServerUsername = @"kServerUsername";
NSString * const kServerPassword = @"kServerPassword";
NSString * const kServerInformation = @"kServerInformation";
NSString * const kServerMultitenant = @"kServerMultitenant";

@interface AccountInfo ()
+ (NSString *)stringWithUUID;
@end


@implementation AccountInfo
@synthesize uuid;
@synthesize vendor;
@synthesize description;
@synthesize protocol;
@synthesize hostname;
@synthesize port;
@synthesize serviceDocumentRequestPath;
@synthesize username;
@synthesize password;
@synthesize infoDictionary;
@synthesize multitenant;



#pragma mark Object Lifecycle
- (void)dealloc
{
    [uuid release];
    [vendor release];
    [description release];
    [protocol release];
    [hostname release];
    [port release];
    [serviceDocumentRequestPath release];
    [username release];
    [password release];
    [infoDictionary release];
    [multitenant release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark NSCoding
- (id)init 
{
    // TODO static NSString objects
    
    self = [super init];
    if(self) {
        uuid = [[AccountInfo stringWithUUID] retain];
        
        [self setServiceDocumentRequestPath:@"/alfresco/service/cmis"];
        [self setPort:kFDHTTP_DefaultPort];
        [self setProtocol:kFDHTTP_Protocol];
        [self setMultitenant:[NSNumber numberWithBool:NO]];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) 
    {
        uuid = [aDecoder decodeObjectForKey:kServerAccountId];
        if (nil == uuid) {
            // We Should never get here.
            uuid = [AccountInfo stringWithUUID];
        }
        [uuid retain];
        
        vendor = [[aDecoder decodeObjectForKey:kServerVendor] retain];
        description = [[aDecoder decodeObjectForKey:kServerDescription] retain];
        protocol = [[aDecoder decodeObjectForKey:kServerProtocol] retain];
        hostname = [[aDecoder decodeObjectForKey:kServerHostName] retain];
        port = [[aDecoder decodeObjectForKey:kServerPort] retain];
        serviceDocumentRequestPath = [[aDecoder decodeObjectForKey:kServerServiceDocumentRequestPath] retain];
        username = [[aDecoder decodeObjectForKey:kServerUsername] retain];
        password = [[aDecoder decodeObjectForKey:kServerPassword] retain];
        infoDictionary = [[aDecoder decodeObjectForKey:kServerInformation] retain];
        multitenant = [[aDecoder decodeObjectForKey:kServerMultitenant] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:uuid forKey:kServerAccountId];
    [aCoder encodeObject:vendor forKey:kServerVendor];
    [aCoder encodeObject:description forKey:kServerDescription];
    [aCoder encodeObject:protocol forKey:kServerProtocol];
    [aCoder encodeObject:hostname forKey:kServerHostName];
    [aCoder encodeObject:port forKey:kServerPort];
    [aCoder encodeObject:serviceDocumentRequestPath forKey:kServerServiceDocumentRequestPath];
    [aCoder encodeObject:username forKey:kServerUsername];
    [aCoder encodeObject:password forKey:kServerPassword];
    [aCoder encodeObject:infoDictionary forKey:kServerInformation];
    [aCoder encodeObject:multitenant forKey:kServerMultitenant];
}

- (BOOL)isMultitenant
{
    return [multitenant boolValue];
}

#pragma mark -
#pragma mark K-V Compliance

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

#pragma mark - Utils

+ (NSString *)stringWithUUID 
{
    // TODO This method should be moved to some other class.
    
    CFUUIDRef uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString *uuidString = (NSString *)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    
    return [uuidString autorelease];
}


@end
