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
//  ServiceDocumentRequest.m
//

#import "ServiceDocumentRequest.h"
#import "Utility.h"
#import "ServiceInfo.h"
#import "CMISMediaTypes.h"
#import "ASIHTTPRequest+Utils.h"
#import "ServiceDocumentParser.h"

@implementation ServiceDocumentRequest

- (void)requestFinished
{
	//	Check that we are valid
	if (![self responseSuccessful]) {
		// FIXME: Recode domain, code and userInfo.  Use ASI as an example but do for CMIS errors
		// !!!: Make sure to cleanup because we are in an error
		
		[self failWithError:[NSError errorWithDomain:CMISNetworkRequestErrorDomain 
												code:ASIUnhandledExceptionError userInfo:nil]];
		 return;
	}
	
	// !!!: Check media type
		 
	ServiceDocumentParser *needToReimpl = [[ServiceDocumentParser alloc] initWithAtomPubServiceDocumentData:self.responseData];
	[needToReimpl parse];
	[needToReimpl release];

	[super requestFinished];
}

- (void)failWithError:(NSError *)theError
{
	// TODO: We should be logging something here and doing something!
	[super failWithError:theError];
}

#pragma mark -
#pragma mark Factory Methods

+ (id)httpGETRequest
{
	NSURL *url = [[ServiceInfo sharedInstance] serviceDocumentURL];
	ServiceDocumentRequest *getRequest = [ServiceDocumentRequest requestWithURL:url];
	[getRequest addBasicAuthHeader];
	[getRequest setAllowCompressedResponse:YES]; // this is the default, but being verbose
	
	[getRequest addRequestHeader:@"Accept" value:kAtomPubServiceMediaType];
	[getRequest setRequestMethod:@"GET"];
	
	return getRequest;
}

@end
