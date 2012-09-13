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
//  NodeLocationHTTPRequest.m
//

#import "NodeLocationHTTPRequest.h"
#import "SBJsonParser.h"
#import "NodeRef.h"

@implementation NodeLocationHTTPRequest

@synthesize siteLocation = _siteLocation;
@synthesize repositoryLocation = _repositoryLocation;

- (void)dealloc
{
    [_siteLocation release];
    [_repositoryLocation release];
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
    
    self.siteLocation = [responseData objectForKey:@"site"];
    self.repositoryLocation = [responseData objectForKey:@"repo"];
    
	[jsonParser release];
	[response release];
}

+ (NodeLocationHTTPRequest *)httpRequestNodeLocation:(NodeRef *)nodeRef withAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:nodeRef forKey:@"NodeRef"];

    NodeLocationHTTPRequest *request = [NodeLocationHTTPRequest requestForServerAPI:kServerAPINodeLocation accountUUID:uuid tenantID:tenantID infoDictionary:infoDictionary];
    return request;
}

@end
