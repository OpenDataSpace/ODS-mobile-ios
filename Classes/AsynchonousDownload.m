//
//  AsynchonousDownload.m
//  Alfresco
//
//  Created by Michael Muller on 10/16/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import "AsynchonousDownload.h"
#import "Utility.h"
#import "AlfrescoAppDelegate.h"

NSString * const NSHTTPPropertyStatusCodeKey = @"NSHTTPPropertyStatusCodeKey";

@implementation AsynchonousDownload

@synthesize data;
@synthesize url;
@synthesize delegate;
@synthesize urlConnection;
@synthesize show500StatusError;
@synthesize responseStatusCode;
@synthesize HUD;

- (void) dealloc {
	[data release];
	[url release];
	[urlConnection release];
	[super dealloc];
}

- (id)initWithURL:(NSURL *)u delegate:(id <AsynchronousDownloadDelegate>)del {
	
	NSLog(@"initializing asynchronous download from: %@", u);
    self = [super init];
	if (self) {
		NSMutableData *d = [[NSMutableData alloc] init];
		[self setData:d];
		[d release];
		
		[self setUrl:[u copy]];
		[self setDelegate:del];
        
        show500StatusError = YES;
	}
	return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	if ([response respondsToSelector:@selector(statusCode)])
	{
		int statusCode = [((NSHTTPURLResponse *)response) statusCode];
		if (statusCode >= 400)
		{
			[connection cancel];  // stop connecting; no more delegate messages
			NSString *msg = [[NSString alloc] initWithFormat: @"%d %@", statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]];
			NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey];
			NSError *statusError = [NSError errorWithDomain:NSHTTPPropertyStatusCodeKey code:statusCode userInfo:errorInfo];
			[self connection:connection didFailWithError:statusError];
			[msg release];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)chunk {
    [self.data appendData:chunk];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	// stop the "network activity" spinner 
	stopSpinner();
	[self hideHUD];
		
	// if it's an auth failure
	if ([[error domain] isEqualToString:NSURLErrorDomain] && [error code] == -1012) {
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
        if (! ([[error domain] isEqualToString:NSHTTPPropertyStatusCodeKey] && ([error code] == 500)) 
            || show500StatusError) 
        {
            NSString *msg = [[NSString alloc] initWithFormat:@"%@ %@\n\n%@", 
                             NSLocalizedString(@"connectionErrorMessage", @"The server returned an error connecting to URL. Localized Error Message"), 
                             [self.url absoluteURL], [error localizedDescription]];
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
		[delegate asyncDownload:self didFailWithError:error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	// log the response
	NSString *responseAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"async result: %@", responseAsString);
	[responseAsString release];
	
	// stop the "network activity" spinner 
	stopSpinner();
	
	if (self.delegate) {
		[delegate asyncDownloadDidComplete:self];
	}
	
	[self hideHUD];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([challenge previousFailureCount] > 0) {
		[challenge.sender cancelAuthenticationChallenge:challenge];
	}
	else {
		NSString *user = userPrefUsername();
		NSString *pass = userPrefPassword();
		NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:user password:pass persistence:NSURLCredentialPersistenceNone];
		[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
		[credential release];
	}
}

- (void) start {
	[self createAndShowHUD];
	
	// start downloading
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	self.urlConnection = [NSURLConnection connectionWithRequest:requestObj delegate:self];
	[self.urlConnection start];
	
	// start the "network activity" spinner 
	startSpinner();
}

- (void) restart {
	NSLog(@"restarting download from: %@", self.url);
	
	NSMutableData *d = [[NSMutableData alloc] init];
	self.data = d;
	[d release];
	
	[self start];
}

- (void)cancel {
	[self.urlConnection cancel];
	[self hideHUD];
	stopSpinner();
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)createAndShowHUD
{
	if (HUD) {
		return;
	}
	
	[self setHUD:[[MBProgressHUD alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
	[HUD setGraceTime:0.5f];
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

@end
