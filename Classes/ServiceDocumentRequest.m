//
//  ServiceDocumentRequest.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 11/10/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
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
