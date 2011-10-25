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
//  DownloadProgressBar.m
//
// this code id based on: http://pessoal.org/blog/2009/02/09/iphone-sdk-formatting-a-numeric-value-with-nsnumberformatter/
//

#import "DownloadProgressBar.h"
#import "Utility.h"
#import "SavedDocument.h"
#import "NSData+Base64.h"

#define kDownloadCounterTag 1



@implementation DownloadProgressBar

@synthesize fileData;
@synthesize totalFileSize;
@synthesize progressView;
@synthesize progressAlert;
@synthesize delegate;
@synthesize filename;
@synthesize cmisObjectId;
@synthesize cmisContentStreamMimeType;

- (void) dealloc {
	[fileData release];
	[progressView release];
	[progressAlert release];
	[filename release];
    [cmisObjectId release];
    [cmisContentStreamMimeType release];
    
	[super dealloc];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSMutableData *data = [[NSMutableData alloc] init];
    self.fileData = data;
	[data release];
	if (nil == self.totalFileSize || [self.totalFileSize isEqualToNumber:[NSNumber numberWithInt:0]]) {
		NSNumber *size = [NSNumber numberWithLongLong:[response expectedContentLength]];
		self.totalFileSize = size;
	}
	
	// check if the response is base64 encoded
	isBase64Encoded = NO;
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
		NSDictionary *dictionary = [httpResponse allHeaderFields];
		NSString *contentTransferEncoding = [dictionary objectForKey:@"Content-Transfer-Encoding"];	
		isBase64Encoded = ((contentTransferEncoding != nil) && [contentTransferEncoding caseInsensitiveCompare:@"base64"] == NSOrderedSame);
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.fileData appendData:data];
	
    NSNumber *resourceLength = [NSNumber numberWithUnsignedInteger:[self.fileData length]];
    NSNumber *progress = [NSNumber numberWithFloat:([resourceLength floatValue] / [self.totalFileSize floatValue])];
    progressView.progress = [progress floatValue];
	
    UILabel *label = (UILabel *)[progressAlert viewWithTag:kDownloadCounterTag];
	/*
	const unsigned int bytes = 1024 * 1024;
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setPositiveFormat:@"##0.00"];
    NSNumber *partial = [NSNumber numberWithFloat:([resourceLength floatValue] / bytes)];
    NSNumber *total = [NSNumber numberWithFloat:([self.totalFileSize floatValue] / bytes)];
    label.text = [NSString stringWithFormat:@"%@ MB of %@ MB", [formatter stringFromNumber:partial], [formatter stringFromNumber:total]];
    [formatter release];
	*/
	label.text = [NSString stringWithFormat:@"%@ %@ %@", 
				  [SavedDocument stringForLongFileSize:[resourceLength longValue]],
                  NSLocalizedString(@"of", @"'of' usage: 1 of 3, 2 of 3, 3 of 3"),
				  [SavedDocument stringForLongFileSize:[self.totalFileSize longValue]]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (isBase64Encoded) {
		NSString *base64String = [[NSString alloc]initWithData:fileData encoding:NSUTF8StringEncoding];
		NSData *decodedData = [NSData dataFromBase64String:base64String];
		[self setFileData:[NSMutableData dataWithData:decodedData]];
        
		[base64String release];
	}
	
	
	if (self.delegate) {
		[delegate download: self completeWithData:self.fileData];
	}
	[progressAlert dismissWithClickedButtonIndex:0 animated:NO];
}

+ (DownloadProgressBar *) createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)fname {
	return [self createAndStartWithURL:url delegate:del message:msg filename:fname contentLength:nil];
}

+ (DownloadProgressBar *) createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)fname contentLength:(NSNumber *)contentLength {	
	DownloadProgressBar *bar = [[[DownloadProgressBar alloc] init] autorelease];

	// if we know the size ahead of time then set it now
	if (nil != contentLength && ![contentLength isEqualToNumber:[NSNumber numberWithInt:0]]) {
		bar.totalFileSize = contentLength;
	}	
	
	// create a modal alert
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:NSLocalizedString(@"pleaseWaitMessage", @"Please Wait...") 
                                                   delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    bar.progressAlert = alert;
	[alert release];
	
	// create a progress bar and put it in the alert
	UIProgressView *progress = [[UIProgressView alloc] initWithFrame:CGRectMake(30.0f, 80.0f, 225.0f, 90.0f)];
    bar.progressView = progress;
    [progress setProgressViewStyle:UIProgressViewStyleBar];
	[progress release];
	[bar.progressAlert addSubview:bar.progressView];
	
	// create a label, and add that to the alert, too
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(90.0f, 90.0f, 225.0f, 40.0f)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:12.0f];
    label.text = @"";
    label.tag = kDownloadCounterTag;
    [bar.progressAlert addSubview:label];
    [label release];

	// show the dialog
	[bar.progressAlert show];
	
	// who should we notify when the download is complete?
	bar.delegate = del;

	// save the filename
	bar.filename = fname;
	
	// start the download
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	[NSURLConnection connectionWithRequest:requestObj delegate:bar];

	return bar;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	NSString *user = userPrefUsername();
	NSString *pass = userPrefPassword();
	NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:user password:pass persistence:NSURLCredentialPersistenceNone];
	[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
	[credential release];
}

@end
