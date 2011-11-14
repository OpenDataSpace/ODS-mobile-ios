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
//  DowloadQueueProgressBar.m
//

#import "DownloadQueueProgressBar.h"
#import "ASINetworkQueue.h"
#import "RepositoryItem.h"
#import "ASIHTTPRequest+Utils.h"
#import "DownloadInfo.h"
#import "SavedDocument.h"

NSInteger const kDownloadCounterTag =  5;

@interface DownloadQueueProgressBar (private)
- (void) loadDownloadView;
- (void) updateProgressView;
@end

@implementation DownloadQueueProgressBar
@synthesize requestQueue = _requestQueue;
@synthesize nodesToDownload = _nodesToDowload;
@synthesize delegate = _delegate;
@synthesize progressAlert = _progressAlert;
@synthesize progressTitle = _progressTitle;
@synthesize progressView = _progressView;

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_requestQueue release];
    [_nodesToDowload release];
    [_progressAlert release];
    [_progressTitle release];
    [_progressView release];
    [_downloadedInfo release];
    [super dealloc];
}

- (id)initWithNodes:(NSArray *)nodesToDownload delegate:(id<DownloadQueueDelegate>)del  andMessage: (NSString *) message {
    self = [super init];
    if (self) {
        self.nodesToDownload = nodesToDownload;
        self.delegate = del;
        self.progressTitle = message;
        _downloadedInfo = [[NSMutableArray array] retain];;
        [self loadDownloadView];
    }
    
    return self;
}

#pragma mark - private methods
- (void) loadDownloadView {
    // create a modal alert
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.progressTitle message:NSLocalizedString(@"pleaseWaitMessage", @"Please Wait...") 
                                                   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    alert.message = [NSString stringWithFormat: @"%@%@", alert.message, @"\n\n\n\n"];
    self.progressAlert = alert;
    
	[alert release];
	
	// create a progress bar and put it in the alert
	UIProgressView *progress = [[UIProgressView alloc] initWithFrame:CGRectMake(30.0f, 80.0f, 225.0f, 90.0f)];
    self.progressView = progress;
    [progress setProgressViewStyle:UIProgressViewStyleBar];
	[progress release];
	[self.progressAlert addSubview:self.progressView];
	
	// create a label, and add that to the alert, too
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, 90.0f, 225.0f, 40.0f)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:13.0f];
    label.text = @"x files left";
    label.tag = kDownloadCounterTag;
    [self.progressAlert addSubview:label];
    [label release];
}

- (void) updateProgressView {
    UILabel *label = (UILabel *)[self.progressAlert viewWithTag:kDownloadCounterTag];
    NSString *plural = [self.requestQueue requestsCount] == 1 ?@"":@"s";
    label.text = [NSString stringWithFormat:NSLocalizedString(@"downloadprogress.files-left", @"x Documents left"), 
                  [self.requestQueue requestsCount], plural];
}

#pragma mark - public methods
- (void) startDownloads {
    [self.requestQueue cancelAllOperations];
    self.requestQueue = [ASINetworkQueue queue];
    [self.requestQueue setDelegate:self];
    [self.requestQueue setRequestDidFinishSelector:@selector(requestFinished:)];
    [self.requestQueue setRequestDidFailSelector:@selector(requestFailed:)];
    [self.requestQueue setQueueDidFinishSelector:@selector(queueFinished:)];
    [self.requestQueue setRequestDidReceiveResponseHeadersSelector:@selector(responseReceived:withHeaders:)];
    [self.requestQueue setShowAccurateProgress:YES];
    [self.requestQueue setShouldCancelAllRequestsOnFailure:NO];
    [self.requestQueue setDownloadProgressDelegate:self.progressView];
    
    for(NSInteger index = 0; index < [self.nodesToDownload count]; index++) {
        RepositoryItem *item = [self.nodesToDownload objectAtIndex:index];
        NSURL *url = [NSURL URLWithString:item.contentLocation];
        NSString *tempPath = [SavedDocument pathToTempFile:item.title];
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        request.tag = index;
        request.downloadDestinationPath = tempPath;
        [request addBasicAuthHeader];
        
        DownloadInfo *info = [[[DownloadInfo alloc] initWithNodeItem:[self.nodesToDownload objectAtIndex:index]] autorelease];
        info.tempFilePath = tempPath;
        [_downloadedInfo addObject:info];
        
        [self.requestQueue addOperation:request];
    }
    
    [self.progressAlert show];
    [self.requestQueue go];
    [self updateProgressView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelActiveConnection:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void) cancel {
    [_progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (NSArray *) downloadedInfo {
    return [NSArray arrayWithArray:_downloadedInfo];
}

#pragma mark -
#pragma mark ASINetworkQueue Delegate methods

- (void) responseReceived:(ASIHTTPRequest *)request withHeaders:(NSDictionary *)responseHeaders  {
    DownloadInfo *info = [_downloadedInfo objectAtIndex:request.tag];
    NSString *contentTransferEncoding = [responseHeaders objectForKey:@"Content-Transfer-Encoding"];	
    info.isBase64Encoded = ((contentTransferEncoding != nil) && [contentTransferEncoding caseInsensitiveCompare:@"base64"] == NSOrderedSame);
}

- (void) requestFinished:(ASIHTTPRequest *)request {
    DownloadInfo *info = [_downloadedInfo objectAtIndex:request.tag];
    info.isCompleted = YES;
    
    [self updateProgressView];
}

- (void) requestFailed:(ASIHTTPRequest *)request {
    DownloadInfo *info = [_downloadedInfo objectAtIndex:request.tag];
    info.isCompleted = NO;
    
    [self updateProgressView];
}

- (void) queueFinished:(ASINetworkQueue *)queue {
    if([self.requestQueue requestsCount] == 0) {
        [_progressAlert dismissWithClickedButtonIndex:1 animated:NO];
        self.requestQueue = nil;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadQueue:completeDownloads:)]) {
            [self.delegate downloadQueue:self completeDownloads:self.downloadedInfo];
        }
        
    }
}

#pragma mark - static methods
+ (DownloadQueueProgressBar *) createWithNodes:(NSArray *)nodesToDownload delegate:(id<DownloadQueueDelegate>)del  andMessage: (NSString *) message{
    DownloadQueueProgressBar *bar = [[[DownloadQueueProgressBar alloc] initWithNodes:nodesToDownload delegate:del andMessage:message] autorelease];
	return bar;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    // we only cancel the connection when buttonIndex=0 (cancel)
    if(buttonIndex == 0) {
        [_requestQueue cancelAllOperations];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadQueueWasCancelled:)]) {
            [self.delegate downloadQueueWasCancelled:self];
        }
        
        self.requestQueue = nil;
    }
}

- (void) cancelActiveConnection:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in DowloadQueueProgressBar");
    [_progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}



@end
