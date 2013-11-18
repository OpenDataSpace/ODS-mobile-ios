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
//  FolderDescendantsRequest.m
//

#import "FolderDescendantsRequest.h"
#import "RepositoryItem.h"
#import "LinkRelationService.h"
#import "CMISMediaTypes.h"
#import "Utility.h"
#import "CMISConstants.h"
#import "CMISUtils.h"

@implementation FolderDescendantsRequest
@synthesize folderDescendants;
@synthesize currentItem;
@synthesize currentCMISName;
@synthesize currentNamespaceURI;
@synthesize elementBeingParsed;
@synthesize valueBuffer;

- (void)dealloc
{
    [folderDescendants release];
    [currentItem release];
    [currentCMISName release];
    [currentNamespaceURI release];
    [elementBeingParsed release];
    [valueBuffer release];
    [super dealloc];
}
#pragma mark -
#pragma mark ASIHttpRequestDelegate Methods

- (void)requestFinishedWithSuccessResponse
{
    AlfrescoLogDebug(@"Folder Descendants Request Finished: %@", [self responseString]);
	self.folderDescendants = [NSMutableArray array];
	
	// create a parser and parse the xml
	NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:[self responseData]] autorelease];
	[parser setShouldProcessNamespaces:YES];
	[parser setDelegate:self];
	[parser parse];
	
	// sort the docs & folders by title
    // No need to sort for downloading descendants but implement this in the case this class is used to replace
    // FolderItemsDownload
	//[self.folderDescendants sortUsingSelector:@selector(compareTitles:)];
	
	// if the user has selected the preference to hide "dot" files, then filter those from the list
	if (!userPrefShowHiddenFiles()) {
		for (int i = [self.folderDescendants count] - 1; i >= 0; i--) {
			RepositoryItem *ritem = [self.folderDescendants objectAtIndex:i];
			if ([ritem.title hasPrefix:@"."]) {
				[self.folderDescendants removeObjectAtIndex:i];
			}
		}
	}
}

- (void)failWithError:(NSError *)theError
{
    if (theError)
        AlfrescoLogDebug(@"Folder Descendants HTTP Request Failure: %@", theError);
    
    [super failWithError:theError];
}

