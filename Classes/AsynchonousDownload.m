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
//  AsynchonousDownload.m
//

#import "AsynchonousDownload.h"
#import "Utility.h"
#import "AlfrescoAppDelegate.h"
#import "ASIHTTPRequest+Utils.h"

NSString * const NSHTTPPropertyStatusCodeKey = @"NSHTTPPropertyStatusCodeKey";

@implementation AsynchonousDownload

@synthesize data;
@synthesize url;
@synthesize httpRequest;
@synthesize delegate;
@synthesize show500StatusError;
@synthesize responseStatusCode;
@synthesize HUD;
@synthesize showHUD;

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self cancel];
	[data release];
	[url release];
    [httpRequest release];
	[super dealloc];
}

- (id)initWithURL:(NSURL *)u delegate:(id <AsynchronousDownloadDelegate>)del {
	
	NSLog(@"initializing asynchronous download from: %@", u);
    self = [super init];
	if (self) {
		NSMutableData *d = [[NSMutableData alloc] init];
		[self setData:d];
		[d release];
		
		[self setUrl:[[u copy] autorelease]];
		[self setDelegate:del];
        
        show500StatusError = YES;
	}
	return self;
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate methods

- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders {
    int statusCode = self.httpRequest.responseStatusCode;
    
    if (statusCode >= 400)
    {
        [self cancel];  // stop connecting; no more delegate messages
        NSString *msg = [[NSString alloc] initWithFormat: @"%d %@", statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]];
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey];
        NSError *statusError = [NSError errorWithDomain:NSHTTPPropertyStatusCodeKey code:statusCode userInfo:errorInfo];
        request.error = statusError;
        [self requestFailed:request];
        [msg release];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    // log the response
	NSLog(@"async result: %@", [request responseString]);
	
	// stop the "network activity" spinner 
	stopSpinner();
    self.data = [NSMutableData dataWithData:[request responseData]];
    self.httpRequest = nil;
	
	if (self.delegate) {

        [(NSThread *)self.delegate performSelectorOnMainThread:@selector(asyncDownloadDidComplete:) withObject:self waitUntilDone:NO];
	}
	
	[self hideHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    // stop the "network activity" spinner 
	stopSpinner();
	[self hideHUD];

	// if it's an auth failure
	if ([[request.error domain] isEqualToString:NetworkRequestErrorDomain] && [request.error code] == ASIAuthenticationErrorType) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"authenticationFailureTitle", @"Authentication Failure Title Text 'Authentication Failure'")
                                                        message:NSLocalizedString(@"authenticationFailureMessage", @"Please check your username and password in the iPhone settings for Fresh Docs") 
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK button text")
                                              otherButtonTitles:nil];
		[alert show];
        [alert release];
	}
	
	// let the user know something else bad happened
	else {
        if (! ([[request.error domain] isEqualToString:NSHTTPPropertyStatusCodeKey] && ([request.error code] == 500)) 
            || show500StatusError) 
        {
            NSString *msg = [[NSString alloc] initWithFormat:@"%@ %@\n\n%@", 
                             NSLocalizedString(@"connectionErrorMessage", @"The server returned an error connecting to URL. Localized Error Message"), 
                             [self.url absoluteURL], [request.error localizedDescription]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"connectionErrorTitle", @"Connection error")
                                                            message:msg delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK button text")
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            [msg release];
        }
	}
	
	if (self.delegate) {
		[delegate asyncDownload:self didFailWithError:request.error];
	}
}

- (void) start {
	[self createAndShowHUD];
	
	// start downloading
    self.httpRequest = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    self.httpRequest.delegate = self;
    [self.httpRequest addBasicAuthHeader];
    [self.httpRequest startAsynchronous];
	
	// start the "network activity" spinner 
	startSpinner();
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelActiveConnection:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (ASIHTTPRequest *) asiHttpRequest {
	// start downloading
    self.httpRequest = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    self.httpRequest.delegate = self;
    [self.httpRequest addBasicAuthHeader];
	
	return self.httpRequest;
}

- (void) restart {
	NSLog(@"restarting download from: %@", self.url);
	
	NSMutableData *d = [[NSMutableData alloc] init];
	self.data = d;
	[d release];
	
	[self start];
}

- (void)cancel {
	[self.httpRequest clearDelegatesAndCancel];
	[self hideHUD];
	stopSpinner();
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)createAndShowHUD
{
	if (!self.showHUD || HUD) {
		return;
	}
	
	[self setHUD:[[[MBProgressHUD alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease]];
	[HUD setGraceTime:0.0f];
	[HUD setMode:MBProgressHUDModeIndeterminate];
	[HUD setTaskInProgress:YES];
	[[(AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate] window] addSubview:HUD];
	[HUD show:YES];
}

- (void)hideHUD
{
	if (HUD) {
		[HUD setTaskInProgress:NO];
		[HUD hide:YES];
		[HUD removeFromSuperview];
		[self setHUD:nil];
	}
}

- (void) cancelActiveConnection:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in AsynchonousDownload");
    [self cancel];
    self.data = nil;
}

@end
