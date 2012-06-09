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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  DownloadNetworkQueue.m
//

#import "DownloadNetworkQueue.h"
#import "ASIHTTPRequest.h"
#import <objc/runtime.h>

@implementation DownloadNetworkQueue

// Only add ASIHTTPRequests to this queue!!
- (void)addOperation:(NSOperation *)operation withFileSize:(NSNumber *)fileSize
{
	if (![operation isKindOfClass:[ASIHTTPRequest class]]) {
		[NSException raise:@"AttemptToAddInvalidRequest" format:@"Attempted to add an object that was not an ASIHTTPRequest to an ASINetworkQueue"];
	}
    
	requestsCount++;
	
	ASIHTTPRequest *request = (ASIHTTPRequest *)operation;
	
	if ([self showAccurateProgress])
    {
		// Force the request to build its body (this may change requestMethod)
		[request buildPostBody];
		
		// CMIS content requests do not support the HTTP HEAD method, so we'll make ASIHTTPRequest in the same
        // state it would be if it had received the HEAD response.
        if ([[request requestMethod] isEqualToString:@"GET"])
        {
            [self request:nil incrementDownloadSizeBy:[fileSize longLongValue]];
            [request setShouldResetDownloadProgress:NO];
		}
	}
    else
    {
		[self request:nil incrementDownloadSizeBy:1];
		[self request:nil incrementUploadSizeBy:1];
	}
	
	[request setShowAccurateProgress:[self showAccurateProgress]];
	
	[request setQueue:self];
    
    // We need to call addOperation: on NSOperationQueue NOT ASINetworkQueue
    SEL addOperationSel = @selector(addOperation:);
    Method addOperationMethod = class_getInstanceMethod([[self superclass] superclass], addOperationSel);
    IMP addOperationImp = method_getImplementation(addOperationMethod);
    addOperationImp(self, addOperationSel, request);    
}

@end
