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
//  SearchResultsDownload.m
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
