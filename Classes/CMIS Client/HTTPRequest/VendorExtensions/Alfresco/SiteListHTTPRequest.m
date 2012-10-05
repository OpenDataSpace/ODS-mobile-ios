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
//  SiteListDownload.m
//

#import "SiteListHTTPRequest.h"
#import "SBJsonParser.h"
#import "RepositoryItem.h"
#import "ASIHttpRequest+Alfresco.h"

@implementation SiteListHTTPRequest
@synthesize results;
@synthesize downloadType;

- (void) dealloc {
	[results release];
	[super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{

	// convert the data to a string
	NSString *str = [[NSString alloc] initWithData:[self responseData] encoding:NSASCIIStringEncoding];
#if MOBILE_DEBUG
    NSLog(@"Sites: %@", str);
#endif
	
	// create a JSON parser
	SBJsonParser *jsonParser = [SBJsonParser new];  
	
	// parse the returned string
	NSArray *a = [jsonParser objectWithString:str];  

	// create an array to hold the site objects
	NSMutableArray *sites = [[NSMutableArray alloc] initWithCapacity:[a count]];

	// create a site object for each JSON entity
	for (NSDictionary *d in a) {
		RepositoryItem *s = [[RepositoryItem alloc] init];
		s.title = [d objectForKey:@"title"];
		s.node = [d objectForKey:@"node"];
        [s setGuid:[NSString stringWithFormat:@"workspace://SpacesStore/%@", [[s node] lastPathComponent]]];
        
        s.metadata = [NSMutableDictionary dictionary];
        [s.metadata setObject:[d objectForKey:@"shortName"] forKey:@"shortName"];
        [s.metadata setObject:[d objectForKey:@"siteManagers"] forKey:@"siteManagers"];
        [s.metadata setObject:[d objectForKey:@"visibility"] forKey:@"visibility"];
		[sites addObject:s];
		[s release];
	}

	// sort the sites by title
	[sites sortUsingSelector:@selector(compareTitles:)];
	
	self.results = sites;

	// clean up; release objects to free memory
	[sites release];
	[jsonParser release];
	[str release];
}

+ (SiteListHTTPRequest *)siteRequestForAllSitesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    SiteListHTTPRequest *request = [SiteListHTTPRequest requestForServerAPI:kServerAPISiteCollection accountUUID:uuid tenantID:tenantID];
    [request setDownloadType:SiteListDownloadTypeAllSites];
    return request;
}

+ (SiteListHTTPRequest *)siteRequestForMySitesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{    
    SiteListHTTPRequest *request = [SiteListHTTPRequest requestForServerAPI:kServerAPIPersonsSiteCollection accountUUID:uuid tenantID:tenantID];
    [request setDownloadType:SiteListDownloadTypeAllSites];
    return request;
}

@end
