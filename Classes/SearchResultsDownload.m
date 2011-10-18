//
//  SearchResultsDownload.m
//  Alfresco
//
//  Created by Michael Muller on 10/23/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import "SearchResultsDownload.h"
#import "SearchResult.h"
#import "Utility.h"
#import "ServiceInfo.h"
#import "RepositoryInfo.h"
#import "RepositoryServices.h"

#define kMaxSearchResults 30

@implementation SearchResultsDownload

@synthesize results;
@synthesize elementBeingParsed;
@synthesize currentNamespaceURI;

- (void) dealloc {
	[results release];
	[elementBeingParsed release];
    [currentNamespaceURI release];
	[super dealloc];
}

- (SearchResultsDownload *) initWithSearchPattern:(NSString *)pattern delegate: (id <AsynchronousDownloadDelegate>) del {
	NSString *webappUrlString = [[ServiceInfo sharedInstance] hostURL];
	NSString *patternEncoded = [pattern stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	NSString *urlStr = [[NSString alloc] initWithFormat:@"%@/alfresco/service/search/keyword.atom?q=%@&p=1&c=%d", webappUrlString, patternEncoded, kMaxSearchResults];
	NSURL *u = [NSURL URLWithString:urlStr];
	[urlStr release];
	return (SearchResultsDownload *) [self initWithURL:u delegate:del];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	// create an array to hold the folder items
	NSMutableArray *r = [[NSMutableArray alloc] init];
	self.results = r;
	[r release];
	
	// create a parser and parse the xml
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.data];
	[parser setDelegate:self];
	[parser parse];
	[parser release];

	// if the user has selected the preference to hide "dot" files, then filter those from the list
	if (!userPrefShowHiddenFiles()) {
		// FIXME: use optimized loop here
		for (int i = [self.results count] - 1; i >= 0; i--) {
			SearchResult *item = [self.results objectAtIndex:i];
			if ([item.title hasPrefix:@"."]) {
				[self.results removeObjectAtIndex:i];
			}
		}
	}
	
	[super connectionDidFinishLoading:connection];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
	// if this is a new entry, create a repository item and add it to the list
	if ([elementName isEqualToString:@"entry"]) {
		SearchResult *r = [[SearchResult alloc] init];
		[self.results addObject:r];
		[r release];
	}
	else if ([elementName isEqualToString:@"link"]) {
		[[self.results lastObject] setContentLocation: [attributeDict objectForKey:@"href"]];
	}
    
    [self setElementBeingParsed:elementName];
    [self setCurrentNamespaceURI:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    [self setElementBeingParsed:nil];
    [self setCurrentNamespaceURI:nil];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	SearchResult *currentItem = [self.results lastObject];
    ServiceInfo *serviceInfo = [ServiceInfo sharedInstance];
	RepositoryInfo *repositoryInfo = [[RepositoryServices shared] currentRepositoryInfo];

    if ([self.elementBeingParsed isEqualToString:@"title"] && ([serviceInfo isAtomNamespace:self.currentNamespaceURI] || [repositoryInfo isPreReleaseCmis])) {
		currentItem.title = currentItem.title ? [currentItem.title stringByAppendingString:string] : string;
	}
	else if ([self.elementBeingParsed isEqualToString:@"relevance:score"]) {
		currentItem.relevance = currentItem.relevance ? [currentItem.relevance stringByAppendingString:string] : string;
	}
    else if ([self.elementBeingParsed isEqualToString:@"name"]) {
        [currentItem setContentAuthor:string];
    }
    else if ([self.elementBeingParsed isEqualToString:@"updated"]) {
        [currentItem setUpdated:string];
    }
    else if ([self.elementBeingParsed isEqualToString:@"alf:noderef"]) {
        [currentItem setCmisObjectId:string];
    }
}

@end
