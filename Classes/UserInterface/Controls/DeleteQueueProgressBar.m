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
//  DeleteQueueProgressBar.m
//

#import "DeleteQueueProgressBar.h"
#import "ASINetworkQueue.h"
#import "RepositoryItem.h"
#import "BaseHTTPRequest.h"
#import "AccountManager.h"
#import "AccountInfo.h"

NSInteger const kDeleteCounterTag =  6;

@interface DeleteQueueProgressBar (private)
- (void) loadDeleteView;
- (void) updateProgressView;
@end

@implementation DeleteQueueProgressBar
@synthesize requestQueue = _requestQueue;
@synthesize itemsToDelete = _itemsToDelete;
@synthesize delegate = _delegate;
@synthesize progressAlert = _progressAlert;
@synthesize progressTitle = _progressTitle;
@synthesize progressView = _progressView;
@synthesize selectedUUID = _selectedUUID;
@synthesize tenantID = _tenantID;

- (void) dealloc
{
    [_requestQueue release];
    [_itemsToDelete release];
    [_progressAlert release];
    [_progressTitle release];
    [_progressView release];
    [_deletedItems release];
    [_selectedUUID release];
    [_tenantID release];
    [super dealloc];
}

- (id)initWithItems:(NSArray *)itemsToDelete delegate:(id<DeleteQueueDelegate>)del andMessage:(NSString *)message
{
    self = [super init];
    if (self)
    {
        self.itemsToDelete = itemsToDelete;
        self.delegate = del;
        self.progressTitle = message;
        _deletedItems = [[NSMutableArray array] retain];
        [self loadDeleteView];
    }
    
    return self;
}

#pragma mark - private methods
- (void) loadDeleteView
{
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
    label.tag = kDeleteCounterTag;
    [self.progressAlert addSubview:label];
    [label release];
}

- (void) updateProgressView
{
    UILabel *label = (UILabel *)[self.progressAlert viewWithTag:kDeleteCounterTag];
    if([self.requestQueue requestsCount] == 1)
    {
        label.text = [NSString stringWithFormat:NSLocalizedString(@"deleteprogress.file-left", @"1 item left"), 
                      [self.requestQueue requestsCount]];
    }
    else 
    {
        label.text = [NSString stringWithFormat:NSLocalizedString(@"deleteprogress.files-left", @"x items left"), 
                      [self.requestQueue requestsCount]];
    }
}

#pragma mark - public methods
- (void) startDeleting
{
    [self.requestQueue cancelAllOperations];
    self.requestQueue = [ASINetworkQueue queue];
    [self.requestQueue setDelegate:self];
    [self.requestQueue setRequestDidFinishSelector:@selector(requestFinished:)];
    [self.requestQueue setRequestDidFailSelector:@selector(requestFailed:)];
    [self.requestQueue setQueueDidFinishSelector:@selector(queueFinished:)];
    [self.requestQueue setShowAccurateProgress:NO];
    [self.requestQueue setShouldCancelAllRequestsOnFailure:NO];
    [self.requestQueue setDownloadProgressDelegate:self.progressView];
    
    for (NSInteger index = 0; index < [self.itemsToDelete count]; index++)
    {
        RepositoryItem *item = [self.itemsToDelete objectAtIndex:index];
        NSURL *url = [NSURL URLWithString:item.deleteURL];
        NSLog(@"DELETE: %@", [url description]);
        
        BaseHTTPRequest *request = [BaseHTTPRequest requestWithURL:url accountUUID:self.selectedUUID];
        [request setTenantID:self.tenantID];
        [request setTag:index];
        [request setShouldContinueWhenAppEntersBackground:YES];
        [request setShouldAttemptPersistentConnection:NO]; // workaround for multiple DELETE requests observed with Wireshark
        [request setRequestMethod:@"DELETE"];
        
        [self.requestQueue addOperation:request];
    }
    
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedUUID];
    NSString *passwordForAccount = [BaseHTTPRequest passwordForAccount:account];
    if (passwordForAccount)
    {
        [self.progressAlert show];
    }
    [self.requestQueue go];
    [self updateProgressView];
}

- (void) cancel
{
    [_progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (NSArray *) deletedItems
{
    return [NSArray arrayWithArray:_deletedItems];
}

#pragma mark -
#pragma mark ASINetworkQueue Delegate methods

- (void) requestFinished:(ASIHTTPRequest *)request
{
    [_deletedItems addObject:[self.itemsToDelete objectAtIndex:request.tag]];
    
    [self updateProgressView];
}

- (void) requestFailed:(ASIHTTPRequest *)request
{
    [self updateProgressView];
}

- (void) queueFinished:(ASINetworkQueue *)queue
{
    if ([self.requestQueue requestsCount] == 0)
    {
        [_progressAlert dismissWithClickedButtonIndex:1 animated:NO];
        self.requestQueue = nil;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(deleteQueue:completedDeletes:)])
        {
            [self.delegate deleteQueue:self completedDeletes:_deletedItems];
        }
    }
}

- (void)finshedPromptPassword:(ASIHTTPRequest *) request
{
    [self.progressAlert show];
}

#pragma mark - static methods
+ (DeleteQueueProgressBar *) createWithItems:(NSArray *)itemsToDelete delegate:(id<DeleteQueueDelegate>)del andMessage:(NSString *)message
{
    DeleteQueueProgressBar *bar = [[[DeleteQueueProgressBar alloc] initWithItems:itemsToDelete delegate:del andMessage:message] autorelease];
    return bar;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // we only cancel the connection when buttonIndex=0 (cancel)
    if (buttonIndex == 0)
    {
        [_requestQueue cancelAllOperations];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(deleteQueueWasCancelled::)])
        {
            [self.delegate deleteQueueWasCancelled:self];
        }
        
        self.requestQueue = nil;
    }
}

@end
