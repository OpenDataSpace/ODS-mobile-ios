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
// AvatarHTTPRequest 
//

#import "AvatarHTTPRequest.h"


@implementation AvatarHTTPRequest

#pragma mark Request creation

+ (AvatarHTTPRequest *)httpRequestAvatarForUserName:(NSString *)userName accountUUID:(NSString *)uuid tenantID:(NSString *)tenantId
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:userName forKey:@"USERNAME"];
    AvatarHTTPRequest *request = [AvatarHTTPRequest requestForServerAPI:kServerAPIPersonAvatar accountUUID:uuid tenantID:tenantId infoDictionary:infoDictionary];
    [request setRequestMethod:@"GET"];
    return request;
}

#pragma mark Request callbacks

- (void)failWithError:(NSError *)theError
{
    if (theError)
    {
        NSLog(@"Error while retrieving avatar (url = '%@'): %@", self.url.absoluteString, theError.localizedDescription);
    }

    [super failWithError:theError];
}

@end
