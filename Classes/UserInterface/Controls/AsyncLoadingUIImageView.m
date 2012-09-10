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
// AsyncLoadingUIImageView 
//

#import "AsyncLoadingUIImageView.h"
#import "ASIHTTPRequest.h"
#import "BaseHTTPRequest.h"


typedef void (^AsyncLoadingUIImageViewSuccessBlock)(UIImage *);
typedef void (^AsyncLoadingUIInageViewFailureBlock)(NSError *);

@interface AsyncLoadingUIImageView () <ASIHTTPRequestDelegate>

@property AsyncLoadingUIImageViewSuccessBlock successBlock;
@property AsyncLoadingUIInageViewFailureBlock failureBlock;

@end


@implementation AsyncLoadingUIImageView

@synthesize successBlock = _successBlock;
@synthesize failureBlock = _failureBlock;

#pragma mark Lazy loading public methods

- (void)setImageWithRequest:(BaseHTTPRequest *)request
{
    [self setImageWithRequest:request succes:nil failure:nil];
}

- (void)setImageWithRequest:(BaseHTTPRequest *)request
                     succes:(AsyncLoadingUIImageViewSuccessBlock)successBlock
                    failure:(AsyncLoadingUIInageViewFailureBlock)failureBlock
{
    if (self.image)
    {
        self.image = nil;
    }

    if (successBlock)
    {
        self.successBlock = successBlock;
    }

    if (failureBlock)
    {
        self.failureBlock = failureBlock;
    }

    // Start async fetch
    request.suppressAllErrors = YES; // we don't want to see an alert view for unreachable images
    [request setDelegate:self];
    [request startAsynchronous];
}

#pragma mark ASIHTTPRequestDelegate methods

- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Update the UI
    self.image = [UIImage imageWithData:request.responseData];

    // Execute the success block
    if (self.successBlock)
    {
        self.successBlock(self.image);
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"Request failed: %@", request.error.localizedDescription);
    if (self.failureBlock)
    {
        self.failureBlock(request.error);
    }
}

@end
