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
//  CMISTypeDefinitionHTTPRequest.m
//

#import "CMISTypeDefinitionHTTPRequest.h"
#import "DownloadMetadata.h"
#import "CMISUtils.h"

@implementation CMISTypeDefinitionHTTPRequest

@synthesize elementBeingParsed;
@synthesize propertyBeingParsed;
@synthesize properties;
@synthesize repositoryItem;
@synthesize downloadMetadata;

- (void) dealloc 
{
	[elementBeingParsed release];
	[propertyBeingParsed release];
	[properties release];
	[repositoryItem release];
    [downloadMetadata release];
	[super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
	
	// log the response
	AlfrescoLogTrace(@"**** async result: %@", self.responseString);
	
	// create a hash to hold the properties, indexed by id
	NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
	self.properties = p;
	[p release];
	
	// create a parser and parse the xml
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[self responseData]];
	[parser setShouldProcessNamespaces:YES];
	[parser setDelegate:self];
	[parser parse];
	[parser release];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict 
{
	// if this is a new property, create a property info obj
	if ([elementName hasPrefix:@"property"] && [elementName hasSuffix:@"Definition"] && [CMISUtils isCmisNamespace:namespaceURI]) {
		PropertyInfo *pinfo = [[PropertyInfo alloc] init];
		self.propertyBeingParsed = pinfo;
		[pinfo release];
	}
	
	self.elementBeingParsed = elementName;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	// if we're done parsing a property, add it to the hash
	if ([elementName hasPrefix:@"property"] && [elementName hasSuffix:@"Definition"] && [CMISUtils isCmisNamespace:namespaceURI]) {
		[self.properties setObject:self.propertyBeingParsed forKey:self.propertyBeingParsed.propertyId];
		self.propertyBeingParsed = nil;
	}
	
	self.elementBeingParsed = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	if (self.propertyBeingParsed) {
		if ([self.elementBeingParsed isEqualToString:@"id"]) {
			self.propertyBeingParsed.propertyId = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.propertyId];
		} else if ([self.elementBeingParsed isEqualToString:@"localName"]) {
			self.propertyBeingParsed.localName = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.localName];
		} else if ([self.elementBeingParsed isEqualToString:@"localNamespace"]) {
			self.propertyBeingParsed.localNamespace = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.localNamespace];
		} else if ([self.elementBeingParsed isEqualToString:@"displayName"]) {
			self.propertyBeingParsed.displayName = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.displayName];
		} else if ([self.elementBeingParsed isEqualToString:@"queryName"]) {
			self.propertyBeingParsed.queryName = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.queryName];
		} else if ([self.elementBeingParsed isEqualToString:@"description"]) {
			self.propertyBeingParsed.description = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.description];
		} else if ([self.elementBeingParsed isEqualToString:@"propertyType"]) {
			self.propertyBeingParsed.propertyType = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.propertyType];
		} else if ([self.elementBeingParsed isEqualToString:@"cardinality"]) {
			self.propertyBeingParsed.cardinality = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.cardinality];
		} else if ([self.elementBeingParsed isEqualToString:@"updatability"]) {
			self.propertyBeingParsed.updatability = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.updatability];
		} else if ([self.elementBeingParsed isEqualToString:@"inherited"]) {
			self.propertyBeingParsed.inherited = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.inherited];
		} else if ([self.elementBeingParsed isEqualToString:@"required"]) {
			self.propertyBeingParsed.required = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.required];
		} else if ([self.elementBeingParsed isEqualToString:@"queryable"]) {
			self.propertyBeingParsed.queryable = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.queryable];
		} else if ([self.elementBeingParsed isEqualToString:@"orderable"]) {
			self.propertyBeingParsed.orderable = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.orderable];
		} else if ([self.elementBeingParsed isEqualToString:@"openChoice"]) {
			self.propertyBeingParsed.openChoice = [NSString stringByAppendingString:string toString:self.propertyBeingParsed.openChoice];
		} 
	}
}

@end

