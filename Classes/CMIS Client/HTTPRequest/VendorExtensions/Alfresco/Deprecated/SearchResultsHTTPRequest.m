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
//  SearchResultsHTTPRequest.m
//

#import "SearchResultsHTTPRequest.h"
#import "AlfrescoUtils.h"
#import "RepositoryItemsParser.h"

#define kMaxSearchResults 30

@implementation SearchResultsHTTPRequest

@synthesize results;
@synthesize itemsParser;

- (void) dealloc {
	[results release];
    [itemsParser release];
	[super dealloc];
}

- (SearchResultsHTTPRequest *) initWithSearchPattern:(NSString *)pattern {
	NSString *webappUrlString = [[AlfrescoUtils sharedInstanceForAccountUUID:self.accountUUID] hostURL];
	NSString *patternEncoded = [pattern stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
		// !!!: Should this be UTF8 Encoded?

	NSString *urlStr = [[NSString alloc] initWithFormat:@"%@/alfresco/service/search/keyword.atom?q=%@&p=1&c=%d", webappUrlString, patternEncoded, kMaxSearchResults];
	NSURL *u = [NSURL URLWithString:urlStr];
	[urlStr release];
	return [self initWithURL:u];
}

- (void)requestFinishedWithSuccessResponse
{
    self.itemsParser = [[[RepositoryItemsParser alloc] initWithData:[self responseData]] autorelease];
    [itemsParser setAccountUUID:self.accountUUID];
    [itemsParser parse];
    
    self.results = [itemsParser children];
}

@end
