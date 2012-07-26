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
//  DownloadProgressBar.m
//
// this code id based on: http://pessoal.org/blog/2009/02/09/iphone-sdk-formatting-a-numeric-value-with-nsnumberformatter/

#import "DownloadProgressBar.h"
#import "Utility.h"
#import "FileUtils.h"
#import "NSData+Base64.h"
#import "RepositoryServices.h"
#import "DownloadInfo.h"
#import "BaseHTTPRequest.h"
#import "Constants.h"
#import "FileProtectionManager.h"
#import "AccountManager.h"
#import "AccountInfo.h"

#define kDownloadCounterTag 5

@interface DownloadProgressBar ()
- (void)handleGraceTimer;

@property (retain) NSTimer *graceTimer;
@end

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
@synthesize selectedAccountUUID;
@synthesize graceTimer;
@synthesize tenantID;

- (void) dealloc 
{   
    [httpRequest clearDelegatesAndCancel];
    
	[fileData release];
	[progressView release];
	[progressAlert release];
	[filename release];
    [cmisObjectId release];
    [cmisContentStreamMimeType release];
    [versionSeriesId release];
    [httpRequest release];
    [repositoryItem release];
    [selectedAccountUUID release];
    [graceTimer release];
    [tenantID release];
    
	[super dealloc];
}

- (DownloadMetadata *) downloadMetadata 
{
    DownloadInfo *downloadInfo = [[DownloadInfo alloc] initWithRepositoryItem:repositoryItem];
    [downloadInfo setSelectedAccountUUID:selectedAccountUUID];
    [downloadInfo setTenantID:tenantID];
    DownloadMetadata *metadata = [downloadInfo downloadMetadata];
    [downloadInfo release];
    
    return metadata;
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate
-(void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"failed to download file: %@", [request.error description]);
    [self performSelectorOnMainThread:@selector(downloadFailed:) withObject:request waitUntilDone:NO];
}

-(void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"download file request finished using cache: %@", [request didUseCachedResponse]? @"YES":@"NO");
	
    [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:request.downloadDestinationPath];
    [progressAlert dismissWithClickedButtonIndex:1 animated:NO];
    [graceTimer invalidate];
    if ([delegate respondsToSelector:@selector(download:completeWithPath:)])
    {
        [delegate download: self completeWithPath:self.httpRequest.downloadDestinationPath];
    }
    
    self.fileData = nil;
    self.httpRequest = nil;
}

- (void)downloadFailed:(ASIHTTPRequest *)request
{
    [progressAlert dismissWithClickedButtonIndex:1 animated:YES];
    [graceTimer invalidate];
    
    if ([delegate respondsToSelector:@selector(downloadFailed:)])
    {
        [delegate downloadFailed:self];
    }
}

#pragma mark - PromptPassword delegate methods

- (void)willPromptPassword:(BaseHTTPRequest *)request
{
    isShowingPromptPasswordDialog = YES;
    [self.progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)finishedPromptPassword:(ASIHTTPRequest *)request
{
    isShowingPromptPasswordDialog = NO;
    [self.progressAlert show];
}

- (void)cancelledPromptPassword:(ASIHTTPRequest *)request
{
    isShowingPromptPasswordDialog = NO;
    [self alertView:self.progressAlert willDismissWithButtonIndex:self.progressAlert.cancelButtonIndex];
}

#pragma mark - ASIProgressDelegate

- (void)setProgress:(float)newProgress
{
    [self.progressView setProgress:newProgress];
}

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes
{
    long contentLength = (long) [[request.responseHeaders objectForKey:@"Content-Length"] doubleValue];
    long bytesSent = contentLength *self.progressView.progress;
    
    UILabel *label = (UILabel *)[self.progressAlert viewWithTag:kDownloadCounterTag];
    label.text = [NSString stringWithFormat:@"%@ %@ %@", 
                  [FileUtils stringForLongFileSize:bytesSent],
                  NSLocalizedString(@"of", @"'of' usage: 1 of 3, 2 of 3, 3 of 3"),
                  [FileUtils stringForLongFileSize:contentLength]];
}

+ (DownloadProgressBar *) createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)fname accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantId
{
	return [self createAndStartWithURL:url delegate:del message:msg filename:fname contentLength:nil accountUUID:uuid tenantID:aTenantId];
}

