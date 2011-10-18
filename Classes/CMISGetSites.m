//
//  CMISGetSites.m
//  Alfresco
//
//  Created by Michael Muller on 10/29/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import "CMISGetSites.h"
#import "RepositoryServices.h"
#import "RepositoryItem.h"

@implementation CMISGetSites

- (CMISGetSites *)initWithDelegate:(id <AsynchronousDownloadDelegate>)del
{
	NSString *cql;
	if ([[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis]) {
		cql = @"select * from folder as f where f.ObjectTypeId = 'F/st_site'";
	} else {
		cql = @"SELECT * FROM st:site";
	}
	 
	return (CMISGetSites *) [self initWithQuery:cql delegate:del];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
	// if this is a new entry, create a repository item and add it to the list
	if ([elementName isEqualToString:@"entry"]) {
		RepositoryItem *cmisAtomEntry = [[RepositoryItem alloc] init];
		[self.results addObject:cmisAtomEntry];
		[cmisAtomEntry release];
	}
	else if ([elementName isEqualToString:@"link"])
	{		
		if ([self.results lastObject]) {
			[[[self.results lastObject] linkRelations] addObject:attributeDict];
		}
	}
	
	self.elementBeingParsed = elementName;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	RepositoryItem *currentItem = [self.results lastObject];
	
	if ([self.elementBeingParsed isEqualToString:@"title"]) {
		currentItem.title = currentItem.title ? [currentItem.title stringByAppendingString:string] : string;
	}
	else if ([self.elementBeingParsed isEqualToString:@"content"]) {
		currentItem.node = currentItem.node ? [currentItem.node stringByAppendingString:string] : string;
	}
	else if ([self.elementBeingParsed isEqualToString:@"id"]) {
		currentItem.guid = [string stringByReplacingOccurrencesOfString:@"urn:uuid:" withString:@""];
	} 
    else if ([self.elementBeingParsed isEqualToString:@"canCreateFolder"]) {
		currentItem.canCreateFolder = [string isEqualToString:@"true"];
	} 
    else if ([self.elementBeingParsed isEqualToString:@"canCreateDocument"]) {
		currentItem.canCreateDocument = [string isEqualToString:@"true"];
	} 
}

@end
