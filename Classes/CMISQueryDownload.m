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
//  CMISQueryDownload.m
//

#import "CMISQueryDownload.h"
#import "SearchResult.h"
#import "Utility.h"
#import "ServiceInfo.h"
#import "RepositoryInfo.h"
#import "RepositoryServices.h"
#import "CMISMediaTypes.h"
#import "ASIHTTPRequest+Utils.h"
#import "RepositoryItem.h"
#import "RepositoryItemsParser.h"

#define kMaxSearchResults 30

@implementation CMISQueryDownload

@synthesize results;
@synthesize currentCMISProperty;
@synthesize currentCMISPropertyValue;
@synthesize elementBeingParsed;
@synthesize namespaceBeingParsed;
@synthesize postData;
@synthesize itemsParser;

- (void) dealloc {
	[results release];
    [currentCMISProperty release];
    [currentCMISPropertyValue release];    
	[elementBeingParsed release];
    [namespaceBeingParsed release];
	[postData release];
    [itemsParser release];
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

	NSString *query = [[NSString alloc] initWithFormat:queryTemplate, cql, kMaxSearchResults];
	self.postData = query;
    NSLog(@"%@",queryTemplate);
	NSLog(@"sending query: %@", query);
	[query release];
    
	return [self initWithURL:u delegate:del];
}

// this is identical to the non-CMIS version
- (void)requestFinished:(ASIHTTPRequest *)request {
    self.itemsParser = [[[RepositoryItemsParser alloc] initWithData:request.responseData] autorelease];
    self.results = [itemsParser children];
    
    if ([results count] > 0) {
        RepositoryItem *result = [results lastObject];
        if (![result title] || [[result title] isEqualToString:@""]) {
            [results removeLastObject];
        }
    }
	
	[super requestFinished:request];
}

- (void) start {
	[self createAndShowHUD];
	
	// create a post request
	NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:url];
	NSData *d = [self.postData dataUsingEncoding:NSUTF8StringEncoding];

	[requestObj setHTTPMethod:@"POST"];
    
    NSLog(@"\n\n%@", [requestObj allHTTPHeaderFields]);
    NSLog(@"\n\n%@", [[[NSString alloc] initWithData:[requestObj HTTPBody] encoding:NSUTF8StringEncoding] autorelease]);
	
    self.httpRequest = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    [self.httpRequest addRequestHeader:@"Content-Type" value:kCMISQueryMediaType];
    [self.httpRequest setPostBody:[NSMutableData dataWithData:d]];
    [self.httpRequest setContentLength:[d length]];
    
    [self.httpRequest addBasicAuthHeader];
    self.httpRequest.delegate = self;
    [self.httpRequest startAsynchronous];
	
	// start the "network activity" spinner 
	startSpinner();
}

@end

