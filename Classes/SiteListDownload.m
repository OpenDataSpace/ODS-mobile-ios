//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  SiteListDownload.m
//

#import "SiteListDownload.h"
#import "SBJsonParser.h"
#import "Utility.h"
#import "ServiceInfo.h"
#import "RepositoryItem.h"
#import "ASIHttpRequest+Alfresco.h"
#import "Utility.h"

@implementation SiteListDownload
@synthesize results;

- (void) dealloc {
	[results release];
	[super dealloc];
}

- (SiteListDownload *)initWithDelegate:(id <AsynchronousDownloadDelegate>)del
{
   NSString  *urlString = [[ASIHTTPRequest alfrescoRepositoryBaseServiceUrlString] stringByAppendingString:@"/api/sites?format=json"];
//    NSString  *urlString = [[ASIHTTPRequest alfrescoRepositoryBaseServiceUrlString] stringByAppendingFormat:@"/api/people/%@/sites", [userPrefUsername() stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"Sites\r\nGET:\t%@", urlString);
    
	NSURL *u = [NSURL URLWithString:urlString];
	return (SiteListDownload *) [self initWithURL:u delegate:del];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

	// convert the data to a string
	NSString *str = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
	
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
	
	[super connectionDidFinishLoading:connection];
}

@end
