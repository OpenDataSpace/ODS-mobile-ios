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
//  ActivitiesHttpRequest.m
//

#import "ActivitiesHttpRequest.h"
#import "JSON.h"
#import "SBJSON.h"
#import "Utility.h"
#import "NodeRef.h"

@implementation ActivitiesHttpRequest
@synthesize activities;

- (void) dealloc {
    [activities release];
    [super dealloc];
}

#pragma mark -
#pragma mark ASIHttpRequestDelegate Methods

- (void)requestFinished
{
    NSLog(@"Activities Request Finished: %@", [self responseString]);
    //	Check that we are valid
	if (![self responseSuccessful]) {
		// FIXME: Recode domain, code and userInfo.  Use ASI as an example but do for CMIS errors
		// !!!: Make sure to cleanup because we are in an error
		
		[self failWithError:[NSError errorWithDomain:CMISNetworkRequestErrorDomain 
												code:ASIUnhandledExceptionError userInfo:nil]];
        return;
	}
    
    NSLog(@"Comments Response String: %@", self.responseString);
    SBJSON *jsonObj = [SBJSON new];
    id result = [jsonObj objectWithString:[self responseString]];
    [activities release];
    activities = [result retain];
    [jsonObj release];
    
    [super requestFinished];
}

- (void)failWithError:(NSError *)theError
{
    if (theError)
        NSLog(@"Tagging HTTP Request Failure: %@", theError);
    
    [super failWithError:theError];
}

#pragma mark -
#pragma mark Static Class Methods

// Full URL: <protocol>://<hostname>:<port>/alfresco/service/api/activities/feed/user?format=json
// GET /alfresco/service/api/activities/feed/user?format=json
+ (ActivitiesHttpRequest *)httpRequestActivities {
    NSString  *urlString = [[self alfrescoRepositoryBaseServiceUrlString] stringByAppendingString:@"/api/activities/feed/user?format=json"];
    NSLog(@"Request Activities\r\nGET:\t%@", urlString);
    ActivitiesHttpRequest *request = [ActivitiesHttpRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setRequestMethod:@"GET"];
    [request addBasicAuthHeader];
    return request;
}

@end