#pragma mark -
#pragma mark NSXMLParserDelegate Methods
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict 
{
	// if this is a new entry, create a repository item and add it to the list
	if ([elementName isEqualToString:@"entry"] &&  [CMISUtils isAtomNamespace:namespaceURI]) {
		RepositoryItem *ritem = [[RepositoryItem alloc] init];
		
		NSMutableDictionary *md = [[NSMutableDictionary alloc] init];
		ritem.metadata = md;
		[md release];
		
		[self.folderDescendants addObject:ritem];
        [self setCurrentItem:ritem];
		[ritem release];
	}
	
	if ([elementName isEqualToString:@"content"] && [CMISUtils isAtomNamespace:namespaceURI]) {
		[currentItem setContentLocation: [attributeDict objectForKey:@"src"]];
	}
	
	// TODO: check comprehensive list of property element names
	if ([elementName hasPrefix:@"property"] && [CMISUtils isCmisNamespace:namespaceURI]) {
		self.currentCMISName = [attributeDict objectForKey:kCMISPropertyDefinitionIdPropertyName];
	}
	
	//<ns3:link type="application/atom+xml;type=feed" rel="down" href="http://ibmcmis.dnsdojo.com:8080/p8cmis/resources/TestOS2/ContentFlat/idf_2360E61A-04F9-4DB7-BB87-54446A3F8AF3"/>
	if ([elementName isEqualToString:@"link"] && 
		[(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"down"] &&
		[(NSString *)[attributeDict objectForKey:@"type"] isEqualToString:kAtomFeedMediaType])
	{
		[currentItem setIdentLink: [attributeDict objectForKey:@"href"]];
	}
	
	//<link rel="describedby" href="https://dms.xwave.ch:443/alfresco/service/cmis/type/F:st:sites"/>
	if ([elementName isEqualToString:@"link"] && 
		[(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"describedby"])
	{
		[currentItem setDescribedByURL:[attributeDict objectForKey:@"href"]];
	}
	
	// <link rel="self" href="https://dms.xwave.ch:443/alfresco/service/cmis/s/workspace:SpacesStore/i/0874d76c-0369-4d99-9c54-72be3d59389c"/>
	if ([elementName isEqualToString:@"link"])
	{
		if ([(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"self"]) {
			[currentItem setSelfURL:[attributeDict objectForKey:@"href"]];
		}
		
		if (currentItem) {
			[[currentItem linkRelations] addObject:attributeDict];
		}
	}
    
	self.elementBeingParsed = elementName;
    [self setCurrentNamespaceURI:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	// TODO: check comprehensive list of property element names
	if ([elementName hasPrefix:@"property"] && [CMISUtils isCmisNamespace:namespaceURI]) {
		if ([self.currentCMISName isEqualToString:kCMISLastModifiedPropertyName]) {
			currentItem.lastModifiedBy = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISLastModificationDatePropertyName]) {
			currentItem.lastModifiedDate = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISBaseTypeIdPropertyName]) {
			currentItem.fileType = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISObjectIdPropertyName]) {
			currentItem.guid = self.valueBuffer;
		} 
		else if ([self.currentCMISName isEqualToString:kCMISContentStreamLengthPropertyName]) {
			currentItem.contentStreamLengthString = self.valueBuffer;
		}
        else if ([self.currentCMISName isEqualToString:kCMISVersionSeriesIdPropertyName]) {
			currentItem.versionSeriesId = self.valueBuffer;
		}
		if (self.currentCMISName) {
			NSString *value = self.valueBuffer ? self.valueBuffer : @"";
			NSString *key = self.currentCMISName;
			[currentItem.metadata setValue:value forKey:key];
		}
		self.currentCMISName = nil;
		self.valueBuffer = nil;
	}
	self.elementBeingParsed = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
    if ([self.elementBeingParsed isEqualToString:@"title"] && [CMISUtils isAtomNamespace:self.currentNamespaceURI]) {
		currentItem.title = currentItem.title ? [currentItem.title stringByAppendingString:string] : string;
	} else if ([self.elementBeingParsed isEqualToString:@"canCreateFolder"]) {
		currentItem.canCreateFolder = [string isEqualToString:@"true"];
	} else if ([self.elementBeingParsed isEqualToString:@"canMoveObject"]) {
		currentItem.canMoveObject = [string isEqualToString:@"true"];
	} else if ([self.elementBeingParsed isEqualToString:@"canCreateDocument"]) {
		currentItem.canCreateDocument = [string isEqualToString:@"true"];
	} else if ([self.elementBeingParsed isEqualToString:@"canDeleteObject"]) {
		currentItem.canDeleteObject = [string isEqualToString:@"true"];
    } else if ([self.elementBeingParsed isEqualToString:@"canSetContentStream"]) {
		currentItem.canSetContentStream = [string isEqualToString:@"true"];
	} else if ([self.elementBeingParsed isEqualToString:@"value"]) {
		self.valueBuffer = self.valueBuffer ? [self.valueBuffer stringByAppendingString:string] : string;
	}
}

+ (FolderDescendantsRequest *)folderDescendantsRequestWithItem:(RepositoryItem *)item accountUUID:(NSString *)uuid
{
    NSString *folderDescendantsUrl = [[LinkRelationService shared] hrefForLinkRelationString:@"down" cmisMediaType:@"application/cmistree+xml" onCMISObject:item];

    if ([folderDescendantsUrl hasSuffix:@"descendants"]) {
        //
        // Assume that Alfresco has getDescendants URL ending with 'descendants', the default depth for the getDescendants CMIS Call is equal to 1.  
        // We override this by providing a -1 which will return all documents at all depths starting from the current folder.
        // This value is probably best if added to the configurations but for now we leave in as a hard-coded valueß
        //
        folderDescendantsUrl = [folderDescendantsUrl stringByAppendingString:@"?depth=-1"];
    }
    AlfrescoLogDebug(@"Folder Descendants\r\nGET:\t%@", folderDescendantsUrl);
    
    FolderDescendantsRequest *request = [FolderDescendantsRequest requestWithURL:[NSURL URLWithString:folderDescendantsUrl] accountUUID:uuid];
    [request setRequestMethod:@"GET"];
    [request setShouldContinueWhenAppEntersBackground:YES];
    return request;
}

@end
