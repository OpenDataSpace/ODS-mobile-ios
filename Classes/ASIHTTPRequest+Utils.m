//
//  ASIHTTPRequest+Utils.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 11/10/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "ASIHTTPRequest+Utils.h"
#import "Utility.h"

NSString * const CMISNetworkRequestErrorDomain = @"FreshDocsCMISNetworkRequestErrorDomain";

@implementation ASIHTTPRequest (Utils)

- (BOOL)responseSuccessful
{
    NSLog(@"Response Status Code: %d", self.responseStatusCode);
	return ((self.responseStatusCode >= 200) && (self.responseStatusCode <= 299));
}

- (void)addBasicAuthHeader
{
	[self addBasicAuthenticationHeaderWithUsername:userPrefUsername() andPassword:userPrefPassword()];
}

- (void)addBasicAuthHeaderForProfile:(NSObject *)repositoryProfile
{
	NSLog(@"Placeholder method, does nothing at the moment");
}

@end