/*
 
 sample output from cmis 1.0 / alfresco community 3.2r2

 <?xml version="1.0" encoding="UTF-8"?>
 <entry xmlns="http://www.w3.org/2005/Atom" xmlns:app="http://www.w3.org/2007/app" xmlns:cmisra="http://docs.oasis-open.org/ns/cmis/restatom/200908/" xmlns:cmis="http://docs.oasis-open.org/ns/cmis/core/200908/" xmlns:alf="http://www.alfresco.org">
 <author><name>mmuller</name></author>
 <content>cmis:document</content>
 <id>urn:uuid:type-cmis:document</id>
 <link rel="self" href="http://cm.ziaconsulting.com:80/alfresco/service/cmis/type/cmis:document"/>
 <link rel="describedby" href="http://cm.ziaconsulting.com:80/alfresco/service/cmis/type/cmis:document"/>
 <link rel="down" href="http://cm.ziaconsulting.com:80/alfresco/service/cmis/type/cmis:document/children" type="application/atom+xml;type=feed"/>
 <link rel="down" href="http://cm.ziaconsulting.com:80/alfresco/service/cmis/type/cmis:document/descendants" type="application/cmistree+xml"/>
 <link rel="service" href="http://cm.ziaconsulting.com:80/alfresco/service/cmis"/>
 <summary>Document Type</summary>
 <title>Document</title>
 <updated>2010-05-11T03:04:22.214Z</updated>
 <cmisra:type cmisra:id="cmis:document" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="cmis:cmisTypeDocumentDefinitionType">
 <cmis:id>cmis:document</cmis:id>
 <cmis:localName>document</cmis:localName>
 <cmis:localNamespace>http://www.alfresco.org/model/cmis/1.0/cd04</cmis:localNamespace>
 <cmis:displayName>Document</cmis:displayName>
 <cmis:queryName>cmis:document</cmis:queryName>
 <cmis:description>Document Type</cmis:description>
 <cmis:baseId>cmis:document</cmis:baseId>
 <cmis:creatable>true</cmis:creatable>
 <cmis:fileable>true</cmis:fileable>
 <cmis:queryable>true</cmis:queryable>
 <cmis:fulltextIndexed>true</cmis:fulltextIndexed>
 <cmis:includedInSupertypeQuery>true</cmis:includedInSupertypeQuery>
 <cmis:controllablePolicy>false</cmis:controllablePolicy>
 <cmis:controllableACL>false</cmis:controllableACL>
 
 <cmis:propertyBooleanDefinition>
 <cmis:id>cmis:isLatestMajorVersion</cmis:id>
 <cmis:localName>isLatestMajorVersion</cmis:localName>
 <cmis:localNamespace>http://www.alfresco.org/model/cmis/1.0/cd04</cmis:localNamespace>
 <cmis:displayName>Is Latest Major Version</cmis:displayName>
 <cmis:queryName>cmis:isLatestMajorVersion</cmis:queryName>
 <cmis:description>Is this the latest major version of the document?</cmis:description>
 <cmis:propertyType>boolean</cmis:propertyType>
 <cmis:cardinality>single</cmis:cardinality>
 <cmis:updatability>readonly</cmis:updatability>
 <cmis:inherited>false</cmis:inherited>
 <cmis:required>false</cmis:required>
 <cmis:queryable>false</cmis:queryable>
 <cmis:orderable>false</cmis:orderable>
 <cmis:openChoice>false</cmis:openChoice>
 </cmis:propertyBooleanDefinition>
 
 <cmis:propertyIdDefinition>
 <cmis:id>cmis:contentStreamId</cmis:id>
 <cmis:localName>contentStreamId</cmis:localName>
 <cmis:localNamespace>http://www.alfresco.org/model/cmis/1.0/cd04</cmis:localNamespace>
 <cmis:displayName>Content Stream Id</cmis:displayName>
 <cmis:queryName>cmis:contentStreamId</cmis:queryName>
 <cmis:description>Id of the stream</cmis:description>
 <cmis:propertyType>id</cmis:propertyType>
 <cmis:cardinality>single</cmis:cardinality>
 <cmis:updatability>readonly</cmis:updatability>
 <cmis:inherited>false</cmis:inherited>
 <cmis:required>false</cmis:required>
 <cmis:queryable>true</cmis:queryable>
 <cmis:orderable>true</cmis:orderable>
 <cmis:openChoice>false</cmis:openChoice>
 </cmis:propertyIdDefinition>
 <cmis:propertyIntegerDefinition>
 <cmis:id>cmis:contentStreamLength</cmis:id>
 <cmis:localName>contentStreamLength</cmis:localName>
 <cmis:localNamespace>http://www.alfresco.org/model/cmis/1.0/cd04</cmis:localNamespace>
 <cmis:displayName>Content Stream Length</cmis:displayName>
 <cmis:queryName>cmis:contentStreamLength</cmis:queryName>
 <cmis:description>The length of the content stream</cmis:description>
 <cmis:propertyType>integer</cmis:propertyType>
 <cmis:cardinality>single</cmis:cardinality>
 <cmis:updatability>readonly</cmis:updatability>
 <cmis:inherited>false</cmis:inherited>
 <cmis:required>false</cmis:required>
 <cmis:queryable>true</cmis:queryable>
 <cmis:orderable>true</cmis:orderable>
 <cmis:openChoice>false</cmis:openChoice>
 </cmis:propertyIntegerDefinition>
 <cmis:propertyStringDefinition>
 <cmis:id>cmis:versionSeriesCheckedOutBy</cmis:id>
 <cmis:localName>versionSeriesCheckedOutBy</cmis:localName>
 <cmis:localNamespace>http://www.alfresco.org/model/cmis/1.0/cd04</cmis:localNamespace>
 <cmis:displayName>Version Series Checked Out By</cmis:displayName>
 <cmis:queryName>cmis:versionSeriesCheckedOutBy</cmis:queryName>
 <cmis:description>The authority who checked out this document version series</cmis:description>
 <cmis:propertyType>string</cmis:propertyType>
 <cmis:cardinality>single</cmis:cardinality>
 <cmis:updatability>readonly</cmis:updatability>
 <cmis:inherited>false</cmis:inherited>
 <cmis:required>false</cmis:required>
 <cmis:queryable>false</cmis:queryable>
 <cmis:orderable>false</cmis:orderable>
 <cmis:openChoice>false</cmis:openChoice>
 </cmis:propertyStringDefinition>

*/
