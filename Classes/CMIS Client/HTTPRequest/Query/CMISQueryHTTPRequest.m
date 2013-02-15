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
//  CMISQueryHTTPRequest.m
//

#import "CMISQueryHTTPRequest.h"
#import "RepositoryInfo.h"
#import "RepositoryServices.h"
#import "CMISMediaTypes.h"
#import "RepositoryItem.h"
#import "RepositoryItemsParser.h"

#define kMaxSearchResults 30

@implementation CMISQueryHTTPRequest

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

- (id)initWithQuery:(NSString *)cql accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
	RepositoryInfo *repositoryInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:uuid tenantID:aTenantID];
	NSString *queryCollectionServiceLocation = [repositoryInfo cmisQueryHref];

	// TODO: Add Unsupported Functionality Exception + Handling

	NSURL *u = [NSURL URLWithString:queryCollectionServiceLocation];
		
	NSString *queryTemplate = @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
	"<cmis:query xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\" xmlns:cmism=\"http://docs.oasis-open.org/ns/cmis/messaging/200908/\" xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">\n"
    "<cmis:statement>%@</cmis:statement>\n"
    "<cmis:searchAllVersions>false</cmis:searchAllVersions>\n"
    "<cmis:includeAllowableActions>true</cmis:includeAllowableActions>\n"
    "<cmis:includeRelationships>none</cmis:includeRelationships>\n"
    "<cmis:renditionFilter>*</cmis:renditionFilter>\n"
    "<cmis:maxItems>%d</cmis:maxItems>\n"
    "<cmis:skipCount>0</cmis:skipCount>\n"
	"</cmis:query>";

	NSString *query = [[NSString alloc] initWithFormat:queryTemplate, cql, kMaxSearchResults];
	self.postData = query;

	AlfrescoLogTrace(@"sending query: %@", query);

	[query release];
    
    self = [self initWithURL:u accountUUID:uuid];
    if(self) {
        [self setTenantID:aTenantID];
        
        // create a post request
        NSMutableURLRequest *requestObj = [NSMutableURLRequest requestWithURL:u];
        NSData *d = [self.postData dataUsingEncoding:NSUTF8StringEncoding];
        
        [requestObj setHTTPMethod:@"POST"];

        AlfrescoLogTrace(@"\n\n%@", [requestObj allHTTPHeaderFields]);
        AlfrescoLogTrace(@"\n\n%@", [[[NSString alloc] initWithData:[requestObj HTTPBody] encoding:NSUTF8StringEncoding] autorelease]);
        
        [self addRequestHeader:@"Content-Type" value:kCMISQueryMediaType];
        [self setPostBody:[NSMutableData dataWithData:d]];
        [self setContentLength:[d length]];
        
        [self setShouldContinueWhenAppEntersBackground:YES];
        self.delegate = self;
    }
    
	return self;
}

// this is identical to the non-CMIS version
- (void)requestFinishedWithSuccessResponse
{
    self.itemsParser = [[[RepositoryItemsParser alloc] initWithData:[self responseData]] autorelease];
    [itemsParser setAccountUUID:self.accountUUID];
    [itemsParser parse];
    
    self.results = [itemsParser children];
    
    if ([results count] > 0) {
        RepositoryItem *result = nil;
        NSMutableArray *filteredResults = [NSMutableArray arrayWithArray:results];
        
        for(result in results) {
            if (![result title] || [[result title] isEqualToString:@""]) {
                [filteredResults removeLastObject];
            }
        }
        
        [self setResults:filteredResults];
    }
}

@end

