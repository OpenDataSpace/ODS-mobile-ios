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
//  DownloadProgressBar.m
//
// this code id based on: http://pessoal.org/blog/2009/02/09/iphone-sdk-formatting-a-numeric-value-with-nsnumberformatter/

#import "DownloadProgressBar.h"
#import "Utility.h"
#import "SavedDocument.h"
#import "NSData+Base64.h"
#import "RepositoryServices.h"
#import "DownloadInfo.h"

#define kDownloadCounterTag 5

@implementation DownloadProgressBar

@synthesize fileData;
@synthesize totalFileSize;
@synthesize progressView;
@synthesize progressAlert;
@synthesize delegate;
@synthesize filename;
@synthesize cmisObjectId;
@synthesize cmisContentStreamMimeType;
@synthesize versionSeriesId;
@synthesize httpRequest;
@synthesize repositoryItem;
@synthesize tag;

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[fileData release];
	[progressView release];
	[progressAlert release];
	[filename release];
    [cmisObjectId release];
    [cmisContentStreamMimeType release];
    [versionSeriesId release];
    [repositoryItem release];
    [httpRequest release];
    
	[super dealloc];
}

- (DownloadMetadata *) downloadMetadata {
    DownloadInfo *downloadInfo = [[DownloadInfo alloc] initWithNodeItem:repositoryItem];
    DownloadMetadata *metadata = [downloadInfo downloadMetadata];
    [downloadInfo release];
    return metadata;
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate
-(void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders {
    // check if the response is base64 encoded
    NSString *contentTransferEncoding = [responseHeaders objectForKey:@"Content-Transfer-Encoding"];	
    isBase64Encoded = ((contentTransferEncoding != nil) && [contentTransferEncoding caseInsensitiveCompare:@"base64"] == NSOrderedSame);
}

-(void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"failed to download file: %@", [request.error description]);
    [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:request waitUntilDone:NO];
}

-(void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"download file request finished using cache: %@", [request didUseCachedResponse]? @"YES":@"NO");
    if (isBase64Encoded) {
		NSString *base64String = [[NSString alloc]initWithData:request.responseData encoding:NSUTF8StringEncoding];
		NSData *decodedData = [NSData dataFromBase64String:base64String];
		[self setFileData:[NSMutableData dataWithData:decodedData]];
        
		[base64String release];
	} else {
        self.fileData = [NSMutableData dataWithData:request.responseData];
    }
	
	[progressAlert dismissWithClickedButtonIndex:1 animated:NO];
	if (self.delegate) {
		[delegate download: self completeWithData:self.fileData];
	}
    
    self.fileData = nil;
    self.httpRequest = nil;
}

- (void) downloadFailed:(ASIHTTPRequest *) request {
    [progressAlert dismissWithClickedButtonIndex:1 animated:YES];
}

#pragma mark -
#pragma mark ASIProgressDelegate

- (void)setProgress:(float)newProgress {
    [self.progressView setProgress:newProgress];
}

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    long contentLenght = (long) [[request.responseHeaders objectForKey:@"Content-Length"] doubleValue];
    long bytesSent = contentLenght *self.progressView.progress;
    
    UILabel *label = (UILabel *)[self.progressAlert viewWithTag:kDownloadCounterTag];
    label.text = [NSString stringWithFormat:@"%@ %@ %@", 
                  [SavedDocument stringForLongFileSize:bytesSent],
                  NSLocalizedString(@"of", @"'of' usage: 1 of 3, 2 of 3, 3 of 3"),
                  [SavedDocument stringForLongFileSize:contentLenght]];
}

+ (DownloadProgressBar *) createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)fname {
	return [self createAndStartWithURL:url delegate:del message:msg filename:fname contentLength:nil];
}

+ (DownloadProgressBar *) createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)fname contentLength:(NSNumber *)contentLength {	
	return [self createAndStartWithURL:url delegate:del message:msg filename:fname contentLength:contentLength shouldForceDownload:NO];
}

+ (DownloadProgressBar *)createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)fname contentLength:(NSNumber *)contentLength shouldForceDownload:(BOOL)shouldForceDownload {
    DownloadProgressBar *bar = [[[DownloadProgressBar alloc] init] autorelease];
    
	// if we know the size ahead of time then set it now
	if (nil != contentLength && ![contentLength isEqualToNumber:[NSNumber numberWithInt:0]]) {
		bar.totalFileSize = contentLength;
	}	
	
	// create a modal alert
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:NSLocalizedString(@"pleaseWaitMessage", @"Please Wait...") 
                                                   delegate:bar cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    alert.message = [NSString stringWithFormat: @"%@%@", alert.message, @"\n\n\n\n"];
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
    
    //UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(90.0f, 90.0f, 225.0f, 40.0f)];
    
	// show the dialog
	[bar.progressAlert show];
	
	// who should we notify when the download is complete?
	bar.delegate = del;
    
	// save the filename
	bar.filename = fname;
	
	// start the download
    bar.httpRequest = [[[ASIHTTPRequest alloc] initWithURL:url] autorelease];
    bar.httpRequest.delegate = bar;
    bar.httpRequest.showAccurateProgress = YES;
    bar.httpRequest.downloadProgressDelegate = bar;
    [bar.httpRequest addBasicAuthHeader];
    if(shouldForceDownload) {
        [bar.httpRequest setCachePolicy:ASIAskServerIfModifiedCachePolicy];
    }
    
    [bar.httpRequest startAsynchronous];
    
    [[NSNotificationCenter defaultCenter] addObserver:bar selector:@selector(cancelActiveConnection:) name:UIApplicationWillResignActiveNotification object:nil];
    
	return bar;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	NSString *user = userPrefUsername();
	NSString *pass = userPrefPassword();
	NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:user password:pass persistence:NSURLCredentialPersistenceNone];
	[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
	[credential release];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    // we only cancel the connection when buttonIndex=0 (cancel)
    if(buttonIndex == 0) {
        [self.httpRequest clearDelegatesAndCancel];
    
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadWasCancelled:)]) {
            [delegate downloadWasCancelled:self];
        }
        
        self.fileData = nil;
    }
}

- (void) cancelActiveConnection:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in DownloadProgressBar");
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void) cancel {
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

@end
