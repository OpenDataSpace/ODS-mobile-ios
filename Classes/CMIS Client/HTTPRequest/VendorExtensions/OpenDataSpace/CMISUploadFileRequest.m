//
//  CMISUploadFileRequest.m
//  FreshDocs
//
//  Created by bdt on 1/20/14.
//
//
#import <AssetsLibrary/AssetsLibrary.h>
#import "CMISUploadFileRequest.h"
#import "RepositoryItem.h"
#import "AssetUploadItem.h"
#import "ObjectByIdRequest.h"
#import "RepositoryItemParser.h"

#if TARGET_OS_IPHONE
#import <MobileCoreServices/UTType.h>
#import <UIKit/UIDevice.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#define APPEND_CHUNK_DATA_SIZE  4194304   //1024*1024*4  The maxmium value for chunk size.
#define MIN_CHUNK_SIZE  8192

@interface CMISUploadFileRequest() {
    uint8_t *readBuffer;   //read buffer
    FILE  *_uploadFileHandle;  //Document File Handle. If the source file url is file path.
    NSString *_mimeType;
}
@property (strong) NSRecursiveLock *cancelledLock;
@property (nonatomic, assign, readwrite) uint64_t    totalBytes;
@property (nonatomic, assign, readwrite) uint64_t    sentBytes;
@property (nonatomic, strong) ALAsset *uploadFileAsset; //Asset from library.If the source file url is asset URL
@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) uint64_t chunkSize;
@end

@implementation CMISUploadFileRequest
@synthesize delegate = _delegate;
@synthesize queue = _queue;
@synthesize uploadProgressDelegate = _uploadProgressDelegate;

@synthesize didStartSelector = _didStartSelector;
@synthesize didFinishSelector = _didFinishSelector;
@synthesize didFailSelector = _didFailSelector;

@synthesize cancelledLock = _cancelledLock;
@synthesize totalBytes = _totalBytes;
@synthesize sentBytes = _sentBytes;
@synthesize uploadFileAsset = _uploadFileAsset;
@synthesize chunkSize = _chunkSize;
@synthesize uploadInfo = _uploadInfo;

@synthesize isCancelled = _isCancelled;
@synthesize error = _error;

#pragma mark -
#pragma mark Utils


#pragma mark -
#pragma mark Inital
- (id) init
{
    if (self = [super init]) {
        _uploadFileAsset = nil;
        _uploadFileHandle = nil;
        
        _didStartSelector = nil;
        _didFinishSelector = nil;
        _didFailSelector = nil;
        
        _totalBytes = 0;
        _sentBytes = 0;
        
        _delegate = nil;
        _queue = nil;
        _uploadProgressDelegate = nil;
        
        _isCancelled = NO;
        
        _error = nil;
        
        _mimeType = nil;
        
        _chunkSize = MIN_CHUNK_SIZE;
        
        readBuffer = malloc(APPEND_CHUNK_DATA_SIZE);
        
        [self setCancelledLock:[[NSRecursiveLock alloc] init]];
    }
    
    return self;
}

- (void) dealloc
{
    free(readBuffer);
    if (_uploadFileHandle) {
        fclose(_uploadFileHandle);
    }
    
    _cancelledLock = nil;
}

- (void) setUploadInfo:(UploadInfo *)uploadInfo
{
    _uploadInfo = uploadInfo;
    [self initUploadFile];  //check file and get file size.
}

+(CMISUploadFileRequest*)cmisUploadRequestWithUploadInfo:(UploadInfo*) info
{
    CMISUploadFileRequest *newRequest = [[self alloc] init];
    [newRequest setUploadInfo:info];
    
    return newRequest;
}

#pragma mark -
#pragma mark File Operation
- (BOOL)initUploadFile
{
    _uploadFileHandle = fopen([[_uploadInfo.uploadFileURL path] cStringUsingEncoding:NSUTF8StringEncoding], "rb");
    if (_uploadFileHandle) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[_uploadInfo.uploadFileURL path] error:NULL];
        self.totalBytes = [attributes fileSize];
        return YES;
    }
    
    self.uploadFileAsset = [AssetUploadItem assetFromURL:_uploadInfo.uploadFileURL];
    if (self.uploadFileAsset) {
        self.totalBytes = [[self.uploadFileAsset defaultRepresentation] size];
        return YES;
    }
    
    return NO;
}

- (BOOL)isFileExists
{
    return (_uploadFileHandle || self.uploadFileAsset);
}

- (NSMutableData*) readDataFromFile:(NSInteger) offset length:(NSInteger) length
{
    NSMutableData *data = [NSMutableData data];
    NSInteger readLen = 0;
    if (_uploadFileHandle) {
        fseek(_uploadFileHandle, 0, offset);
        readLen = fread(readBuffer, 1, length, _uploadFileHandle);
    }
    
    if (self.uploadFileAsset) {
        readLen = [[self.uploadFileAsset defaultRepresentation] getBytes:readBuffer fromOffset:offset length:length error:nil];
        
    }
    
    if (readLen > 0)
        data = [NSData dataWithBytesNoCopy:readBuffer length:readLen freeWhenDone:NO];
    
    return data;
}

