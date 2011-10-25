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
//  ServiceDocumentParser.m
//  

#import "ServiceDocumentParser.h"
#import "ServiceInfo.h"
#import "RepositoryServices.h"
#import "CMISMediaTypes.h"
#import "LinkRelationService.h"


@implementation ServiceDocumentParser
@synthesize serviceDocData;
@synthesize currentRepositoryInfo;
@synthesize repositoryInfoDictionary;
@synthesize currentCollectionHref;
@synthesize elementBeingParsed;
@synthesize namespaceBeingParsed;
@synthesize collectionType;
@synthesize collectionMediaTypeAcceptArray;
@synthesize inCMISRepositoryInfoElement;

- (void)dealloc
{
	[serviceDocData release];
	[currentRepositoryInfo release];
	[repositoryInfoDictionary release];
	[currentCollectionHref release];
	[elementBeingParsed release];
	[namespaceBeingParsed release];
	[collectionType release];
	[collectionMediaTypeAcceptArray release];
	[super dealloc];
}

- (id)initWithAtomPubServiceDocumentData:(NSData *)appData
{
	if ((self = [super init])) {
		serviceDocData = [appData copy];
		inCMISRepositoryInfoElement = NO;
	}
	return self;
}

- (void)parse {
	// create a parser and parse the xml
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:serviceDocData];
	[parser setShouldProcessNamespaces:YES];
	[parser setDelegate:self];
	[parser parse];
	[parser release];	
} // synchronous parse


