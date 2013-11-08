//
//  RenameQueueProgressBar.m
//  FreshDocs
//
//  Created by bdt on 11/8/13.
//
//

#import "RenameQueueProgressBar.h"
#import "ASINetworkQueue.h"
#import "RepositoryItem.h"
#import "CMISUpdateProperties.h"
#import "AccountManager.h"
#import "PropertyInfo.h"

@interface RenameQueueProgressBar (private)
- (void) loadDeleteView;
- (void) updateProgressView;
@end

@implementation RenameQueueProgressBar
@synthesize requestQueue = _requestQueue;
@synthesize itemToRename = _itemToRename;
@synthesize delegate = _delegate;
@synthesize progressAlert = _progressAlert;
@synthesize progressTitle = _progressTitle;
@synthesize progressView = _progressView;
@synthesize selectedUUID = _selectedUUID;
@synthesize tenantID = _tenantID;

- (id)initWithItem:(NSDictionary *)itemInfo delegate:(id<RenameQueueDelegate>)del andMessage:(NSString *)message
{
    self = [super init];
    if (self)
    {
        self.itemToRename = itemInfo;
        self.delegate = del;
        self.progressTitle = message;
    
        [self loadDeleteView];
    }
    
    return self;
}

#pragma mark - private methods
- (void)loadDeleteView
{
    // create a modal alert
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.progressTitle
                                                    message:NSLocalizedString(@"pleaseWaitMessage", @"Please Wait...")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"cancelButton", @"Cancel")
                                          otherButtonTitles:nil];
    alert.message = [NSString stringWithFormat: @"%@%@", alert.message, @"\n\n\n\n"];
    self.progressAlert = alert;
	
	
	// create a progress bar and put it in the alert
    UIActivityIndicatorView *progress = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.progressView = progress;
    [self.progressAlert addSubview:self.progressView];
}

- (void) updateProgressView
{

}

#pragma mark - public methods
- (void) startRenaming
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
    
    RepositoryItem *item = [_itemToRename objectForKey:@"Item"];
    NSString *newFileName = [_itemToRename objectForKey:@"NewFileName"];

    NSMutableDictionary *editDict = [NSMutableDictionary dictionaryWithDictionary:item.metadata];
    [editDict setObject:newFileName  forKey:@"cmis:name"];
    PropertyInfo *info = [[PropertyInfo alloc] init];
    info.propertyType = @"string";
    info.displayName = [item.metadata objectForKey:@"cmis:name"];
    info.localName = newFileName;
    info.propertyId = @"cmis:name";
    
    CMISUpdateProperties *updateRequest = [[CMISUpdateProperties alloc ]initWithURL:[NSURL URLWithString:item.selfURL] propertyInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:info, @"cmis:name", nil] originalMetadata:item.metadata editedMetadata:editDict accountUUID:self.selectedUUID];
    [updateRequest setTenantID:self.tenantID];
    [updateRequest setTag:index];
    
    [self.requestQueue addOperation:updateRequest];
    
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

#pragma mark -
#pragma mark ASINetworkQueue Delegate methods

- (void) requestFinished:(ASIHTTPRequest *)request
{
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
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(renameQueue:completedRename:)])
        {
            [self.delegate renameQueue:self completedRename:_itemToRename];
        }
    }
}

- (void)finishedPromptPassword:(ASIHTTPRequest *) request
{
    [self.progressAlert show];
}

#pragma mark - static methods
+ (RenameQueueProgressBar *)createWithItem:(NSDictionary*) itemInfo delegate:(id <RenameQueueDelegate>)del andMessage:(NSString *)message
{
    RenameQueueProgressBar *bar = [[RenameQueueProgressBar alloc] initWithItem:itemInfo delegate:del andMessage:message];
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
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(renameQueueWasCancelled::)])
        {
            [self.delegate renameQueueWasCancelled:self];
        }
        
        self.requestQueue = nil;
    }
}

@end

