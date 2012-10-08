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
//  DowloadQueueProgressBar.m
//

#import "DownloadQueueProgressBar.h"
#import "ASINetworkQueue.h"
#import "RepositoryItem.h"
#import "DownloadInfo.h"
#import "FileUtils.h"
#import "BaseHTTPRequest.h"
#import "FileProtectionManager.h"
#import "AccountManager.h"

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
@synthesize selectedUUID = _selectedUUID;
@synthesize tenantID = _tenantID;

- (void) dealloc {
    [_requestQueue release];
    [_nodesToDowload release];
    [_progressAlert release];
    [_progressTitle release];
    [_progressView release];
    [_downloadedInfo release];
    [_selectedUUID release];
    [_tenantID release];
    [super dealloc];
}

- (id)initWithNodes:(NSArray *)nodesToDownload delegate:(id<DownloadQueueDelegate>)del  andMessage: (NSString *) message {
    self = [super init];
    if (self) {
        self.nodesToDownload = nodesToDownload;
        self.delegate = del;
        self.progressTitle = message;
        _downloadedInfo = [[NSMutableArray array] retain];
        [self loadDownloadView];
    }
    
    return self;
}

#pragma mark - private methods
- (void) loadDownloadView {
    // create a modal alert
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.progressTitle
                                                    message:NSLocalizedString(@"pleaseWaitMessage", @"Please Wait...")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"cancelButton", @"Cancel")
                                          otherButtonTitles:nil];
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
    if([self.requestQueue requestsCount] == 1)
    {
        label.text = [NSString stringWithFormat:NSLocalizedString(@"downloadprogress.file-left", @"1 Documents left"), 
                      [self.requestQueue requestsCount]];
    }
    else 
    {
        label.text = [NSString stringWithFormat:NSLocalizedString(@"downloadprogress.files-left", @"x Documents left"), 
                      [self.requestQueue requestsCount]];
    }
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
        NSString *tempPath = [FileUtils pathToTempFile:item.title];
        
        BaseHTTPRequest *request = [BaseHTTPRequest requestWithURL:url accountUUID:self.selectedUUID];
        [request setTenantID:self.tenantID];
        [request setTag:index];
        [request setDownloadDestinationPath:tempPath];
        [request setShouldContinueWhenAppEntersBackground:YES];
        
        DownloadInfo *info = [[[DownloadInfo alloc] initWithRepositoryItem:[self.nodesToDownload objectAtIndex:index]] autorelease];
        info.tempFilePath = tempPath;
        info.selectedAccountUUID = self.selectedUUID;
        info.tenantID = self.tenantID;
        [_downloadedInfo addObject:info];
        
        [self.requestQueue addOperation:request];
    }
    
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedUUID];
    NSString *passwordForAccount = [BaseHTTPRequest passwordForAccount:account];
    if(passwordForAccount)
    {
        [self.progressAlert show];
    }
    [self.requestQueue go];
    [self updateProgressView];
}

- (void) cancel {
    [_progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (NSArray *) downloadedInfo {
    return [NSArray arrayWithArray:_downloadedInfo];
}

#pragma mark -
#pragma mark ASINetworkQueue Delegate methods

- (void) requestFinished:(ASIHTTPRequest *)request {
    DownloadInfo *info = [_downloadedInfo objectAtIndex:request.tag];
    [info setDownloadStatus:DownloadInfoStatusDownloaded];
    [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:request.downloadDestinationPath];
    
    [self updateProgressView];
}

- (void) requestFailed:(ASIHTTPRequest *)request {
    DownloadInfo *info = [_downloadedInfo objectAtIndex:request.tag];
    [info setDownloadStatus:DownloadInfoStatusFailed];
    [info setError:request.error];
    
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

- (void)finishedPromptPassword:(ASIHTTPRequest *) request
{
    [self.progressAlert show];
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



@end
