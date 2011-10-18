//
//  SiteListDownload.m
//  Alfresco
//
//  Created by Michael Muller on 10/21/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
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
