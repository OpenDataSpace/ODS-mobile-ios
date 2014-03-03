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
#import "RepositoryItem.h"

@implementation SiteListHTTPRequest
@synthesize results;
@synthesize downloadType;

- (void) dealloc
{
	[results release];
	[super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
    NSArray *jsonArray = [self arrayFromJSONResponse];
    
	// create an array to hold the site objects
    NSMutableArray *sites = [NSMutableArray arrayWithCapacity:[jsonArray count]];

	// create a site object for each JSON entity
	for (NSDictionary *dictionary in jsonArray)
    {
		RepositoryItem *repositoryItem = [RepositoryItem new];
		repositoryItem.title = [dictionary objectForKey:@"title"];
		repositoryItem.node = [dictionary objectForKey:@"node"];
        repositoryItem.guid = [NSString stringWithFormat:@"workspace://SpacesStore/%@", [repositoryItem.node lastPathComponent]];
        
        repositoryItem.metadata = [NSMutableDictionary dictionary];
        [repositoryItem.metadata setObject:[dictionary objectForKey:@"shortName"] forKey:@"shortName"];
        [repositoryItem.metadata setObject:[dictionary objectForKey:@"siteManagers"] forKey:@"siteManagers"];
        [repositoryItem.metadata setObject:[dictionary objectForKey:@"visibility"] forKey:@"visibility"];
		[sites addObject:repositoryItem];
		[repositoryItem release];
	}

	// sort the sites by title
	//[sites sortUsingSelector:@selector(compareTitles:)];
	
	self.results = sites;
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
