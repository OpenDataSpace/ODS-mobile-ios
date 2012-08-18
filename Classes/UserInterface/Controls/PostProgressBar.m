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
//  PostProgressBar.m
//
// this code id based on: http://pessoal.org/blog/2009/02/09/iphone-sdk-formatting-a-numeric-value-with-nsnumberformatter/

#import "PostProgressBar.h"
#import "Utility.h"
#import "FileUtils.h"
#import "CMISMediaTypes.h"
#import "BaseHTTPRequest.h"
#import "RepositoryItemParser.h"
#import "RepositoryItem.h"

#define kPostCounterTag 5

@interface PostProgressBar ()
- (void)handleGraceTimer;

@property (retain) NSTimer *graceTimer;
@end

@implementation PostProgressBar

@synthesize fileData;
@synthesize progressAlert;
@synthesize delegate;
@synthesize cmisObjectId;
@synthesize progressView;
@synthesize currentRequest;
@synthesize graceTimer;
@synthesize suppressErrors;
@synthesize repositoryItem;

- (void) dealloc 
{
    [currentRequest clearDelegatesAndCancel];
    
	[fileData release];
	[progressAlert release];
    [cmisObjectId release];
    [progressView release];
    [currentRequest release];
    [graceTimer release];
    [repositoryItem release];
    
	[super dealloc];
}

- (id)initWithRequest:(BaseHTTPRequest *)request message:(NSString *)msg graceTime:(CGFloat)graceTime
{
    self = [super init];
    
    if (self)
    {
        [request setDelegate:self];
        [request setUploadProgressDelegate:self];
        [request setPromptPasswordDelegate:self];
        [request setWillPromptPasswordSelector:@selector(willPromptPassword:)];
        [request setFinishedPromptPasswordSelector:@selector(finishedPromptPassword:)];
        [request setCancelledPromptPasswordSelector:@selector(cancelledPromptPassword:)];
        
        self.suppressErrors = [request suppressAllErrors];
        
        // create a modal alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg
                                                        message:NSLocalizedString(@"Please wait...", @"Please wait...")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button text")
                                              otherButtonTitles:nil];
        self.progressAlert = alert;
        
        UIProgressView *progress = [[UIProgressView alloc] initWithFrame:CGRectMake(30.0f, 80.0f, 225.0f, 90.0f)];
        self.progressView = progress;
        [progress setProgressViewStyle:UIProgressViewStyleBar];
        [progress release];
        [self.progressAlert addSubview:self.progressView];
        
        alert.message = [NSString stringWithFormat: @"%@%@", alert.message, @"\n\n\n\n"];
        [alert release];
		
        // create a label, and add that to the alert, too
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(90.0f, 90.0f, 225.0f, 20.0f)];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12.0f];
        label.text = [NSString stringWithFormat:@"%@ %@",
                      NSLocalizedString(@"Sending", @"Sending 1000 kb"),
                      [FileUtils stringForLongFileSize:request.contentLength]];
        label.tag = kPostCounterTag;
        [self.progressAlert addSubview:label];
        [label release];
        
        // If the grace time is set postpone the dialog
        if (graceTime > 0.0)
        {
            self.graceTimer = [NSTimer scheduledTimerWithTimeInterval:graceTime
                                                               target:self
                                                             selector:@selector(handleGraceTimer)
                                                             userInfo:nil
                                                              repeats:NO];
        }
        // ... otherwise show the dialog immediately
        else
        {
            [self.progressAlert show];
        }
    }
    
    return self;
}

- (id)initWithRequest:(BaseHTTPRequest *)request message:(NSString *)msg
{
    return [self initWithRequest:request message:msg graceTime:kNetworkProgressDialogGraceTime];
}

- (void)displayFailureMessage
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(displayFailureMessage) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"postprogressbar.error.uploadfailed.title", @"Upload Failed") 
                                 message:NSLocalizedString(@"postprogressbar.error.uploadfailed.message", @"The upload failed, please try again")
                                delegate:nil 
                       cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"Okay") 
                       otherButtonTitles:nil, nil] autorelease] show];
}

+ (PostProgressBar *)createAndStartWithURL:(NSURL*)url andPostBody:(NSString *)body delegate:(id <PostProgressBarDelegate>)del message:(NSString *)msg accountUUID:(NSString *)uuid
{
    return [PostProgressBar createAndStartWithURL:url andPostBody:body delegate:del message:msg accountUUID:uuid requestMethod:@"POST" suppressErrors:NO];
}
    
+ (PostProgressBar *)createAndStartWithURL:(NSURL*)url andPostBody:(NSString *)body delegate:(id <PostProgressBarDelegate>)del message:(NSString *)msg accountUUID:(NSString *)uuid requestMethod:(NSString *)requestMethod suppressErrors:(BOOL)suppressErrors
{
    // determine HTTP method to use, default to POST
    if (requestMethod == nil)
    {
        requestMethod = @"POST";
    }
	
    BaseHTTPRequest *request = [BaseHTTPRequest requestWithURL:url accountUUID:uuid];
    [request setRequestMethod:requestMethod];
    [request addRequestHeader:@"Content-Type" value:kAtomEntryMediaType];
    [request setPostBody:[NSMutableData dataWithData:[body dataUsingEncoding:NSUTF8StringEncoding]]];
    [request setContentLength:[body length]];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setSuppressAllErrors:suppressErrors];
    [request startAsynchronous];
	
    PostProgressBar *bar = [[[PostProgressBar alloc] initWithRequest:request message:msg] autorelease];
	// who should we notify when the download is complete?
    [bar setDelegate:del];
    return bar;
}

