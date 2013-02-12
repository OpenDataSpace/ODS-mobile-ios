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
//  RepositoryItemParser.m
//

#import "RepositoryItemParser.h"
#import "RepositoryItem.h"
#import "CMISMediaTypes.h"
#import "CMISConstants.h"
#import "CMISUtils.h"

@implementation RepositoryItemParser

- (void)dealloc
{
    [_item release];
    [_parseData release];
    [_currentCMISName release];
    [_elementBeingParsed release];
    [_currentNamespaceURI release];
    [_valueBuffer release];
    [_accountUUID release];
    [_currentAspect release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _item = [[RepositoryItem alloc] init];
		_item.metadata = [NSMutableDictionary dictionary];
        _item.aspects = [NSMutableArray array];
    }
    
    return self;
}

- (id)initWithData:(NSData *)newParseData
{
    self = [self init];
    if (self)
    {
        _parseData = [newParseData retain];
    }
    
    return self;
}

- (RepositoryItem *) parse
{
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:self.parseData] autorelease];
	
	[parser setShouldProcessNamespaces:YES];
	[parser setDelegate:self];
	[parser parse];
    
    return self.item;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                          attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"content"] && [CMISUtils isAtomNamespace:namespaceURI])
    {
		[self.item setContentLocation:[attributeDict objectForKey:@"src"]];
	}
	
	// TODO: check comprehensive list of property element names
	if ([elementName hasPrefix:@"property"] && [CMISUtils isCmisNamespace:namespaceURI])
    {
		self.currentCMISName = [attributeDict objectForKey:kCMISPropertyDefinitionIdPropertyName];
	}
	
	//<ns3:link type="application/atom+xml;type=feed" rel="down" href="http://ibmcmis.dnsdojo.com:8080/p8cmis/resources/TestOS2/ContentFlat/idf_2360E61A-04F9-4DB7-BB87-54446A3F8AF3"/>
	if ([elementName isEqualToString:@"link"] && 
		[(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"down"] &&
		[(NSString *)[attributeDict objectForKey:@"type"] isEqualToString:kAtomFeedMediaType])
	{
		[self.item setIdentLink: [attributeDict objectForKey:@"href"]];
	}
	
	//<link rel="describedby" href="https://dms.xwave.ch:443/alfresco/service/cmis/type/F:st:sites"/>
	if ([elementName isEqualToString:@"link"] && 
		[(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"describedby"])
	{
		[self.item setDescribedByURL:[attributeDict objectForKey:@"href"]];
	}
	
	// <link rel="self" href="https://dms.xwave.ch:443/alfresco/service/cmis/s/workspace:SpacesStore/i/0874d76c-0369-4d99-9c54-72be3d59389c"/>
	if ([elementName isEqualToString:@"link"])
	{
		if ([(NSString *)[attributeDict objectForKey:@"rel"] isEqualToString:@"self"])
        {
			[self.item setSelfURL:[attributeDict objectForKey:@"href"]];
		}
		
        [self.item.linkRelations addObject:attributeDict];
	}
    
	[self setElementBeingParsed:elementName];
    [self setCurrentNamespaceURI:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	// TODO: check comprehensive list of property element names
	if ([elementName hasPrefix:@"property"] && [CMISUtils isCmisNamespace:namespaceURI])
    {
		if ([self.currentCMISName isEqualToString:kCMISLastModifiedPropertyName])
        {
			self.item.lastModifiedBy = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISLastModificationDatePropertyName])
        {
			self.item.lastModifiedDate = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISBaseTypeIdPropertyName])
        {
			self.item.fileType = self.valueBuffer;
		}
		else if ([self.currentCMISName isEqualToString:kCMISObjectIdPropertyName])
        {
			self.item.guid = self.valueBuffer;
		} 
		else if ([self.currentCMISName isEqualToString:kCMISContentStreamLengthPropertyName])
        {
			self.item.contentStreamLengthString = self.valueBuffer;
		}
        else if ([self.currentCMISName isEqualToString:kCMISVersionSeriesIdPropertyName])
        {
			self.item.versionSeriesId = self.valueBuffer;
		}
		
        if (self.currentCMISName)
        {
			NSString *value = self.valueBuffer ? self.valueBuffer : @"";
			NSString *key = self.currentCMISName;
			[self.item.metadata setValue:value forKey:key];
		}
		self.currentCMISName = nil;
		self.valueBuffer = nil;
	}
    else if ([elementName hasPrefix:@"appliedAspects"])
    {
        if ([self.currentAspect length] > 0)
        {
            [self.item.aspects addObject:self.currentAspect];
        }
    }

	self.elementBeingParsed = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if ([self.elementBeingParsed isEqualToString:@"title"] && [CMISUtils isAtomNamespace:self.currentNamespaceURI])
    {
		self.item.title = self.item.title ? [self.item.title stringByAppendingString:string] : string;
	}
    else if ([self.elementBeingParsed isEqualToString:@"canCreateFolder"])
    {
		self.item.canCreateFolder = [string isEqualToString:@"true"];
	}
    else if ([self.elementBeingParsed isEqualToString:@"canCreateDocument"])
    {
		self.item.canCreateDocument = [string isEqualToString:@"true"];
	}
    else if ([self.elementBeingParsed isEqualToString:@"canDeleteObject"])
    {
		self.item.canDeleteObject = [string isEqualToString:@"true"];
    }
    else if ([self.elementBeingParsed isEqualToString:@"canSetContentStream"])
    {
		self.item.canSetContentStream = [string isEqualToString:@"true"];
	}
    else if ([self.elementBeingParsed isEqualToString:@"value"])
    {
		self.valueBuffer = self.valueBuffer ? [self.valueBuffer stringByAppendingString:string] : string;
	}
    else if ([self.elementBeingParsed isEqualToString:@"appliedAspects"])
    {
        if ([string hasPrefix:kCMISAlfrescoAspectNamePrefix])
        {
            self.currentAspect = [string substringFromIndex:kCMISAlfrescoAspectNamePrefix.length];
        }
        else
        {
            self.currentAspect = string;
        }
	}
}

@end
