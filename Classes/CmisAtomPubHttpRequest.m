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
//  CmisAtomPubHttpRequest.m
//

#import "CmisAtomPubHttpRequest.h"
#import "CMISMediaTypes.h"
#import "ASIHTTPRequest+Utils.h"

const NSRange ResponseStatus2xx = {200, 100};

@interface CmisAtomPubHttpRequest () 
- (id)initWithURL:(NSURL *)newURL mediaType:(NSString *)mediaTypeValue;
+ (id)requestWithURL:(NSURL *)newURL mediaType:(NSString *)mediaType;
@end


@implementation CmisAtomPubHttpRequest
@synthesize mediaType;

#pragma mark -
#pragma mark Lifecycle - Memory Management

- (void)dealloc
{
    [mediaType release];
    [super dealloc];
}


#pragma mark Lifecycle - Initialization

- (id)initWithURL:(NSURL *)newURL mediaType:(NSString *)mediaTypeValue
{
    self = [super initWithURL:newURL];
    if (self) {
        [self setMediaType:mediaTypeValue];
        [self addBasicAuthHeader];
        [self setAllowCompressedResponse:YES];
    }
    return self;
}

+ (id)requestWithURL:(NSURL *)newURL mediaType:(NSString *)mediaType
{
    CmisAtomPubHttpRequest *httpRequest = [CmisAtomPubHttpRequest requestWithURL:newURL];
    [httpRequest setMediaType:mediaType];
    [httpRequest addBasicAuthHeader];
    [httpRequest setAllowCompressedResponse:YES];
    
    return httpRequest;
}

#pragma mark -
#pragma mark ASIHTTPRequest delegate methods

- (void)requestFinished
{
    NSLog(@"CMIS AtomPub HTTP Request/r/n%d %@", responseStatusCode, [self url]);
    
    if ( !NSLocationInRange(responseStatusCode, ResponseStatus2xx)) 
    {
        // TODO HANDLE ME BECAUSE I FAILED
        [self failWithError:[NSError errorWithDomain:@"" code:responseStatusCode userInfo:nil]];
        return;
    }
    
    [super requestFinished];
}

- (void)failWithError:(NSError *)theError
{
    [super failWithError:theError];
}


@end
