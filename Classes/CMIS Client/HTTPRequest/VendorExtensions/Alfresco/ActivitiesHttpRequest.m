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
//  ActivitiesHttpRequest.m
//

#import "ActivitiesHttpRequest.h"

@interface ActivitiesHttpRequest () // Private
@property (nonatomic, readwrite, retain) NSArray *activities;
@end

@implementation ActivitiesHttpRequest
@synthesize activities = _activities;

- (void) dealloc 
{
    [_activities release];
    [super dealloc];
}

#pragma mark -
#pragma mark ASIHttpRequestDelegate Methods

- (void)requestFinishedWithSuccessResponse
{
    AlfrescoLogTrace(@"Activities Request Finished: %@", [self responseString]);

    // We need the generated containers to be mutable to be augment with accountUUID and tentantID
    [self setActivities:[self mutableArrayFromJSONResponseWithOptions:NSJSONReadingMutableContainers]];
    
    for (NSMutableDictionary *activityDict in self.activities) 
    {        
        [activityDict setObject:[self accountUUID] forKey:@"accountUUID"];
        if (self.tenantID) 
        {
            [activityDict setObject:[self tenantID] forKey:@"tenantID"];
        }
    }
}

- (void)failWithError:(NSError *)theError
{
    if (theError)
        AlfrescoLogDebug(@"Activities HTTP Request Failure: %@", theError);
    
    [super failWithError:theError];
}

#pragma mark -
#pragma mark Static Class Methods

// Full URL: <protocol>://<hostname>:<port>/alfresco/service/api/activities/feed/user?format=json
// GET /alfresco/service/api/activities/feed/user?format=json
+ (ActivitiesHttpRequest *)httpRequestActivitiesForAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    ActivitiesHttpRequest *request = [ActivitiesHttpRequest requestForServerAPI:kServerAPIActivitiesUserFeed 
                                                                    accountUUID:uuid tenantID:aTenantID];
    [request setRequestMethod:@"GET"];

    return request;
}

@end
