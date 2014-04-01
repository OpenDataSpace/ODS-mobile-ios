//
//  CMISUploadFileQueue.m
//  FreshDocs
//
//  Created by bdt on 1/20/14.
//
//

#import "CMISUploadFileQueue.h"
#import "CMISUploadFileRequest.h"

@interface CMISUploadFileQueue()
@property (assign) int requestsCount;
@end

@implementation CMISUploadFileQueue
@synthesize shouldCancelAllRequestsOnFailure = _shouldCancelAllRequestsOnFailure;

@synthesize delegate = _delegate;
@synthesize requestsCount = _requestsCount;

@synthesize requestDidStartSelector = _requestDidStartSelector;
@synthesize requestDidFinishSelector = _requestDidFinishSelector;
@synthesize requestDidFailSelector = _requestDidFailSelector;
@synthesize queueDidFinishSelector = _queueDidFinishSelector;

#pragma mark -
#pragma mark - Init 
- (id)init
{
	self = [super init];
	[self setShouldCancelAllRequestsOnFailure:YES];
	[self setMaxConcurrentOperationCount:4];
	[self setSuspended:YES];
	
	return self;
}

+ (id)queue
{
	return [[self alloc] init];
}

#pragma mark -
#pragma mark - Queue Operations
- (void)setSuspended:(BOOL)suspend
{
	[super setSuspended:suspend];
}

- (void)go
{
	[self setSuspended:NO];
}

- (void)cancelAllOperations
{
	[self setBytesUploadedSoFar:0];
	[self setTotalBytesToUpload:0];
	[super cancelAllOperations];
}

- (void)addOperation:(NSOperation *)operation
{
	if (![operation isKindOfClass:[CMISUploadFileRequest class]]) {
		[NSException raise:@"AttemptToAddInvalidRequest" format:@"Attempted to add an object that was not an CMISUploadFileOperation to an CMISUploadQueue"];
	}
    
	[self setRequestsCount:[self requestsCount]+1];
	
	CMISUploadFileRequest *request = (CMISUploadFileRequest *)operation;
    
    [self setTotalBytesToUpload:[self totalBytesToUpload] + [request totalBytes]];
    
    
    [request setQueue:self];
    
	[super addOperation:request];
}

#pragma mark -
#pragma mark - Upload File Request Delegate Method
- (void)uploadStarted:(CMISUploadFileRequest *)request
{
    if ([self requestDidStartSelector]) {
		[[self delegate] performSelector:[self requestDidStartSelector] withObject:request];  //should add -Wno-arc-performSelector-leaks
	}
}

- (void)uploadFinished:(CMISUploadFileRequest *)request
{
    [self setRequestsCount:[self requestsCount]-1];
	if ([self requestDidFinishSelector]) {
		[[self delegate] performSelector:[self requestDidFinishSelector] withObject:request];
	}
	if ([self requestsCount] == 0) {
		if ([self queueDidFinishSelector]) {
			[[self delegate] performSelector:[self queueDidFinishSelector] withObject:self];
		}
	}
}

- (void)uploadFailed:(CMISUploadFileRequest *)request
{
    [self setRequestsCount:[self requestsCount]-1];
	if ([self requestDidFailSelector]) {
		[[self delegate] performSelector:[self requestDidFailSelector] withObject:request];
	}
	if ([self requestsCount] == 0) {
		if ([self queueDidFinishSelector]) {
			[[self delegate] performSelector:[self queueDidFinishSelector] withObject:self];
		}
	}
	if ([self shouldCancelAllRequestsOnFailure] && [self requestsCount] > 0) {
		[self cancelAllOperations];
	}
}

- (void)request:(CMISUploadFileRequest *)request didSendBytes:(long long)bytes
{
	[self setBytesUploadedSoFar:[self bytesUploadedSoFar]+bytes];
	if ([self uploadProgressDelegate]) {
        id uploadProgressDelegate = _uploadProgressDelegate;
		[ASIHTTPRequest updateProgressIndicator:&uploadProgressDelegate withProgress:[self bytesUploadedSoFar] ofTotal:[self totalBytesToUpload]];
	}
}


@end
