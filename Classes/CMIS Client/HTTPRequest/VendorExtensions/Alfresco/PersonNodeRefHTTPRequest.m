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
//  PersonNodeRefHTTPRequest.m
//

#import "PersonNodeRefHTTPRequest.h"

@implementation PersonNodeRefHTTPRequest

@synthesize nodeRef = _nodeRef;

- (void)dealloc
{
    [_nodeRef release];
    [super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
    // parse the returned json
    NSDictionary *jsonObject = [self dictionaryFromJSONResponse];
    NSArray *personJSONArray = [jsonObject valueForKeyPath:@"data.items"];
    
    AlfrescoLogTrace(@"Persons: %@", personJSONArray);
    
    if (personJSONArray.count > 0)
    {
        NSDictionary *personDict = [personJSONArray objectAtIndex:0];
        [self setNodeRef:[personDict valueForKey:@"nodeRef"]];
    }
}

+ (PersonNodeRefHTTPRequest *)personRequestWithUsername:(NSString *)username accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:username forKey:@"PERSON"];
    PersonNodeRefHTTPRequest *request = [PersonNodeRefHTTPRequest requestForServerAPI:kServerAPIPersonNodeRef 
                                                                          accountUUID:uuid tenantID:tenantID infoDictionary:infoDictionary];
    [request setRequestMethod:@"GET"];
    
    return request;
}

@end