#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
	ServiceInfo* serviceInfo = [ServiceInfo sharedInstance];
	
	if ([elementName isEqualToString:@"workspace"] && [serviceInfo isAtomPubNamespace:namespaceURI]) {
		[self setCurrentRepositoryInfo:[[[RepositoryInfo alloc] init] autorelease]];
	}
	else if ([elementName isEqualToString:@"repositoryInfo"] 
			 && ([serviceInfo isCmisRestAtomNamespace:namespaceURI] // CMIS 1.0 uses cmis rest atom NS
				 || [serviceInfo isCmisNamespace:namespaceURI])) // !!!: draft CMIS versions use cmis NS
	{
		inCMISRepositoryInfoElement = YES;
		[self setRepositoryInfoDictionary:[NSMutableDictionary dictionary]];
	}
	else if ([elementName isEqualToString:@"collection"] && [serviceInfo isAtomPubNamespace:namespaceURI]) {
		[self setCurrentCollectionHref:[attributeDict objectForKey:@"href"]];
		[self setCollectionMediaTypeAcceptArray:[NSMutableArray array]];
		
		// !!!: for backwards compatibility with cmis .6 (as shipped in alfresco community 3.2.0)
		NSString *type = [attributeDict objectForKey:@"cmis:collectionType"];
		if ([type isEqualToString:@"rootchildren"]) {
			[currentRepositoryInfo setRootFolderHref:[attributeDict objectForKey:@"href"]];
		}
	}
	
	[self setElementBeingParsed:elementName];
	[self setNamespaceBeingParsed:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	ServiceInfo* serviceInfo = [ServiceInfo sharedInstance];
	
	if ([self.elementBeingParsed isEqualToString:@"collectionType"] && [serviceInfo isCmisRestAtomNamespace:namespaceBeingParsed]) {
		self.collectionType = self.collectionType ? [self.collectionType stringByAppendingString:string] : string;
	}
	//	else if ([self.elementBeingParsed isEqualToString:@"cmisVersionSupported"] && [serviceInfo isCmisNamespace:namespaceBeingParsed]) {
	//		self.cmisVersion = self.cmisVersion ? [self.cmisVersion stringByAppendingString:string] : string;
	//	}
	else if ([elementBeingParsed isEqualToString:@"accept"] && [serviceInfo isAtomPubNamespace:namespaceBeingParsed]) {
		[collectionMediaTypeAcceptArray addObject:string];
	}
	else if (inCMISRepositoryInfoElement && [serviceInfo isCmisNamespace:namespaceBeingParsed]) {
		/*
		 <cmis:repositoryId>DaphneA</cmis:repositoryId>
		 <cmis:repositoryName>DaphneA</cmis:repositoryName>
		 <cmis:repositoryDescription>DaphneA</cmis:repositoryDescription>
		 <cmis:vendorName>IBM</cmis:vendorName>
		 <cmis:productName>IBM FileNet P8 Content Manager</cmis:productName>
		 <cmis:productVersion>5.0.0</cmis:productVersion>
		 <cmis:rootFolderId>idf_0F1E2D3C-4B5A-6978-8796-A5B4C3D2E1F0</cmis:rootFolderId>
		 <cmis:capabilities>
		 <cmis:capabilityACL>none</cmis:capabilityACL>
		 <cmis:capabilityAllVersionsSearchable>true</cmis:capabilityAllVersionsSearchable>
		 <cmis:capabilityChanges>none</cmis:capabilityChanges>
		 <cmis:capabilityContentStreamUpdatability>pwconly</cmis:capabilityContentStreamUpdatability>
		 <cmis:capabilityGetDescendants>true</cmis:capabilityGetDescendants>
		 <cmis:capabilityGetFolderTree>true</cmis:capabilityGetFolderTree>
		 <cmis:capabilityMultifiling>true</cmis:capabilityMultifiling>
		 <cmis:capabilityPWCSearchable>true</cmis:capabilityPWCSearchable>
		 <cmis:capabilityPWCUpdatable>true</cmis:capabilityPWCUpdatable>
		 <cmis:capabilityQuery>bothcombined</cmis:capabilityQuery>
		 <cmis:capabilityRenditions>none</cmis:capabilityRenditions>
		 <cmis:capabilityUnfiling>true</cmis:capabilityUnfiling>
		 <cmis:capabilityVersionSpecificFiling>false</cmis:capabilityVersionSpecificFiling>
		 <cmis:capabilityJoin>innerandouter</cmis:capabilityJoin>
		 </cmis:capabilities>
		 <cmis:cmisVersionSupported>1.0</cmis:cmisVersionSupported>
		 */
		if ([elementBeingParsed isEqualToString:@"capabilities"]) {
			// TODO: Skip Capabilities for now but implementation needed
		}
		else {
			// We're going to use key-value coding to populate the RepositoryInfo class
			NSString *object = [repositoryInfoDictionary objectForKey:elementBeingParsed];
			[repositoryInfoDictionary setObject:((object) ? [object stringByAppendingString:string] : string) 
										 forKey:elementBeingParsed];
		}
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	ServiceInfo* serviceInfo = [ServiceInfo sharedInstance];
	
	[self setElementBeingParsed:nil];
	[self setNamespaceBeingParsed:nil];
	
	if ([elementName isEqualToString:@"collectionType"] && [serviceInfo isCmisRestAtomNamespace:namespaceURI]) {
		
		if ([self.collectionType isEqualToString:@"root"]) {
			[currentRepositoryInfo setRootFolderHref:currentCollectionHref];
		}
		
		[self setCollectionType:nil];
	}
	else if ([elementName isEqualToString:@"collection"] && [serviceInfo isAtomPubNamespace:namespaceURI]) {
		if ([collectionMediaTypeAcceptArray containsObject:kCMISQueryMediaType]) {
			[currentRepositoryInfo setCmisQueryHref:currentCollectionHref];
		}
		
		[self setCurrentCollectionHref:nil];
		[collectionMediaTypeAcceptArray removeAllObjects];
	}
	else if ([elementName isEqualToString:@"repositoryInfo"] 
			 && ([serviceInfo isCmisRestAtomNamespace:namespaceURI] // CMIS 1.0 uses cmis rest atom NS
				 || [serviceInfo isCmisNamespace:namespaceURI])) // !!!: draft CMIS versions use cmis NS
	{
		[currentRepositoryInfo setValuesForKeysWithDictionary:repositoryInfoDictionary];
		
		inCMISRepositoryInfoElement = NO;		
		[self setRepositoryInfoDictionary:nil];
	}
	else if ([elementName isEqualToString:@"workspace"] && [serviceInfo isAtomPubNamespace:namespaceURI]) {
		[[RepositoryServices shared] addRepositoryInfo:currentRepositoryInfo 
									  forRepositoryId:[currentRepositoryInfo repositoryId]];
	}
}

@end
