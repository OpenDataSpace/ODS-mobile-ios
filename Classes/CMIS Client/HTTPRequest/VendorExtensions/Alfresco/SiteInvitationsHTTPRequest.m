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
//  SiteInvitationsHTTPRequest.m
//

#import "SiteInvitationsHTTPRequest.h"
#import "SBJsonParser.h"

@implementation SiteInvitationsHTTPRequest
@synthesize invitations = _invitations;

- (void)dealloc
{
	[_invitations release];
	[super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
	// convert the data to a string
	NSString *response = [[NSString alloc] initWithData:[self responseData] encoding:NSASCIIStringEncoding];
	
	// create a JSON parser
	SBJsonParser *jsonParser = [SBJsonParser new];
	
	// parse the returned string
    NSDictionary *responseData = [jsonParser objectWithString:response];
	NSArray *invitesArray = [responseData objectForKey:@"data"];
    
	// create an array to hold the pending invite objects
	NSMutableDictionary *pendingInvites = [NSMutableDictionary dictionaryWithCapacity:[invitesArray count]];
    
	// create a site object for each JSON entity
	for (NSDictionary *inviteObj in invitesArray)
    {
        [pendingInvites setObject:[inviteObj objectForKey:@"inviteId"] forKey:[inviteObj objectForKey:@"resourceName"]];
	}
    
	self.invitations = [NSDictionary dictionaryWithDictionary:pendingInvites];
    
	[jsonParser release];
	[response release];
}

+ (SiteInvitationsHTTPRequest *)httpRequestSiteInvitationsWithAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    SiteInvitationsHTTPRequest *request = [SiteInvitationsHTTPRequest requestForServerAPI:kServerAPISiteInvitations accountUUID:uuid tenantID:tenantID];
    return request;
}

@end