+ (DownloadProgressBar *) createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)fname contentLength:(NSNumber *)contentLength accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantId
{
	return [self createAndStartWithURL:url delegate:del message:msg filename:fname contentLength:contentLength shouldForceDownload:NO accountUUID:uuid tenantID:aTenantId];
}

+ (DownloadProgressBar *)createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)fname contentLength:(NSNumber *)contentLength shouldForceDownload:(BOOL)shouldForceDownload accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantId
{
    DownloadProgressBar *bar = [[[DownloadProgressBar alloc] init] autorelease];
    [bar setSelectedAccountUUID:uuid];
    [bar setTenantID:aTenantId];
    
	// if we know the size ahead of time then set it now
	if (nil != contentLength && ![contentLength isEqualToNumber:[NSNumber numberWithInt:0]]) {
		bar.totalFileSize = contentLength;
	}	
	
	// create a modal alert
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:NSLocalizedString(@"pleaseWaitMessage", @"Please Wait...") 
                                                   delegate:bar cancelButtonTitle:NSLocalizedString(@"cancelButton", @"Cancel") otherButtonTitles:nil];
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
    
	// who should we notify when the download is complete?
	bar.delegate = del;
    
	// save the filename
	bar.filename = fname;
	
	// start the download
    NSString *tempPath = [FileUtils pathToTempFile:fname];
    
    [bar setHttpRequest:[[[BaseHTTPRequest alloc] initWithURL:url accountUUID:uuid ] autorelease]];
    [bar.httpRequest setDelegate:bar];
    [bar.httpRequest setShowAccurateProgress:YES];
    [bar.httpRequest setDownloadProgressDelegate:bar];
    [bar.httpRequest setDownloadDestinationPath:tempPath];
    [bar.httpRequest setPromptPasswordDelegate:bar];
    [bar.httpRequest setWillPromptPasswordSelector:@selector(willPromptPassword:)];
    [bar.httpRequest setFinishedPromptPasswordSelector:@selector(finishedPromptPassword:)];
    [bar.httpRequest setCancelledPromptPasswordSelector:@selector(cancelledPromptPassword:)];
    if(shouldForceDownload)
    {
        [bar.httpRequest setCachePolicy:ASIAskServerIfModifiedCachePolicy];
    }
    [bar setTenantID:aTenantId];
    [bar.httpRequest startAsynchronous];
    
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:uuid];
    NSString *passwordForAccount = [BaseHTTPRequest passwordForAccount:account];
    if(passwordForAccount)
    {
        // If the grace time is set postpone the dialog
        if (kNetworkProgressDialogGraceTime > 0.0)
        {
            if ([bar.graceTimer isValid])
            {
                [bar.graceTimer invalidate];
            }
            bar.graceTimer = [NSTimer scheduledTimerWithTimeInterval:kNetworkProgressDialogGraceTime
                                                              target:bar
                                                            selector:@selector(handleGraceTimer)
                                                            userInfo:nil
                                                             repeats:NO];
        }
        // ... otherwise show the dialog immediately if the account has a password
        else
        {
            [bar.progressAlert show];
        }
    }
    
	return bar;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (!isShowingPromptPasswordDialog && buttonIndex == alertView.cancelButtonIndex)
    {
        [self.httpRequest clearDelegatesAndCancel];
    
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadWasCancelled:)])
        {
            [delegate downloadWasCancelled:self];
        }
        
        self.fileData = nil;
    }
}

- (void) cancelActiveConnection:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in DownloadProgressBar");
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [graceTimer invalidate];
}

- (void) cancel {
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [graceTimer invalidate];
}

#pragma mark -
#pragma mark NSTimer handler
- (void)handleGraceTimer
{
    [graceTimer invalidate];
    if (!isShowingPromptPasswordDialog)
    {
        [self.progressAlert show];
    }
}

@end
