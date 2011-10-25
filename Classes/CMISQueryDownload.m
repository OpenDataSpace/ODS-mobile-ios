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
//  CMISQueryDownload.m
//

#import "CMISQueryDownload.h"
#import "SearchResult.h"
#import "Utility.h"
#import "ServiceInfo.h"
#import "RepositoryInfo.h"
#import "RepositoryServices.h"
#import "CMISMediaTypes.h"

#define kMaxSearchResults 30

@implementation CMISQueryDownload

@synthesize results;
@synthesize currentCMISProperty;
@synthesize currentCMISPropertyValue;
@synthesize elementBeingParsed;
@synthesize namespaceBeingParsed;
@synthesize postData;

- (void) dealloc {
	[results release];
    [currentCMISProperty release];
    [currentCMISPropertyValue release];    
	[elementBeingParsed release];
    [namespaceBeingParsed release];
	[postData release];
	[super dealloc];
}

- (id)initWithQuery:(NSString *)cql delegate:(id <AsynchronousDownloadDelegate>)del
{
	RepositoryInfo *repositoryInfo = [[RepositoryServices shared] currentRepositoryInfo];
	NSString *queryCollectionServiceLocation = [repositoryInfo cmisQueryHref];

	// TODO: Add Unsupported Functionality Exception + Handling

	NSURL *u = [NSURL URLWithString:queryCollectionServiceLocation];
		
	NSString *queryTemplate = @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
	"<cmis:query xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\" xmlns:cmism=\"http://docs.oasis-open.org/ns/cmis/messaging/200908/\" xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">\n"
    "<cmis:statement>%@</cmis:statement>\n"
    "<cmis:searchAllVersions>false</cmis:searchAllVersions>\n"
    "<cmis:includeAllowableActions>false</cmis:includeAllowableActions>\n"
    "<cmis:includeRelationships>none</cmis:includeRelationships>\n"
    "<cmis:renditionFilter>*</cmis:renditionFilter>\n"
    "<cmis:maxItems>%d</cmis:maxItems>\n"
    "<cmis:skipCount>0</cmis:skipCount>\n"
	"</cmis:query>";
    

	
	// URI Template: 
	/*
	 *	http://cmis.alfresco.com:80/service/cmis/query?q={q}&amp;searchAllVersions={searchAllVersions}
	 *		&amp;maxItems={maxItems}&amp;skipCount={skipCount}&amp;includeAllowableActions={includeAllowableActions}
	 *		&amp;includeRelationships={includeRelationships}
	 */
//	NSString *queryUriTemplate = @"http://cmis.alfresco.com:80/service/cmis/query?q=%@&amp;searchAllVersions=true&maxItems=50&skipCount=0&includeAllowableActions=false&includeRelationships=none"
//	NSString *queryUriTemplate = @"http://cmis.alfresco.com:80/service/cmis/query?q=%@&amp;searchAllVersions={searchAllVersions}&amp;maxItems={maxItems}&amp;skipCount={skipCount}&amp;includeAllowableActions={includeAllowableActions}&amp;includeRelationships={includeRelationships}"
	// q = %@
	// searchAllVersions = true
	// maxItems = %d
	// skipCount = 0
	// includeAllowableActions = false
	// includeRelationships = none

	NSString *query = [[NSString alloc] initWithFormat:queryTemplate, cql, kMaxSearchResults];
	self.postData = query;
    NSLog(@"%@",queryTemplate);
	NSLog(@"sending query: %@", query);
	[query release];
    
	return [self initWithURL:u delegate:del];
}

