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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  RepositoryItemParser.m
//

#import "RepositoryItemParser.h"
#import "RepositoryItem.h"
#import "ServiceInfo.h"
#import "CMISMediaTypes.h"

@implementation RepositoryItemParser
@synthesize parseData;
@synthesize currentCMISName;
@synthesize elementBeingParsed;
@synthesize currentNamespaceURI;
@synthesize valueBuffer;
@synthesize accountUUID;

- (void)dealloc {
    [parseData release];
    [item release];
    [valueBuffer release];
    [currentCMISName release];
    [accountUUID release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        item = [[RepositoryItem alloc] init];
        NSMutableDictionary *md = [[NSMutableDictionary alloc] init];
		item.metadata = md;
		[md release];
    }
    
    return self;
}

- (id)initWithData:(NSData *)newParseData {
    self = [self init];
    if(self) {
        self.parseData = newParseData;
    }
    
    return self;
}

- (RepositoryItem *) parse {
    NSXMLParser *parser = [NSXMLParser alloc];
    parser = [[parser initWithData:parseData] autorelease];
	
	[parser setShouldProcessNamespaces:YES];
	[parser setDelegate:self];
	[parser parse];
    
    return item;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
	ServiceInfo *serviceInfo = [ServiceInfo sharedInstanceForAccountUUID:self.accountUUID];
	
	if ([elementName isEqualToString:@"content"] && [serviceInfo isAtomNamespace:namespaceURI]) {
		[item setContentLocation: [attributeDict objectForKey:@"src"]];
	}
	
	// TODO: check comprehensive list of property element names
	if ([elementName hasPrefix:@"property"] && [serviceInfo isCmisNamespace:namespaceURI]) {
		self.currentCMISName = [attributeDict objectForKey:[serviceInfo cmisPropertyIdAttribute]];
	}
	
	//<ns3:link type="application/atom+xml;type=feed" rel="down" href="http://ibmcmis.dnsdojo.com:8080/p8cmis/resources/TestOS2/ContentFlat/idf_2360E61A-04F9-4DB7-BB87-54446A3F8AF3"/>
	if ([elementName isEqualToString:@"link"] && 
		[(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"down"] &&
		[(NSString *)[attributeDict objectForKey:@"type"] isEqualToString:kAtomFeedMediaType])
	{
		[item setIdentLink: [attributeDict objectForKey:@"href"]];
	}
	
	//<link rel="describedby" href="https://dms.xwave.ch:443/alfresco/service/cmis/type/F:st:sites"/>
	if ([elementName isEqualToString:@"link"] && 
		[(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"describedby"])
	{
		[item setDescribedByURL:[attributeDict objectForKey:@"href"]];
	}
	
	// <link rel="self" href="https://dms.xwave.ch:443/alfresco/service/cmis/s/workspace:SpacesStore/i/0874d76c-0369-4d99-9c54-72be3d59389c"/>
	if ([elementName isEqualToString:@"link"])
	{
		if ([(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"self"]) {
			[item setSelfURL:[attributeDict objectForKey:@"href"]];
		}
		
        [[item linkRelations] addObject:attributeDict];
	}
    
	self.elementBeingParsed = elementName;
    [self setCurrentNamespaceURI:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
	ServiceInfo *serviceInfo = [ServiceInfo sharedInstanceForAccountUUID:accountUUID];
	
	// TODO: check comprehensive list of property element names
	if ([elementName hasPrefix:@"property"] && [serviceInfo isCmisNamespace:namespaceURI]) {
		if ([self.currentCMISName isEqualToString:[serviceInfo lastModifiedByPropertyName]]) {
			item.lastModifiedBy = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:[serviceInfo lastModificationDatePropertyName]]) {
			item.lastModifiedDate = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:[serviceInfo baseTypeIdPropertyName]]) {
			item.fileType = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:[serviceInfo objectIdPropertyName]]) {
			item.guid = self.valueBuffer;
		} 
		else if ([self.currentCMISName isEqualToString:[serviceInfo contentStreamLengthPropertyName]]) {
			item.contentStreamLengthString = self.valueBuffer;
		}
        else if ([self.currentCMISName isEqualToString:[serviceInfo versionSeriesIdPropertyName]]) {
			item.versionSeriesId = self.valueBuffer;
		}
		if (self.currentCMISName) {
			NSString *value = self.valueBuffer ? self.valueBuffer : @"";
			NSString *key = self.currentCMISName;
			[item.metadata setValue:value forKey:key];
		}
		self.currentCMISName = nil;
		self.valueBuffer = nil;
	}
	self.elementBeingParsed = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    ServiceInfo *serviceInfo = [ServiceInfo sharedInstanceForAccountUUID:accountUUID];
    
    if ([self.elementBeingParsed isEqualToString:@"title"] && [serviceInfo isAtomNamespace:self.currentNamespaceURI]) {
		item.title = item.title ? [item.title stringByAppendingString:string] : string;
	} else if ([self.elementBeingParsed isEqualToString:@"canCreateFolder"]) {
		item.canCreateFolder = [string isEqualToString:@"true"];
	} else if ([self.elementBeingParsed isEqualToString:@"canCreateDocument"]) {
		item.canCreateDocument = [string isEqualToString:@"true"];
	} else if ([self.elementBeingParsed isEqualToString:@"value"]) {
		self.valueBuffer = self.valueBuffer ? [self.valueBuffer stringByAppendingString:string] : string;
	}
}

@end
