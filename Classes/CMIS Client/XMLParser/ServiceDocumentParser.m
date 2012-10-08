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
//  ServiceDocumentParser.m
//

#import "ServiceDocumentParser.h"
#import "CMISMediaTypes.h"
#import "CMISUtils.h"

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
@synthesize currentTemplateValue;
@synthesize currentTemplateType;
@synthesize accountUuid;
@synthesize tenantID;

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
    [currentTemplateValue release];
    [currentTemplateType release];
    [accountUuid release];
    [tenantID release];
    
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

/**
 R - Required
 S - If supported
 
 MUST PARSE OUT
	(R) Root Folder Children Collection: Root folder of the Repository
	(R) Types Children Collection: Collection containing the base types in the repository
	(S) Query collection: Collection for posting queries to be executed
 
 FUTURE:
 **/

#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
	if ([elementName isEqualToString:@"workspace"] && [CMISUtils isAtomPubNamespace:namespaceURI]) {
		[self setCurrentRepositoryInfo:[[[RepositoryInfo alloc] init] autorelease]];
	}
	else if ([elementName isEqualToString:@"repositoryInfo"] 
			 && ([CMISUtils isCmisRestAtomNamespace:namespaceURI] // CMIS 1.0 uses cmis rest atom NS
				 || [CMISUtils isCmisNamespace:namespaceURI])) // !!!: draft CMIS versions use cmis NS
	{
		inCMISRepositoryInfoElement = YES;
		[self setRepositoryInfoDictionary:[NSMutableDictionary dictionary]];
	}
	else if ([elementName isEqualToString:@"collection"] && [CMISUtils isAtomPubNamespace:namespaceURI]) {
		[self setCurrentCollectionHref:[attributeDict objectForKey:@"href"]];
		[self setCollectionMediaTypeAcceptArray:[NSMutableArray array]];
		
		// !!!: for backwards compatibility with cmis .6 (as shipped in alfresco community 3.2.0)
		NSString *type = [attributeDict objectForKey:@"cmis:collectionType"];
		if ([type isEqualToString:@"rootchildren"]) {
			[currentRepositoryInfo setRootFolderHref:[attributeDict objectForKey:@"href"]];
		}
	}
    else if ([elementName isEqualToString:@"uritemplate"] && [CMISUtils isCmisRestAtomNamespace:namespaceURI]) {
        isUriTemplate = YES;
        [self setCurrentTemplateType:@""];
        [self setCurrentTemplateValue:@""];
    }
    
	
	[self setElementBeingParsed:elementName];
	[self setNamespaceBeingParsed:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	if ([self.elementBeingParsed isEqualToString:@"collectionType"] && [CMISUtils isCmisRestAtomNamespace:namespaceBeingParsed]) {
		self.collectionType = self.collectionType ? [self.collectionType stringByAppendingString:string] : string;
	}
	//	else if ([self.elementBeingParsed isEqualToString:@"cmisVersionSupported"] && [CMISUtils isCmisNamespace:namespaceBeingParsed]) {
	//		self.cmisVersion = self.cmisVersion ? [self.cmisVersion stringByAppendingString:string] : string;
	//	}
	else if ([elementBeingParsed isEqualToString:@"accept"] && [CMISUtils isAtomPubNamespace:namespaceBeingParsed]) {
		[collectionMediaTypeAcceptArray addObject:string];
	}
	else if (inCMISRepositoryInfoElement && [CMISUtils isCmisNamespace:namespaceBeingParsed]) 
    {
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
    else if (isUriTemplate && [CMISUtils isCmisRestAtomNamespace:namespaceBeingParsed]) {
        if ([elementBeingParsed isEqualToString:@"template"]) {
            [self setCurrentTemplateValue:[currentTemplateValue stringByAppendingString:string]];
        } else if ([elementBeingParsed isEqualToString:@"type"]) {
            [self setCurrentTemplateType:[currentTemplateType stringByAppendingString:string]];
        }
    }
    else if ([elementBeingParsed isEqualToString:@"productVersion"] && [CMISUtils isCmisNamespace:namespaceBeingParsed]) {
        [repositoryInfoDictionary setObject:string forKey:@"productVersion"];
    }
    else if ([elementBeingParsed isEqualToString:@"productName"] && [CMISUtils isCmisNamespace:namespaceBeingParsed]) {
        [repositoryInfoDictionary setObject:string forKey:@"productName"];
    }
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	[self setElementBeingParsed:nil];
	[self setNamespaceBeingParsed:nil];
	
	if ([elementName isEqualToString:@"collectionType"] && [CMISUtils isCmisRestAtomNamespace:namespaceURI]) {
		
		if ([self.collectionType isEqualToString:@"root"]) {
			[currentRepositoryInfo setRootFolderHref:currentCollectionHref];
		}
		
		[self setCollectionType:nil];
	}
	else if ([elementName isEqualToString:@"collection"] && [CMISUtils isAtomPubNamespace:namespaceURI]) {
		if ([collectionMediaTypeAcceptArray containsObject:kCMISQueryMediaType]) {
			[currentRepositoryInfo setCmisQueryHref:currentCollectionHref];
		}
		
		[self setCurrentCollectionHref:nil];
		[collectionMediaTypeAcceptArray removeAllObjects];
	}
	else if ([elementName isEqualToString:@"repositoryInfo"] 
			 && ([CMISUtils isCmisRestAtomNamespace:namespaceURI] // CMIS 1.0 uses cmis rest atom NS
				 || [CMISUtils isCmisNamespace:namespaceURI])) // !!!: draft CMIS versions use cmis NS
	{
		[currentRepositoryInfo setValuesForKeysWithDictionary:repositoryInfoDictionary];
		
		inCMISRepositoryInfoElement = NO;		
		[self setRepositoryInfoDictionary:nil];
	}
	else if ([elementName isEqualToString:@"workspace"] && [CMISUtils isAtomPubNamespace:namespaceURI]) {
		[[RepositoryServices shared] addRepositoryInfo:currentRepositoryInfo 
                                        forAccountUuid:accountUuid tenantID:[self tenantID]];
	}
    else if ([elementName isEqualToString:@"uritemplate"] && [CMISUtils isCmisRestAtomNamespace:namespaceURI]) {
        if (currentTemplateType) {
            if ([currentTemplateType isEqualToString:@"objectbyid"]) {
                [currentRepositoryInfo setObjectByIdUriTemplate:currentTemplateValue];
            } else if ([currentTemplateType isEqualToString:@"objectbypath"]) {
                [currentRepositoryInfo setObjectByPathUriTemplate:currentTemplateValue];
            } else if ([currentTemplateType isEqualToString:@"typebyid"]) {
                [currentRepositoryInfo setTypeByIdUriTemplate:currentTemplateValue];
            } else if ([currentTemplateType isEqualToString:@"query"]) {
                [currentRepositoryInfo setQueryUriTemplate:currentTemplateValue];
            }
        }
        
        [self setCurrentTemplateValue:nil];
        [self setCurrentTemplateType:nil];
        isUriTemplate = NO;
    }
}

@end
