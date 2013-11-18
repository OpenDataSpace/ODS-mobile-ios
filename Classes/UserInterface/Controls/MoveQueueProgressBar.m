//
//  MoveQueueProgressBar.m
//  FreshDocs
//
//  Created by bdt on 11/14/13.
//
//

#import "MoveQueueProgressBar.h"
#import "ASINetworkQueue.h"
#import "RepositoryItem.h"
#import "CMISMoveObjectHTTPRequest.h"
#import "AccountManager.h"
#import "AlfrescoUtils.h"

NSInteger const kMoveCounterTag =  8;

@interface MoveQueueProgressBar () {
    NSMutableArray *_movedItems;
}
- (void) loadMoveView;
@end

@implementation MoveQueueProgressBar
@synthesize requestQueue = _requestQueue;
@synthesize itemsToMove = _itemsToMove;
@synthesize delegate = _delegate;
@synthesize progressAlert = _progressAlert;
@synthesize progressTitle = _progressTitle;
@synthesize progressView = _progressView;
@synthesize selectedUUID = _selectedUUID;
@synthesize tenantID = _tenantID;
@synthesize targetFolder = _targetFolder;
@synthesize sourceFolderId = _sourceFolderId;

- (id)initWithItems:(NSArray *)itemsToMove targetFolder:(RepositoryItem*)targetFolder delegate:(id<MoveQueueDelegate>)del andMessage:(NSString *)message
{
    self = [super init];
    if (self)
    {
        self.itemsToMove = itemsToMove;
        self.delegate = del;
        self.progressTitle = message;
        self.targetFolder = targetFolder;
        _movedItems = [NSMutableArray array];
        _sourceFolderId = nil;
        [self loadMoveView];
    }
    
    return self;
}

- (void) loadMoveView {
    // create a modal alert
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.progressTitle
                                                    message:NSLocalizedString(@"pleaseWaitMessage", @"Please Wait...")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"cancelButton", @"Cancel")
                                          otherButtonTitles:nil];
    alert.message = [NSString stringWithFormat: @"%@%@", alert.message, @"\n\n\n\n"];
    self.progressAlert = alert;
	
	// create a progress bar and put it in the alert
	UIProgressView *progress = [[UIProgressView alloc] initWithFrame:CGRectMake(30.0f, 80.0f, 225.0f, 90.0f)];
    self.progressView = progress;
    [progress setProgressViewStyle:UIProgressViewStyleBar];
	[self.progressAlert addSubview:self.progressView];
	
	// create a label, and add that to the alert, too
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30.0f, 90.0f, 225.0f, 40.0f)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = UITextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:13.0f];
    label.text = @"x files left";
    label.tag = kMoveCounterTag;
    [self.progressAlert addSubview:label];

}

- (void) updateProgressView
{
    UILabel *label = (UILabel *)[self.progressAlert viewWithTag:kMoveCounterTag];
    if([self.requestQueue requestsCount] == 1)
    {
        label.text = [NSString stringWithFormat:NSLocalizedString(@"moveprogress.file-left", @"1 item left"),
                      [self.requestQueue requestsCount]];
    }
    else
    {
        label.text = [NSString stringWithFormat:NSLocalizedString(@"moveprogress.files-left", @"x items left"),
                      [self.requestQueue requestsCount]];
    }
}

- (void)startMoving {
    [self.requestQueue cancelAllOperations];
    self.requestQueue = [ASINetworkQueue queue];
    [self.requestQueue setDelegate:self];
    [self.requestQueue setRequestDidFinishSelector:@selector(requestFinished:)];
    [self.requestQueue setRequestDidFailSelector:@selector(requestFailed:)];
    [self.requestQueue setQueueDidFinishSelector:@selector(queueFinished:)];
    [self.requestQueue setShowAccurateProgress:NO];
    [self.requestQueue setShouldCancelAllRequestsOnFailure:NO];
    [self.requestQueue setDownloadProgressDelegate:self.progressView];
    
    for (NSInteger index = 0; index < [self.itemsToMove count]; index++)
    {
        RepositoryItem *item = [self.itemsToMove objectAtIndex:index];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@&sourceFolderId=%@",_targetFolder.identLink, _sourceFolderId]];
        
        AlfrescoLogDebug(@"MOVE: %@", [url description]);
        
        CMISMoveObjectHTTPRequest *request = [[CMISMoveObjectHTTPRequest alloc] initWithURL:url moveParam:[NSDictionary dictionaryWithObjectsAndKeys:item.guid,@"cmis:objectId", nil] accountUUID:self.selectedUUID];
        [request setTenantID:self.tenantID];
        [request setTag:index];
        
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

- (void)cancel {
    [_progressAlert dismissWithClickedButtonIndex:0 animated:YES];
}

- (NSArray *) movedItems
{
    return [NSArray arrayWithArray:_movedItems];
}

#pragma mark -
#pragma mark ASINetworkQueue Delegate methods

- (void) requestFinished:(ASIHTTPRequest *)request
{
    [_movedItems addObject:[self.itemsToMove objectAtIndex:request.tag]];
    
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
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(moveQueue:completedMoves:)])
        {
            [self.delegate moveQueue:self completedMoves:_movedItems];
        }
    }
}

- (void)finishedPromptPassword:(ASIHTTPRequest *) request
{
    [self.progressAlert show];
}

#pragma mark - static methods
+ (MoveQueueProgressBar *)createWithItems:(NSArray*)itemsToMove targetFolder:(RepositoryItem*)targetFolder delegate:(id <MoveQueueDelegate>)del andMessage:(NSString *)message {
    MoveQueueProgressBar *bar = [[MoveQueueProgressBar alloc] initWithItems:itemsToMove targetFolder:targetFolder delegate:del andMessage:message];
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
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(moveQueueWasCancelled::)])
        {
            [self.delegate moveQueueWasCancelled:self];
        }
        
        self.requestQueue = nil;
    }
}

@end