+ (PostProgressBar *)createAndStartWithURL:(NSURL*)url andPostFile:(NSString *)filePath delegate:(id <PostProgressBarDelegate>)del message:(NSString *)msg accountUUID:(NSString *)uuid
{
    return [PostProgressBar createAndStartWithURL:url andPostFile:filePath delegate:del message:msg accountUUID:uuid requestMethod:@"POST" suppressErrors:NO];
}

+ (PostProgressBar *)createAndStartWithURL:(NSURL *)url andPostFile:(NSString *)filePath delegate:(id<PostProgressBarDelegate>)del message:(NSString *)msg accountUUID:(NSString *)uuid requestMethod:(NSString *)requestMethod suppressErrors:(BOOL)suppressErrors
{
    return [PostProgressBar createAndStartWithURL:url andPostFile:filePath delegate:del message:msg accountUUID:uuid requestMethod:requestMethod suppressErrors:suppressErrors graceTime:kNetworkProgressDialogGraceTime];
}

+ (PostProgressBar *)createAndStartWithURL:(NSURL *)url andPostFile:(NSString *)filePath delegate:(id<PostProgressBarDelegate>)del message:(NSString *)msg accountUUID:(NSString *)uuid requestMethod:(NSString *)requestMethod suppressErrors:(BOOL)suppressErrors graceTime:(CGFloat)graceTime
{
    // determine HTTP method to use, default to POST
    if (requestMethod == nil)
    {
        requestMethod = @"POST";
    }
    
    NSError *attributesError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&attributesError];
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    
    BaseHTTPRequest *request = [BaseHTTPRequest requestWithURL:url accountUUID:uuid];
    [request setRequestMethod:requestMethod];
    [request addRequestHeader:@"Content-Type" value:kAtomEntryMediaType];
    [request setPostBodyFilePath:filePath];
    [request setContentLength:[fileSizeNumber longLongValue]];
    [request setShouldStreamPostDataFromDisk:YES];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setSuppressAllErrors:suppressErrors];
    [request startAsynchronous];
	
    PostProgressBar *bar = [[[PostProgressBar alloc] initWithRequest:request message:msg graceTime:graceTime] autorelease];
	// who should we notify when the download is complete?
    [bar setDelegate:del];
    return bar;
}

#pragma mark - ASIHTTPRequestDelegate

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"failed to upload file");
    [self performSelectorOnMainThread:@selector(uploadFailed:) withObject:request waitUntilDone:NO];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"upload file request finished %@", [request responseString]);
    [self performSelectorOnMainThread:@selector(parseResponse:) withObject:request waitUntilDone:NO];
}

- (void)parseResponse:(ASIHTTPRequest *)request 
{
    RepositoryItemParser *itemParser = [[[RepositoryItemParser alloc] initWithData:request.responseData] autorelease];
    [self setRepositoryItem:[itemParser parse]]; 
    [self setCmisObjectId:[self.repositoryItem guid]];
    
	if (self.delegate) 
    {
		[delegate post:self completeWithData:self.fileData];
	}
    
    [progressAlert dismissWithClickedButtonIndex:0 animated:NO];
    [graceTimer invalidate];
}

- (void)uploadFailed:(ASIHTTPRequest *)request 
{
    if (self.delegate) 
    {
		[delegate post: self failedWithData:self.fileData];
	}
    
    [progressAlert dismissWithClickedButtonIndex:0 animated:NO];
    [graceTimer invalidate];
    
    if (!self.suppressErrors)
    {
        [self displayFailureMessage];
    }
}

#pragma mark - ASIProgressDelegate

- (void)setProgress:(float)newProgress
{
    [self.progressView setProgress:newProgress];
}

- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes
{
    long bytesSent = request.postLength *self.progressView.progress;
    
    UILabel *label = (UILabel *)[self.progressAlert viewWithTag:kPostCounterTag];
    label.text = [NSString stringWithFormat:@"%@ %@ %@", 
     [FileUtils stringForLongFileSize:bytesSent],
     NSLocalizedString(@"of", @"'of' usage: 1 of 3, 2 of 3, 3 of 3"),
     [FileUtils stringForLongFileSize:request.postLength]];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (!isShowingPromptPasswordDialog)
    {
        [self.currentRequest clearDelegatesAndCancel];
        self.fileData = nil;
    }
}

#pragma mark - NSTimer handler

- (void)handleGraceTimer
{
    [graceTimer invalidate];
    if (!isShowingPromptPasswordDialog)
    {
        [self.progressAlert show];
    }
}

#pragma mark - PromptPassword delegate methods

- (void)willPromptPassword:(BaseHTTPRequest *)request
{
    isShowingPromptPasswordDialog = YES;
    [self.progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)finishedPromptPassword:(BaseHTTPRequest *)request
{
    isShowingPromptPasswordDialog = NO;
    [self.progressAlert show];
}

- (void)cancelledPromptPassword:(BaseHTTPRequest *)request
{
    isShowingPromptPasswordDialog = NO;
    [self alertView:self.progressAlert willDismissWithButtonIndex:self.progressAlert.cancelButtonIndex];
}

@end