#pragma mark -
#pragma mark Upload Helpers

- (BOOL) createFileOnServer   //create empty file on server.
{
    CMISUploadFileHTTPRequest *createFileRequest = [CMISUploadFileHTTPRequest cmisUploadRequestWithUploadInfo:_uploadInfo];
    [createFileRequest setRequestMethod:@"POST"];
    [createFileRequest setPromptPasswordDelegate:self];
    [createFileRequest setSuppressAccountStatusUpdateOnError:YES];
    [_uploadInfo setUploadStatus:UploadInfoStatusActive];
    
    [createFileRequest startSynchronous];
    _error = [createFileRequest error];
    
    if (_error == nil && [createFileRequest responseStatusCode] == 201) {  //create successful
        RepositoryItemParser *itemParser = [[RepositoryItemParser alloc] initWithData:[createFileRequest responseData]];
        _uploadInfo.repositoryItem = [itemParser parse];
        [_uploadInfo setCmisObjectId:_uploadInfo.repositoryItem.guid];
        [_uploadInfo setRepositoryItem:_uploadInfo.repositoryItem];
        
        return YES;
    }
    
    return NO;
}

- (BOOL) updateRepositoryItemInfo   //update change token for uploading file
{
    ObjectByIdRequest *objRequest = [ObjectByIdRequest defaultObjectById:_uploadInfo.repositoryItem.guid accountUUID:_uploadInfo.selectedAccountUUID tenantID:_uploadInfo.tenantID];
    [objRequest startSynchronous];
    _error = [objRequest error];
    
    if (_error == nil && [objRequest responseStatusCode] == 200) {
        _uploadInfo.repositoryItem = [objRequest repositoryItem];
        AlfrescoLogDebug(@"uploaded file size:%@, file name:%@ changeToken:%@",[_uploadInfo.repositoryItem.metadata objectForKey:@"cmis:contentStreamLength"],_uploadInfo.repositoryItem.title, _uploadInfo.repositoryItem.changeToken);
        self.sentBytes = [[_uploadInfo.repositoryItem.metadata objectForKey:@"cmis:contentStreamLength"] longLongValue];
        
        return YES;
    }
    
    AlfrescoLogDebug(@"%@", _error);
    return NO;
}

- (BOOL) appendChunkData:(NSMutableData*) contentData dataLength:(uint64_t) dataLength isLastChunk:(BOOL)isLastChunk
{
    @autoreleasepool {
        AlfrescoLogDebug(@"appendChunkData file name:%@ changeToken:%@",[_uploadInfo.repositoryItem.metadata objectForKey:@"cmis:contentStreamLength"],_uploadInfo.repositoryItem.title, _uploadInfo.repositoryItem.changeToken);
        CMISAppendContentHTTPRequest *appendRequest = [CMISAppendContentHTTPRequest cmisAppendRequestWithUploadInfo:_uploadInfo contentData:contentData isLastChunk:isLastChunk];
        [appendRequest addRequestHeader:@"Content-Type" value:_mimeType];
        [appendRequest setUploadProgressDelegate:self];
        [appendRequest startSynchronous];
        
        _error = [appendRequest error];
        
        if (_error == nil && ([appendRequest responseStatusCode] == 201 || [appendRequest responseStatusCode] == 200)) {  //put data successfully
            AlfrescoLogDebug(@"upload size:%llu  total:%llu",self.sentBytes, self.totalBytes);
            AlfrescoLogDebug(@"appendChunkData:%@ ,error:%@", [NSString stringWithUTF8String:[[appendRequest responseData] bytes]], _error);
            return YES;
        }
        
        AlfrescoLogDebug(@"appendChunkData:%@ ,error:%@", [NSString stringWithUTF8String:[[appendRequest responseData] bytes]], _error);
    }
    
    return NO;
}

- (BOOL) uplaodWholeFile
{
    //cal chunk size first
    self.chunkSize = [self getChunkSize];
    
    while (self.sentBytes != self.totalBytes) {
        uint64_t leftBytes = self.totalBytes - self.sentBytes;
        
        NSInteger readLength = (leftBytes >= self.chunkSize)?self.chunkSize:leftBytes;
        AlfrescoLogDebug(@"leftBytes:%llu readLength:%d total:%llu",leftBytes, readLength, self.totalBytes);
        NSMutableData *data = [self readDataFromFile:self.sentBytes length:readLength];
        if (!data) {
            return NO;
        }
        
        if (![self appendChunkData:data dataLength:readLength isLastChunk:(self.sentBytes + readLength == self.totalBytes)]) {
            return NO;
        }
        
        if (![self updateRepositoryItemInfo]) {
            return NO;
        }
        
        if (_isCancelled) {   //cancel upload request
            return NO;
        }
    }
    
    return YES;
}

