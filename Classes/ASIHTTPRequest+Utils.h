//
//  ASIHTTPRequest+Utils.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 11/10/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

extern NSString * const CMISNetworkRequestErrorDomain;

@interface ASIHTTPRequest (Utils)

- (BOOL)responseSuccessful;
- (void)addBasicAuthHeader;

@end
