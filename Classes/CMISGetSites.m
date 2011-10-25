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
//  CMISGetSites.m
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