- (uint64_t) getChunkSize {
    uint64_t avgSize = (uint64_t)self.totalBytes/50;
    if (avgSize > APPEND_CHUNK_DATA_SIZE) {
        avgSize == APPEND_CHUNK_DATA_SIZE;
    }else if (avgSize < MIN_CHUNK_SIZE) {
        avgSize = MIN_CHUNK_SIZE;
    }
    
    return avgSize;
}

//mimetype from file extension
- (NSString*) mimeTypeFromFileExtension {
    //get mimetype from file extension
    CFStringRef pathExtension = (__bridge_retained CFStringRef)self.uploadInfo.extension;
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);
    
    // The UTI can be converted to a mime type:
    
    NSString* mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (type != NULL)
        CFRelease(type);
    
    if (mimeType == nil) {
        mimeType = @"application/octet-stream";
    }
    
    return mimeType;
}

#pragma mark -
#pragma mark ASIHttpRequest Delegate
- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes
{
    self.sentBytes += bytes;
    unsigned long long value = bytes;
    id uploadQueue = _queue;
    
    [ASIHTTPRequest performSelector:@selector(request:didSendBytes:) onTarget:&uploadQueue withObject:self amount:&value callerToRetain:self];
	
    id uploadIndicatorDelegate = _uploadProgressDelegate;
    [ASIHTTPRequest updateProgressIndicator:&uploadIndicatorDelegate withProgress:self.sentBytes ofTotal:self.totalBytes];
}

#pragma mark -
#pragma mark Delegate Handler

- (void) uploadStart
{
    [[self cancelledLock] lock];
    
    if (_delegate && [_delegate respondsToSelector:@selector(uploadStarted:)]) {
		[_delegate performSelector:@selector(uploadStarted:) withObject:_uploadInfo];
	}
    
    if (_queue && [_queue respondsToSelector:@selector(uploadStarted:)]) {
		[_queue performSelector:@selector(uploadStarted:) withObject:self];
	}
    [[self cancelledLock] unlock];
    
}

- (void) uploadFailed
{
    [[self cancelledLock] lock];
    
    if (_delegate && [_delegate respondsToSelector:@selector(uploadFailed:)]) {
		[_delegate performSelector:@selector(uploadFailed:) withObject:_uploadInfo];
	}
    
    if (_queue && [_queue respondsToSelector:@selector(uploadFailed:)]) {
		[_queue performSelector:@selector(uploadFailed:) withObject:self];
	}
    [[self cancelledLock] unlock];
    
}

- (void) uploadFinish
{
    [[self cancelledLock] lock];
    
    if (_delegate && [_delegate respondsToSelector:@selector(uploadFinished:)]) {
		[_delegate performSelector:@selector(uploadFinished:) withObject:_uploadInfo];
	}
    
    if (_queue && [_queue respondsToSelector:@selector(uploadFinished:)]) {
		[_queue performSelector:@selector(uploadFinished:) withObject:self];
	}
    [[self cancelledLock] unlock];
    
}

#pragma mark -
#pragma mark Main Thread

- (void) cancelRequestThread {
    _error = [[NSError alloc] initWithDomain:NetworkRequestErrorDomain code:ASIRequestCancelledErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"asihttprequest.request.cancelled", @"The request was cancelled"),NSLocalizedDescriptionKey,nil]];
    
	[[self cancelledLock] lock];
    
    if (![self isCancelled]) {
        // Clear delegates
        [self setDelegate:nil];
        [self setQueue:nil];
        [self setUploadProgressDelegate:nil];
        _isCancelled = YES;
    }	
    
	[[self cancelledLock] unlock];
    
}

- (void)cancel
{
    [self performSelectorInBackground:@selector(cancelRequestThread) withObject:nil];
}

- (void)clearDelegatesAndCancel
{
    [[self cancelledLock] lock];

	// Clear delegates
	[self setDelegate:nil];
	[self setQueue:nil];
	[self setUploadProgressDelegate:nil];
    _isCancelled = YES;
    
	[[self cancelledLock] unlock];
    
	[self cancel];
}

- (void) main
{
    @autoreleasepool {
        @try {
            if (![self isFileExists]) {  //check the file url and init file handle, file size.
                [self uploadFailed];
                return;
            }
            
            _mimeType = [self mimeTypeFromFileExtension];
            AlfrescoLogDebug(@"upload file mime type:%@", _mimeType);
            
            if (_uploadInfo.repositoryItem.guid == nil || [_uploadInfo.repositoryItem.guid length] < 2) {  //create the file on serve if it's not exist.
                if (![self createFileOnServer]) {
                    [self uploadFailed];
                    return;
                }
            }else
            {
                if (![self updateRepositoryItemInfo]) {
                    [self uploadFailed];
                    return;
                }
            }
            [self uploadStart];
            
            if (![self uplaodWholeFile]) {
                [self uploadFailed];
                return;
            }
            
            [self uploadFinish];
        }
        @catch (NSException *exception) {
            AlfrescoLogDebug(@"Upload file request exception:%@", exception);
            [self uploadFailed];
        }
        @finally {
            
        }
    }
}
@end