// this is identical to the non-CMIS version
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	// create an array to hold the folder items
	NSMutableArray *r = [[NSMutableArray alloc] init];
	self.results = r;
	[r release];
	
	// create a parser and parse the xml
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.data];
	[parser setDelegate:self];
	[parser setShouldProcessNamespaces:YES];
	[parser parse];
	[parser release];
	
	// if the user has selected the preference to hide "dot" files, then filter those from the list
	if (!userPrefShowHiddenFiles()) {
		for (int i = [self.results count] - 1; i >= 0; i--) {
			SearchResult *item = [self.results objectAtIndex:i];
			if ([item.title hasPrefix:@"."]) {
				[self.results removeObjectAtIndex:i];
			}
		}
	}
    
    if ([results count] > 0) {
        SearchResult *result = [results lastObject];
        if (![result title] || [[result title] isEqualToString:@""]) {
            [results removeLastObject];
        }
    }
	
	[super connectionDidFinishLoading:connection];
	[self hideHUD];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict 
{
	ServiceInfo *serviceInfo = [ServiceInfo sharedInstance];
	
	// if this is a new entry, create a repository item and add it to the list
	if ([elementName isEqualToString:@"entry"] && [serviceInfo isAtomNamespace:namespaceURI]) {
		SearchResult *r = [[SearchResult alloc] init];
		[self.results addObject:r];
		[r release];
	}
	
	if ([elementName isEqualToString:@"content"] && [serviceInfo isAtomNamespace:namespaceURI]) {
		[[self.results lastObject] setContentLocation: [attributeDict objectForKey:@"src"]];
	}	
	
	if ([elementName hasPrefix:@"property"] && [serviceInfo isCmisNamespace:namespaceURI]) {
		self.currentCMISProperty = [attributeDict objectForKey:@"propertyDefinitionId"];
        [self setCurrentCMISPropertyValue:@""];
	}
	
	[self setElementBeingParsed:elementName];
    [self setNamespaceBeingParsed:namespaceURI];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{  
	ServiceInfo *serviceInfo = [ServiceInfo sharedInstance];    
	if ([elementName hasPrefix:@"property"] && [serviceInfo isCmisNamespace:namespaceURI]) 
    {
        SearchResult *result = [self.results lastObject];
        if ([self.currentCMISProperty isEqualToString:@"cmis:objectId"]) {
            [result setCmisObjectId:self.currentCMISPropertyValue];
        }
        else if ([currentCMISProperty isEqualToString:@"cmis:lastModificationDate"]) {
            [result setLastModifiedDateStr:currentCMISPropertyValue];
        }
        else if ([currentCMISProperty isEqualToString:@"cmis:name"]) {
            [result setTitle:currentCMISPropertyValue];
        }
        else if ([currentCMISProperty isEqualToString:@"cmis:contentStreamLength"]) {
            [result setContentStreamLength:currentCMISPropertyValue];
        }
        else if ([currentCMISProperty isEqualToString:@"cmis:contentStreamMimeType"]) {
            [result setContentStreamMimeType:currentCMISPropertyValue];
        }
        
        [self setCurrentCMISProperty:nil];
        [self setCurrentCMISPropertyValue:nil];
	}
    
    [self setElementBeingParsed:nil];
    [self setNamespaceBeingParsed:nil];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
//	SearchResult *currentItem = [self.results lastObject];
    ServiceInfo *serviceInfo = [ServiceInfo sharedInstance];
	
	if ([self.elementBeingParsed isEqualToString:@"value"] 
			 && [serviceInfo isCmisNamespace:self.namespaceBeingParsed] 
			 && (nil != self.currentCMISProperty) )  
	{
		[self setCurrentCMISPropertyValue:[self.currentCMISPropertyValue stringByAppendingString:string]];
	}
	
	
	/*
	else if ([self.currentCMISProperty isEqualToString:@"Relevance"] && [self.elementBeingParsed isEqualToString:@"cmis:value"]) {
		currentItem.relevance = currentItem.relevance ? [currentItem.relevance stringByAppendingString:string] : string;
	}
	 */
}

- (void) start {
	[self createAndShowHUD];
	
	// create a post request
	NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:url];
	NSData *d = [self.postData dataUsingEncoding:NSUTF8StringEncoding];
	NSString *len = [[NSString alloc] initWithFormat:@"%d", [d length]];
	[requestObj addValue:len forHTTPHeaderField:@"Content-length"];
	[requestObj addValue:kCMISQueryMediaType forHTTPHeaderField:@"Content-Type"];
	[requestObj setHTTPMethod:@"POST"];
	[requestObj setHTTPBody:d];
	[len release];
    
    NSLog(@"\n\n%@", [requestObj allHTTPHeaderFields]);
    NSLog(@"\n\n%@", [[[NSString alloc] initWithData:[requestObj HTTPBody] encoding:NSUTF8StringEncoding] autorelease]);
	
    [self setUrlConnection:[NSURLConnection connectionWithRequest:requestObj delegate:self]];
    [self.urlConnection start];
	
	// start the "network activity" spinner 
	startSpinner();
}

@end

